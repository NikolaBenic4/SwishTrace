import json
import os
from datetime import datetime, timezone
from decimal import Decimal

import boto3
import firebase_admin
from firebase_admin import auth

TABLE_NAME = os.environ["TABLE_NAME"]
table = boto3.resource("dynamodb").Table(TABLE_NAME)

if not firebase_admin._apps:
    firebase_admin.initialize_app(
        options={"projectId": os.environ["FIREBASE_PROJECT_ID"]}
    )


def user_from_event(event):
    header = (event.get("headers") or {}).get("authorization", "")
    if not header.lower().startswith("bearer "):
        raise PermissionError("Missing bearer token.")
    decoded = auth.verify_id_token(header.split(" ", 1)[1])
    return {
        "userId": decoded["uid"],
        "email": decoded.get("email", ""),
        "displayName": decoded.get("name") or decoded.get("email", "Player"),
    }


def body(event):
    return json.loads(event.get("body") or "{}")


def response(status, payload=None):
    return {
        "statusCode": status,
        "headers": {"content-type": "application/json"},
        "body": json.dumps(payload or {}, default=_json_default),
    }


def now_iso():
    return datetime.now(timezone.utc).isoformat()


def decimalize(value):
    return json.loads(json.dumps(value), parse_float=Decimal)


def _json_default(value):
    if isinstance(value, Decimal):
        return int(value) if value % 1 == 0 else float(value)
    raise TypeError
