# Feature 11: Appearance, language and logout

[Checklist](README.md) | [Previous](10-profile-editing.md) | [Next](12-sheet-selection-and-preview.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/profile/widgets/preferences_container.dart#L40' style='text-decoration:underline'>lib/screens/profile/widgets<br/>preferences_container.dart:40-72</a><br/>Changing the switch calls onDarkModeChanged<br/>Profile connects it to updateTheme: <a href='../../lib/screens/profile/screens/profile_screen.dart#L122' style='text-decoration:underline'>profile_screen.dart:122-126</a>"]
    B["02. <a href='../../lib/screens/profile/screens/profile_screen.dart#L255' style='text-decoration:underline'>lib/screens/profile/screens<br/>profile_screen.dart:255-267</a><br/>Change the screen colors now and save the choice"]
    C["03. <a href='../../lib/theme/app_theme_colors.dart#L37' style='text-decoration:underline'>lib/theme<br/>app_theme_colors.dart:37-71</a><br/>Choose the light or dark color set<br/>Color values: <a href='../../lib/theme/app_colors.dart#L3' style='text-decoration:underline'>app_colors.dart:3-32</a>"]
    DRAWERTHEME["Drawer appearance switch: <a href='../../lib/widgets/drawer.dart#L287' style='text-decoration:underline'>lib/widgets/drawer.dart:287-308</a><br/>Call the owning screen's callback and save the theme<br/><a href='../../lib/widgets/drawer.dart#L362' style='text-decoration:underline'>drawer.dart:362-373</a>"]
    D["04. <a href='../../lib/widgets/drawer.dart#L375' style='text-decoration:underline'>lib/widgets<br/>drawer.dart:375-449</a><br/>Choose English or Filipino, update the app and save the choice<br/>Language tap: <a href='../../lib/widgets/drawer.dart#L285' style='text-decoration:underline'>drawer.dart:285-285</a><br/>Restore on startup: <a href='../../lib/main.dart#L98' style='text-decoration:underline'>main.dart:98-111</a>"]
    E["05. <a href='../../lib/localization/app_locale_controller.dart#L4' style='text-decoration:underline'>lib/localization<br/>app_locale_controller.dart:4-20</a><br/>Keep the chosen language in memory and notify listeners<br/>Language codes: <a href='../../lib/localization/app_language.dart#L3' style='text-decoration:underline'>app_language.dart:3-18</a>"]
    F["06. <a href='../../lib/main.dart#L67' style='text-decoration:underline'>lib/main.dart:67-96</a><br/>AnimatedBuilder updates MaterialApp.locale<br/>This rebuilds the app configuration without navigating away"]
    G["07. <a href='../../lib/localization/localization_extension.dart#L4' style='text-decoration:underline'>lib/localization<br/>localization_extension.dart:4-6</a><br/>context.l10n reads the current translations<br/>Locale selection: <a href='../../lib/translations/generated/app_localizations.dart#L8943' style='text-decoration:underline'>app_localizations.dart:8943-8962</a>"]
    H["08. <a href='../../lib/screens/profile/widgets/logout_container.dart#L26' style='text-decoration:underline'>lib/screens/profile/widgets<br/>logout_container.dart:26-110</a><br/>Confirm Profile logout, sign out and reset the displayed language<br/>This path does not call unregisterDevice"]
    I["09. <a href='../../lib/widgets/drawer.dart#L332' style='text-decoration:underline'>lib/widgets<br/>drawer.dart:332-337</a><br/>Confirm drawer logout and request notification cleanup"]
    J["10. <a href='../../lib/services/processing_announcements.dart#L42' style='text-decoration:underline'>lib/services<br/>processing_announcements.dart:42-65</a><br/>On Android, attempt to delete the backend device entry and FCM token<br/>Cleanup failures do not prevent logout"]
    TOKEN["<a href='../../lib/services/processing_job_service.dart#L279' style='text-decoration:underline'>lib/services/processing_job_service.dart:279-285</a><br/>Get the signed-in user's Firebase ID token"]
    REQUEST["<a href='../../lib/constants/backend_config.dart#L83' style='text-decoration:underline'>lib/constants/backend_config.dart:83-126</a><br/>Resolve the backend address and send the DELETE request"]
    API["<a href='../../backend/jobs/routes.py#L116' style='text-decoration:underline'>backend/jobs/routes.py:116-119</a><br/>Require a verified user and request device removal"]
    DB["<a href='../../backend/jobs/repositories/store.py#L221' style='text-decoration:underline'>backend/jobs/repositories/store.py:221-223</a><br/>Delete the SQLite device row matching this installation and user"]
    K["12. <a href='../../lib/widgets/drawer.dart#L346' style='text-decoration:underline'>lib/widgets/drawer.dart:346-349</a><br/>Clear previous screens and open Login<br/>Profile equivalent: <a href='../../lib/screens/profile/widgets/logout_container.dart#L107' style='text-decoration:underline'>logout_container.dart:107-110</a>"]
    L["Translation source files:<br/><a href='../../lib/translations/app_en.arb#L75' style='text-decoration:underline'>lib/translations/app_en.arb:75-76</a><br/><a href='../../lib/translations/app_fil.arb#L75' style='text-decoration:underline'>lib/translations/app_fil.arb:75-76</a><br/>Generation settings: <a href='../../l10n.yaml#L1' style='text-decoration:underline'>l10n.yaml:1-6</a>"]
    A --> B --> C
    DRAWERTHEME --> C
    D --> E --> F --> G
    L -. "Generated translations" .-> G
    H --> K
    M["11. <a href='../../lib/widgets/drawer.dart#L338' style='text-decoration:underline'>lib/widgets<br/>drawer.dart:338-344</a><br/>Sign out and reset the displayed language to English"]
    I --> J --> M --> K    J -- "If an installation ID and signed-in user exist" --> TOKEN --> REQUEST --> API --> DB
    DB -. "Response returns to cleanup" .-> J
```
