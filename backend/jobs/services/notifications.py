"""Durable per-device completion delivery. Firebase records remain authoritative."""
import logging
from firebase_admin import messaging


def deliver(store):
    for delivery in store.deliveries():
        job = store.get(delivery["job"])
        success = job["state"] == "completed"
        filipino = delivery["language"] == "fil"
        title = ("Handa na ang iyong musika" if success else "Hindi natapos ang iyong musika") if filipino else (
            "Your music is ready" if success else "We couldn't finish your music")
        body = (("Buksan ang SoundSight para tingnan at pakinggan ito." if success else
                 "Buksan ang SoundSight para subukan muli.") if filipino else
                "Open SoundSight to view and play it." if success else "Open SoundSight to try again.")
        try:
            messaging.send(messaging.Message(
                token=delivery["token"], notification=messaging.Notification(title, body),
                data={"jobId": job["id"], "ownerId": job["owner"], "taskType": job["kind"],
                      "targetId": job["target"], "eventId": job["id"], "status": job["state"]},
                android=messaging.AndroidConfig(priority="high", ttl=86400,
                    notification=messaging.AndroidNotification(channel_id="processing_results",
                        icon="ic_processing_notification", tag=job["id"]))))
            store.delivery_done(delivery)
        except messaging.UnregisteredError:
            store.delivery_done(delivery, invalid=True)
        except Exception:
            logging.exception("Could not send the completion notification; will retry | job=%s", job["id"])
            store.delivery_retry(delivery)
