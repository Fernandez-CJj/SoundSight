from fastapi import Header
from fastapi import HTTPException
from firebase_admin import auth


def requireVerifiedFirebaseUser(
    authorization: str | None = Header(default=None),
):
    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=401,
            detail="A Firebase ID token is required.",
        )

    idToken = authorization.removeprefix("Bearer ").strip()
    if idToken == "":
        raise HTTPException(
            status_code=401,
            detail="A Firebase ID token is required.",
        )

    try:
        decodedToken = auth.verify_id_token(idToken)
    except Exception as error:
        raise HTTPException(
            status_code=401,
            detail="The Firebase ID token is invalid or expired.",
        ) from error

    if decodedToken.get("email_verified") is not True:
        raise HTTPException(
            status_code=403,
            detail="Verify your email before using this feature.",
        )

    userId = decodedToken.get("uid")
    if not isinstance(userId, str) or userId == "":
        raise HTTPException(
            status_code=401,
            detail="The Firebase ID token does not identify a user.",
        )

    return userId
