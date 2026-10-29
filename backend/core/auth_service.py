import logging
import re

from fastapi import Header
from fastapi import HTTPException
from firebase_admin import get_app
from firebase_admin import auth


logger = logging.getLogger("uvicorn.error")


def _invalidTokenReason(error: Exception) -> str:
    message = str(error)
    earlyMatch = re.search(r"Token used too early, (\d+) < (\d+)", message)
    if earlyMatch is not None:
        secondsEarly = int(earlyMatch.group(2)) - int(earlyMatch.group(1))
        return f"token issued {secondsEarly} seconds ahead of backend clock"
    if 'incorrect "aud"' in message:
        return "Firebase project mismatch (audience)"
    if 'incorrect "iss"' in message:
        return "Firebase project mismatch (issuer)"
    if "given a custom token" in message:
        return "custom token supplied instead of an ID token"
    if 'no "kid"' in message:
        return "missing token key ID"
    if "incorrect algorithm" in message:
        return "incorrect token algorithm"
    if "Certificate for key id" in message and "not found" in message:
        return "token signing key missing from Firebase certificates"
    if "Could not verify token signature" in message:
        return "token signature does not match Firebase certificates"
    if "Wrong number of segments" in message:
        return "malformed ID token"
    if "Token does not contain required claim" in message:
        return "ID token missing a required time claim"
    return f"invalid ID token ({type(error.__cause__).__name__})"


def requireVerifiedFirebaseUser(
    authorization: str | None = Header(default=None),
):
    if authorization is None or not authorization.startswith("Bearer "):
        logger.warning("Firebase authentication failed: missing Bearer header")
        raise HTTPException(
            status_code=401,
            detail="A Firebase ID token is required.",
        )

    idToken = authorization.removeprefix("Bearer ").strip()
    if idToken == "":
        logger.warning("Firebase authentication failed: empty ID token")
        raise HTTPException(
            status_code=401,
            detail="A Firebase ID token is required.",
        )

    try:
        decodedToken = auth.verify_id_token(idToken, clock_skew_seconds=5)
    except auth.CertificateFetchError as error:
        logger.error("Firebase authentication unavailable: certificate fetch failed")
        raise HTTPException(
            status_code=503,
            detail="The backend could not verify Firebase tokens right now.",
        ) from error
    except auth.ExpiredIdTokenError as error:
        logger.warning("Firebase authentication failed: expired ID token")
        raise HTTPException(
            status_code=401,
            detail="The Firebase ID token has expired.",
        ) from error
    except auth.InvalidIdTokenError as error:
        logger.warning(
            "Firebase authentication failed: %s; backend project: %s",
            _invalidTokenReason(error),
            get_app().project_id,
        )
        raise HTTPException(
            status_code=401,
            detail="The Firebase ID token is invalid.",
        ) from error
    except Exception as error:
        logger.error(
            "Firebase authentication unavailable: %s",
            type(error).__name__,
        )
        raise HTTPException(
            status_code=503,
            detail="The backend could not verify Firebase tokens right now.",
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
