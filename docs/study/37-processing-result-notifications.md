# Feature 37: Processing-result notifications

[Checklist](README.md) | [Previous](36-notification-device-registration.md) | [Next](38-admin-application.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../backend/jobs/repositories/firebase_bridge.py#L120' style='text-decoration:underline'>backend/jobs/repositories<br/>firebase_bridge.py:120-149</a><br/>Save whether processing finished or failed in Firestore"]
    B["02. <a href='../../backend/jobs/repositories/store.py#L181' style='text-decoration:underline'>backend/jobs/repositories<br/>store.py:181-189</a><br/>Save the final result and add a notification for each registered phone"]
    C["03. <a href='../../backend/jobs/worker.py#L127' style='text-decoration:underline'>backend/jobs<br/>worker.py:127-133</a><br/>Try sending pending notifications, with retries if needed"]
    D["04. <a href='../../backend/jobs/services/notifications.py#L6' style='text-decoration:underline'>backend/jobs/services<br/>notifications.py:6-29</a><br/>Use Firebase to send the phone a message in its chosen language"]
    E["05. <a href='../../lib/services/processing_announcements.dart#L164' style='text-decoration:underline'>lib/services<br/>processing_announcements.dart:164-169</a><br/>Handle a notification that opened the app"]
    F["06. <a href='../../lib/services/processing_announcements.dart#L94' style='text-decoration:underline'>lib/services<br/>processing_announcements.dart:94-114</a><br/>Listen for messages while the app is open and for notification taps"]
    G["07. <a href='../../lib/services/processing_announcements.dart#L116' style='text-decoration:underline'>lib/services<br/>processing_announcements.dart:116-162</a><br/>Also check Firestore for processing results the user has not seen"]
    H["08. <a href='../../lib/services/processing_announcements.dart#L232' style='text-decoration:underline'>lib/services<br/>processing_announcements.dart:232-248</a><br/>Wait until the app is open and ready to show the signed-in screens"]
    I["09. <a href='../../lib/services/processing_announcements.dart#L250' style='text-decoration:underline'>lib/services<br/>processing_announcements.dart:250-315</a><br/>Show the newest processing message and remember it was seen"]
    J["10. <a href='../../lib/services/processing_announcements.dart#L323' style='text-decoration:underline'>lib/services<br/>processing_announcements.dart:323-387</a><br/>Open the sheet or composition mentioned by the notification"]
    K["The saved Firestore record holds the result<br/>A failed notification send is retried without rerunning the processing job"]
    A --> B --> C --> D
    D -- "App launched by tap" --> E --> H
    D -- "App open or notification tapped" --> F --> H
    A -. "App notices the saved update" .-> G --> H
    H --> I
    H -- "User tapped a notification" --> J
    I -- "Open action" --> J
    C -. "Retry sending the update" .-> K```
