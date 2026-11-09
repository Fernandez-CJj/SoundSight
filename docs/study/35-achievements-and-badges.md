# Feature 35: Achievements and badges

[Checklist](README.md) | [Previous](34-practice-results.md) | [Next](36-notification-device-registration.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/assessment/services/assessment_attempt_service.dart#L437' style='text-decoration:underline'>lib/screens/assessment/services<br/>assessment_attempt_service.dart:437-465</a><br/>Finishing the assessment can earn First Measure"]
    B["02. <a href='../../lib/screens/capture_upload_sheet/services/music_sheet_upload_service.dart#L99' style='text-decoration:underline'>lib/screens/capture_upload_sheet/services<br/>music_sheet_upload_service.dart:99-110</a><br/>The first sheet upload can earn Sheet Collector"]
    C["03. <a href='../../lib/screens/composition/services/composition_service.dart#L64' style='text-decoration:underline'>lib/screens/composition/services<br/>composition_service.dart:64-96</a><br/>The first saved composition can earn First Composer"]
    D["04. <a href='../../lib/screens/lessons/services/practice_progress_service.dart#L29' style='text-decoration:underline'>lib/screens/lessons/services<br/>practice_progress_service.dart:29-66</a><br/>Completing lesson milestones can earn badges and XP"]
    E["05. <a href='../../lib/achievements/models/achievement_badge.dart#L3' style='text-decoration:underline'>lib/achievements/models<br/>achievement_badge.dart:3-59</a><br/>Define the nine badges, their pictures and translated descriptions"]
    F["06. <a href='../../lib/achievements/repositories/achievement_repository.dart#L13' style='text-decoration:underline'>lib/achievements/repositories<br/>achievement_repository.dart:13-13</a><br/>Prepare the details saved when a badge is earned"]
    G["Store each badge at users/UID/achievements/BADGE_ID<br/>Do not award the same saved badge repeatedly"]
    H["07. <a href='../../lib/achievements/widgets/achievement_announcements.dart#L120' style='text-decoration:underline'>lib/achievements/widgets<br/>achievement_announcements.dart:120-136</a><br/>Notice a newly earned badge and add its message to the waiting list"]
    I["08. <a href='../../lib/achievements/widgets/achievement_announcements.dart#L165' style='text-decoration:underline'>lib/achievements/widgets<br/>achievement_announcements.dart:165-192</a><br/>Show the badge message when another popup is not in the way"]
    J["09. <a href='../../lib/screens/profile/widgets/achievements_container.dart#L44' style='text-decoration:underline'>lib/screens/profile/widgets<br/>achievements_container.dart:44-50</a><br/>Recognize older progress and show earned badges on Profile"]
    A --> F
    B --> F
    C --> F
    D --> F
    F --> G --> H --> I
    E -. "Badge definitions" .-> F
    G --> J```
