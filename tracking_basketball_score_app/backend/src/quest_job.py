from boto3.dynamodb.conditions import Attr, Key

from common import now_iso, table
from logic import calculate_quests


def handler(_event, _context):
    profiles = table.scan(
        FilterExpression=Attr("SK").eq("PROFILE"),
        ProjectionExpression="PK",
    ).get("Items", [])
    updated = 0
    for profile in profiles:
        user_id = profile["PK"].removeprefix("USER#")
        sessions = table.query(
            KeyConditionExpression=Key("PK").eq(profile["PK"])
            & Key("SK").begins_with("SESSION#")
        ).get("Items", [])
        quests = calculate_quests(sessions)
        table.put_item(
            Item={
                "PK": profile["PK"],
                "SK": "QUESTS#CURRENT",
                "entityType": "QUESTS",
                "userId": user_id,
                "quests": quests,
                "updatedAt": now_iso(),
            }
        )
        updated += 1
    return {"updatedUsers": updated}
