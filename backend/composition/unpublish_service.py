from composition.storage_service import deletePublishedCompositionFiles
from core.firebase_service import getDatabase


def unpublishComposition(
    compositionId,
    ownerId,
):
    database = getDatabase()

    postReference = database.collection(
        "compositionPosts"
    ).document(
        compositionId
    )

    postDocument = postReference.get()

    if not postDocument.exists:
        return False

    postData = postDocument.to_dict()

    if postData.get("ownerId") != ownerId:
        raise PermissionError(
            "Only the owner can unpublish this composition."
        )

    deletePublishedCompositionFiles(
        ownerId,
        compositionId,
    )

    for versionDocument in postReference.collection(
        "versions"
    ).stream():
        for likeDocument in versionDocument.reference.collection(
            "likes"
        ).stream():
            likeDocument.reference.delete()

        for commentDocument in versionDocument.reference.collection(
            "comments"
        ).stream():
            commentDocument.reference.delete()

        versionDocument.reference.delete()

    for savedDocument in database.collection(
        "savedCompositionPosts"
    ).where(
        "postId",
        "==",
        compositionId,
    ).stream():
        savedDocument.reference.delete()

    postReference.delete()

    return True
