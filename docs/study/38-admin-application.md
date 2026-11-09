# Feature 38: Admin application

[Checklist](README.md) | [Previous](37-processing-result-notifications.md) | [Next](39-landing-website.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../soundsight_admin/lib/main.dart#L13' style='text-decoration:underline'>soundsight_admin/lib<br/>main.dart:13-17</a><br/>Start the admin website and prepare Firebase"]
    B["02. <a href='../../soundsight_admin/lib/firebase_options.dart#L4' style='text-decoration:underline'>soundsight_admin/lib<br/>firebase_options.dart:4-14</a><br/>Choose the Firebase project used by the admin website"]
    C["03. <a href='../../soundsight_admin/lib/main.dart#L47' style='text-decoration:underline'>soundsight_admin/lib<br/>main.dart:47-59</a><br/>Check whether someone is signed in"]
    D["04. <a href='../../soundsight_admin/lib/main.dart#L160' style='text-decoration:underline'>soundsight_admin/lib<br/>main.dart:160-165</a><br/>Sign in using email and password"]
    E["05. <a href='../../soundsight_admin/lib/main.dart#L72' style='text-decoration:underline'>soundsight_admin/lib<br/>main.dart:72-78</a><br/>Read whether this account is listed as an enabled admin"]
    F{"Is this an enabled admin account?"}
    G["Explain that access is denied and offer Retry or Sign out"]
    H["06. <a href='../../soundsight_admin/lib/main.dart#L287' style='text-decoration:underline'>soundsight_admin/lib<br/>main.dart:287-301</a><br/>Show dashboard sections and the light/dark setting"]
    I["07. <a href='../../soundsight_admin/lib/library_screen.dart#L269' style='text-decoration:underline'>soundsight_admin/lib<br/>library_screen.dart:269-274</a><br/>View, add, edit, preview or delete library songs"]
    J["08. <a href='../../soundsight_admin/lib/library_screen.dart#L119' style='text-decoration:underline'>soundsight_admin/lib<br/>library_screen.dart:119-228</a><br/>Upload the song files and save their details in available_pieces"]
    K["09. <a href='../../soundsight_admin/lib/library_screen.dart#L243' style='text-decoration:underline'>soundsight_admin/lib<br/>library_screen.dart:243-266</a><br/>Delete the chosen song's files and saved record"]
    L["10. <a href='../../soundsight_admin/lib/read_only_screens.dart#L19' style='text-decoration:underline'>soundsight_admin/lib<br/>read_only_screens.dart:19-24</a><br/>View users and their profile details"]
    M["11. <a href='../../soundsight_admin/lib/read_only_screens.dart#L153' style='text-decoration:underline'>soundsight_admin/lib<br/>read_only_screens.dart:153-158</a><br/>View shared compositions and open their files"]
    N["12. <a href='../../soundsight_admin/lib/admin_theme.dart#L48' style='text-decoration:underline'>soundsight_admin/lib<br/>admin_theme.dart:48-106</a><br/>Choose the admin website's light or dark colors"]
    O["The mobile app reads these library songs<br/>See Feature 19"]
    P["13. <a href='../../firestore.rules#L10' style='text-decoration:underline'>firestore.rules:10-15</a><br/>Firebase checks that the account may access these records"]
    Q["14. <a href='../../storage.rules#L16' style='text-decoration:underline'>storage.rules:16-21</a><br/>Firebase checks that the account may access these files"]
    A --> C
    A -. "Choose the Firebase project" .-> B
    C -- "Not signed in" --> D --> C
    C -- "Signed in" --> E --> F
    F -- No --> G
    F -- Yes --> H
    H --> I --> J --> O
    I -- Delete --> K
    H --> L
    H --> M
    H -. "Theme" .-> N
    J -. "Check permission to read or save records" .-> P
    J -. "Check permission to read or save files" .-> Q```
