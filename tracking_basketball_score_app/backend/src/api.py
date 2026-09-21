from datetime import datetime, timezone
from uuid import uuid4

from boto3.dynamodb.conditions import Key

from common import (
    body,
    decimalize,
    now_iso,
    response,
    table,
    user_from_event,
)
from logic import score_for_session, week_key


def handler(event, _context):
    try:
        user = user_from_event(event)
        ensure_profile(user)
        method = event["requestContext"]["http"]["method"]
        path = event.get("rawPath", "")
        routes = {
            ("POST", "/sessions"): save_session,
            ("POST", "/shots"): save_shot,
            ("GET", "/friends"): list_friends,
            ("POST", "/friends"): add_friend,
            ("POST", "/challenges"): create_challenge,
            ("GET", "/leaderboard"): leaderboard,
        }
        action = routes.get((method, path))
        if action is None:
            return response(404, {"message": "Route not found."})
        return action(user, event)
    except PermissionError as error:
        return response(401, {"message": str(error)})
    except ValueError as error:
        return response(400, {"message": str(error)})
    except Exception:
        return response(500, {"message": "Internal server error."})


def ensure_profile(user):
    table.update_item(
        Key={"PK": f"USER#{user['userId']}", "SK": "PROFILE"},
        UpdateExpression=(
            "SET email = if_not_exists(email, :email), "
            "displayName = if_not_exists(displayName, :name), "
            "points = if_not_exists(points, :zero), "
            "GSI2PK = :emailKey, GSI2SK = :userKey"
        ),
        ExpressionAttributeValues={
            ":email": user["email"],
            ":name": user["displayName"],
            ":zero": 0,
            ":emailKey": f"EMAIL#{user['email'].lower()}",
            ":userKey": f"USER#{user['userId']}",
        },
    )


def save_session(user, event):
    data = body(event)
    session_id = data.get("id") or data.get("sessionId")
    if not session_id:
        raise ValueError("Session id is required.")
    points = score_for_session(data)
    current_week = week_key()
    item = decimalize(
        {
            **data,
            "PK": f"USER#{user['userId']}",
            "SK": f"SESSION#{session_id}",
            "entityType": "SESSION",
            "userId": user["userId"],
            "points": points,
            "createdAt": now_iso(),
        }
    )
    table.put_item(Item=item, ConditionExpression="attribute_not_exists(SK)")
    profile = table.update_item(
        Key={"PK": f"USER#{user['userId']}", "SK": "PROFILE"},
        UpdateExpression="ADD points :points SET updatedAt = :now",
        ExpressionAttributeValues={":points": points, ":now": now_iso()},
        ReturnValues="ALL_NEW",
    )["Attributes"]
    leaderboard_key = {
        "PK": f"USER#{user['userId']}",
        "SK": f"LEADERBOARD#{current_week}",
    }
    weekly = table.update_item(
        Key=leaderboard_key,
        UpdateExpression=(
            "ADD points :points SET GSI1PK = :week, GSI1SK = :initial, "
            "entityType = :type, userId = :userId, displayName = :name"
        ),
        ExpressionAttributeValues={
            ":points": points,
            ":week": f"WEEK#{current_week}",
            ":initial": f"POINTS#999999999#USER#{user['userId']}",
            ":type": "LEADERBOARD",
            ":userId": user["userId"],
            ":name": profile["displayName"],
        },
        ReturnValues="ALL_NEW",
    )["Attributes"]
    weekly_points = int(weekly["points"])
    table.update_item(
        Key=leaderboard_key,
        UpdateExpression="SET GSI1SK = :sort",
        ExpressionAttributeValues={
            ":sort": (
                f"POINTS#{999999999-weekly_points:09d}#USER#{user['userId']}"
            )
        },
    )
    return response(201, {"sessionId": session_id, "pointsAwarded": points})


def save_shot(user, event):
    data = body(event)
    session_id = data.get("sessionId")
    shot_id = data.get("shotId")
    if not session_id or not shot_id:
        raise ValueError("sessionId and shotId are required.")
    table.put_item(
        Item=decimalize(
            {
                **data,
                "PK": f"SESSION#{session_id}",
                "SK": f"SHOT#{shot_id}",
                "entityType": "SHOT",
                "userId": user["userId"],
                "createdAt": now_iso(),
            }
        )
    )
    return response(201, {"shotId": shot_id})


def list_friends(user, _event):
    result = table.query(
        KeyConditionExpression=Key("PK").eq(f"USER#{user['userId']}")
        & Key("SK").begins_with("FRIEND#")
    )
    items = [
        {
            "userId": item["friendUserId"],
            "displayName": item["displayName"],
            "points": item.get("points", 0),
        }
        for item in result.get("Items", [])
    ]
    return response(200, {"items": items})


def add_friend(user, event):
    email = body(event).get("email", "").strip().lower()
    if not email:
        raise ValueError("Friend email is required.")
    result = table.query(
        IndexName="EmailIndex",
        KeyConditionExpression=Key("GSI2PK").eq(f"EMAIL#{email}"),
        Limit=1,
    )
    if not result.get("Items"):
        raise ValueError("No ShotLab account uses that email.")
    friend = result["Items"][0]
    friend_id = friend["PK"].removeprefix("USER#")
    if friend_id == user["userId"]:
        raise ValueError("You cannot add yourself.")
    created = now_iso()
    with table.batch_writer() as batch:
        batch.put_item(
            Item={
                "PK": f"USER#{user['userId']}",
                "SK": f"FRIEND#{friend_id}",
                "friendUserId": friend_id,
                "displayName": friend["displayName"],
                "points": friend.get("points", 0),
                "createdAt": created,
            }
        )
        batch.put_item(
            Item={
                "PK": f"USER#{friend_id}",
                "SK": f"FRIEND#{user['userId']}",
                "friendUserId": user["userId"],
                "displayName": user["displayName"],
                "points": 0,
                "createdAt": created,
            }
        )
    return response(201, {"friendUserId": friend_id})


def create_challenge(user, event):
    data = body(event)
    friend_id = data.get("friendUserId")
    target = int(data.get("targetMakes", 25))
    if not friend_id or target < 1:
        raise ValueError("Valid friendUserId and targetMakes are required.")
    friendship = table.get_item(
        Key={
            "PK": f"USER#{user['userId']}",
            "SK": f"FRIEND#{friend_id}",
        }
    ).get("Item")
    if friendship is None:
        raise ValueError("Challenges can only be sent to friends.")
    challenge_id = str(uuid4())
    expires = datetime.now(timezone.utc).timestamp() + 7 * 86400
    item = {
        "PK": f"CHALLENGE#{challenge_id}",
        "SK": "DETAIL",
        "entityType": "CHALLENGE",
        "challengeId": challenge_id,
        "creatorUserId": user["userId"],
        "friendUserId": friend_id,
        "targetMakes": target,
        "creatorMakes": 0,
        "friendMakes": 0,
        "status": "active",
        "createdAt": now_iso(),
        "expiresAt": int(expires),
    }
    table.put_item(Item=item)
    return response(201, item)


def leaderboard(_user, _event):
    result = table.query(
        IndexName="LeaderboardIndex",
        KeyConditionExpression=Key("GSI1PK").eq(f"WEEK#{week_key()}"),
        Limit=50,
    )
    items = [
        {
            "rank": index + 1,
            "userId": item["userId"],
            "displayName": item["displayName"],
            "points": item["points"],
        }
        for index, item in enumerate(result.get("Items", []))
    ]
    return response(200, {"items": items})
