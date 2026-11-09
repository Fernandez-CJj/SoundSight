# Feature 10: Profile and editing

[Checklist](README.md) | [Previous](09-feature-tutorials.md) | [Next](11-appearance-language-and-logout.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/profile/screens/profile_screen.dart#L136' style='text-decoration:underline'>lib/screens/profile/screens<br/>profile_screen.dart:136-176</a><br/>Load assessment progress, then the user's profile"]
    B["02. <a href='../../lib/screens/profile/widgets/profile_container.dart#L8' style='text-decoration:underline'>lib/screens/profile/widgets<br/>profile_container.dart:8-222</a><br/>Show the name, email and profile picture"]
    C["03. <a href='../../lib/screens/profile/widgets/player_progress_container.dart#L38' style='text-decoration:underline'>lib/screens/profile/widgets<br/>player_progress_container.dart:38-190</a><br/>Keep skill rank, XP and level up to date"]
    D["04. <a href='../../lib/screens/profile/widgets/achievements_container.dart#L44' style='text-decoration:underline'>lib/screens/profile/widgets<br/>achievements_container.dart:44-50</a><br/>Load earned badges and recognize older saved progress"]
    E["05. <a href='../../lib/screens/profile/widgets/assessment_container.dart#L8' style='text-decoration:underline'>lib/screens/profile/widgets<br/>assessment_container.dart:8-87</a><br/>Show the assessment action that matches the saved progress"]
    F["06. <a href='../../lib/screens/profile/screens/profile_screen.dart#L269' style='text-decoration:underline'>lib/screens/profile/screens<br/>profile_screen.dart:269-295</a><br/>Open the editor when the pencil is tapped"]
    G["07. <a href='../../lib/screens/profile/dialogs/edit_profile_sheet.dart#L193' style='text-decoration:underline'>lib/screens/profile/dialogs<br/>edit_profile_sheet.dart:193-221</a><br/>Choose a picture from the gallery and preview it"]
    H["08. <a href='../../lib/screens/profile/dialogs/edit_profile_sheet.dart#L108' style='text-decoration:underline'>lib/screens/profile/dialogs<br/>edit_profile_sheet.dart:108-176</a><br/>Check the name and ask whether to save the changes"]
    I["09. <a href='../../lib/screens/profile/dialogs/edit_profile_sheet.dart#L178' style='text-decoration:underline'>lib/screens/profile/dialogs<br/>edit_profile_sheet.dart:178-191</a><br/>Upload the picture to profilePictures/UID/profile.jpg"]
    J["10. <a href='../../lib/screens/profile/dialogs/edit_profile_sheet.dart#L155' style='text-decoration:underline'>lib/screens/profile/dialogs<br/>edit_profile_sheet.dart:155-155</a><br/>Save the name and picture link in the user's profile"]
    K["11. <a href='../../lib/screens/profile/screens/profile_screen.dart#L292' style='text-decoration:underline'>lib/screens/profile/screens<br/>profile_screen.dart:292-292</a><br/>Show the saved changes on Profile"]
    A --> B
    A --> C
    A --> D
    A --> E
    B -. "Edit via screen pencil" .-> F --> G --> H --> I --> J --> K
    H -- "Name only" --> I```
