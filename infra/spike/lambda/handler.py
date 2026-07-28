"""Log the full API Gateway event and extract signer email from the IAM userArn when present."""

from __future__ import annotations

import json


def extract_identity(user_arn: str) -> str | None:
    """Return the assumed-role session name if it looks like an email, else None."""
    session_name = user_arn.rsplit("/", 1)[-1]
    if "@" in session_name:
        return session_name
    return None


def handler(event, context):
    print(json.dumps(event, default=str))

    user_arn = (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("iam", {})
        .get("userArn", "")
    )
    identity = extract_identity(user_arn) if user_arn else None
    if identity:
        print(f"Identified user: {identity}")
        return {
            "statusCode": 200,
            "headers": {"content-type": "application/json"},
            "body": json.dumps({"ok": True, "message": "logged event to CloudWatch"}),
        }

    print("Rejected: no email found in signing identity")
    return {
        "statusCode": 403,
        "headers": {"content-type": "application/json"},
        "body": '{"message": "The credentials provided are not associated with an SSO session. Please sign in using your AWS SSO session and try again."}',
    }
