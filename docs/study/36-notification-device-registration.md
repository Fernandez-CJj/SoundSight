# Feature 36: Setting up processing notifications

[Checklist](README.md) | [Previous](35-achievements-and-badges.md) | [Next](37-processing-result-notifications.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/services/processing_job_service.dart#L154' style='text-decoration:underline'>lib/services<br/>processing_job_service.dart:154-154</a><br/>The backend accepts a processing request"]
    B["02. <a href='../../lib/services/processing_announcements.dart#L171' style='text-decoration:underline'>lib/services<br/>processing_announcements.dart:171-181</a><br/>On Android, ask once for permission to send notifications"]
    C["03. <a href='../../lib/services/processing_announcements.dart#L183' style='text-decoration:underline'>lib/services<br/>processing_announcements.dart:183-225</a><br/>Get this phone's notification address, installation ID and language"]
    D["04. <a href='../../backend/jobs/routes.py#L108' style='text-decoration:underline'>backend/jobs<br/>routes.py:108-113</a><br/>Check who is asking to register the phone"]
    E["05. <a href='../../backend/jobs/repositories/store.py#L215' style='text-decoration:underline'>backend/jobs/repositories<br/>store.py:215-219</a><br/>Remember which account, phone and language should receive updates"]
    F["06. <a href='../../lib/services/processing_announcements.dart#L42' style='text-decoration:underline'>lib/services<br/>processing_announcements.dart:42-65</a><br/>When logging out through the drawer, stop this phone's account notifications first"]
    G["07. <a href='../../backend/jobs/repositories/store.py#L221' style='text-decoration:underline'>backend/jobs/repositories<br/>store.py:221-223</a><br/>Remove the matching phone and account from the notification list"]
    A --> B --> C --> D --> E
    F --> G
    G -. "Stop targeting signed-out installation" .-> E```
