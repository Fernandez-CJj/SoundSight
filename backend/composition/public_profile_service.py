from core.firebase_service import getDatabase


def getPublicProfile(userId):
    username = "SoundSight Musician"
    profileImageUrl = ""

    if userId == "":
        return {
            "username": username,
            "profileImageUrl": profileImageUrl,
        }

    database = getDatabase()

    userDocument = database.collection(
        "users"
    ).document(
        userId
    ).get()

    if userDocument.exists:
        userData = userDocument.to_dict()

        savedUsername = userData.get(
            "username"
        )

        savedProfileImageUrl = userData.get(
            "profileImageUrl"
        )

        if (
            isinstance(savedUsername, str)
            and savedUsername.strip() != ""
        ):
            username = savedUsername.strip()

        if isinstance(savedProfileImageUrl, str):
            profileImageUrl = savedProfileImageUrl

    return {
        "username": username,
        "profileImageUrl": profileImageUrl,
    }
