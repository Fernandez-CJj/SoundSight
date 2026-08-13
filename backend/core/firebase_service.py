import firebase_admin

from firebase_admin import firestore
from firebase_admin import storage


firebaseApp = firebase_admin.initialize_app(
    options={
        "storageBucket": (
            "soundsight-b1d16.firebasestorage.app"
        )
    }
)

database = firestore.client()


def getDatabase():
    return database


def getStorageBucket():
    return storage.bucket()
