# Feature 01: App startup

[Checklist](README.md) | [Next](02-initial-screen-selection.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

Solid arrows show startup calls and returns. Dotted arrows show related code or later updates.

```mermaid
flowchart TD
    A["01. <a href='../../lib/main.dart#L23' style='text-decoration:underline'>lib/main.dart:23-28</a><br/>Prepare Flutter, set portrait mode and start navigation-bar setup"]
    B["02. <a href='../../lib/services/system_navigation_service.dart#L16' style='text-decoration:underline'>lib/services/system_navigation_service.dart:16-22</a><br/>On Android, watch keyboard changes and request hiding the navigation bar"]
    C["03. <a href='../../lib/services/system_navigation_service.dart#L27' style='text-decoration:underline'>lib/services/system_navigation_service.dart:27-33</a><br/>Hide the bar only when the keyboard is closed and the app is active"]
    KEY["<a href='../../lib/services/system_navigation_service.dart#L24' style='text-decoration:underline'>lib/services/system_navigation_service.dart:24-25</a><br/>Check whether the keyboard is visible"]
    D["04. <a href='../../android/app/src/main/kotlin/com/example/soundsight/MainActivity.kt#L21' style='text-decoration:underline'>android/app/src/main/kotlin/com/example/soundsight/MainActivity.kt:21-34</a><br/>Android receives the request and hides its navigation bar"]
    E["05. <a href='../../lib/main.dart#L30' style='text-decoration:underline'>lib/main.dart:30-30</a><br/>Return to main and prepare Firebase"]
    F["06. <a href='../../lib/main.dart#L32' style='text-decoration:underline'>lib/main.dart:32-34</a><br/>On Android, register the background-message function"]
    BG["<a href='../../lib/services/processing_announcements.dart#L21' style='text-decoration:underline'>lib/services/processing_announcements.dart:21-23</a><br/>Inspect the registered function, then return to main<br/>It currently adds no action; Firebase displays notification payloads"]
    G["07. <a href='../../lib/main.dart#L35' style='text-decoration:underline'>lib/main.dart:35-35</a><br/>Start displaying SoundSight"]
    H["08. <a href='../../lib/main.dart#L38' style='text-decoration:underline'>lib/main.dart:38-51</a><br/>Create the app widget and its shared navigation, language and message objects"]
    I["09. <a href='../../lib/main.dart#L54' style='text-decoration:underline'>lib/main.dart:54-57</a><br/>Begin reading the saved language without waiting for it to finish"]
    J["10. <a href='../../lib/main.dart#L98' style='text-decoration:underline'>lib/main.dart:98-111</a><br/>If signed in, read the saved language<br/>Otherwise keep the default English language"]
    K["11. <a href='../../lib/localization/app_locale_controller.dart#L10' style='text-decoration:underline'>lib/localization/app_locale_controller.dart:10-12</a><br/>Ask the language helper to understand the saved choice"]
    L["12. <a href='../../lib/localization/app_language.dart#L3' style='text-decoration:underline'>lib/localization/app_language.dart:3-18</a><br/>Choose English or Filipino; use English for an unknown choice"]
    M["13. <a href='../../lib/localization/app_locale_controller.dart#L14' style='text-decoration:underline'>lib/localization/app_locale_controller.dart:14-18</a><br/>Apply the choice and announce a change if the language is different"]
    N["14. <a href='../../lib/main.dart#L67' style='text-decoration:underline'>lib/main.dart:67-96</a><br/>Build the app with navigation, translations and shared messages"]
    O["15. <a href='../../lib/main.dart#L90' style='text-decoration:underline'>lib/main.dart:90-90</a><br/>Use AuthenticationGate to choose the starting screen"]
    A --> B
    B -- Android --> C
    B -- "Other platform: skip this helper" --> E
    C -. "Keyboard check" .-> KEY
    C -- "Keyboard closed and app active" --> D
    C -- "Otherwise skip hiding for now" --> E
    D -- "Request finishes; return to main" --> E
    E --> F --> G --> H --> I
    F -. "Registered now; called later for background messages" .-> BG
    I -- "Read language in the background" --> J
    J -- "Saved profile read successfully" --> K --> L --> M
    I -- "Continue building without waiting for the language" --> N --> O
    M -. "Refresh when the chosen language changes" .-> N```
