# Feature 08: Home and navigation

[Checklist](README.md) | [Previous](07-assessment-notation-piano-and-results.md) | [Next](09-feature-tutorials.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/homescreen/screens/home_screen.dart#L46' style='text-decoration:underline'>lib/screens/homescreen/screens<br/>home_screen.dart:46-73</a><br/>Prepare Home, load the profile, then request the guide<br/>Tell processing announcements that navigation is ready"]
    B["02. <a href='../../lib/screens/homescreen/screens/home_screen.dart#L276' style='text-decoration:underline'>lib/screens/homescreen/screens<br/>home_screen.dart:276-297</a><br/>Load the user's name, colors, skill level and XP"]
    C["03. <a href='../../lib/screens/profile/widgets/player_progress_container.dart#L25' style='text-decoration:underline'>lib/screens/profile/widgets<br/>player_progress_container.dart:25-190</a><br/>Listen for profile changes and show skill rank, XP and level<br/>Each 100 XP adds one player level"]
    D["04. <a href='../../lib/screens/homescreen/widgets/quick_actions.dart#L30' style='text-decoration:underline'>lib/screens/homescreen/widgets<br/>quick_actions.dart:30-142</a><br/>Show buttons for the main app features"]
    E["05. <a href='../../lib/screens/homescreen/screens/home_screen.dart#L299' style='text-decoration:underline'>lib/screens/homescreen/screens<br/>home_screen.dart:299-367</a><br/>Open the screen selected through a Home callback"]
    F["06. <a href='../../lib/screens/homescreen/widgets/practice_container.dart#L7' style='text-decoration:underline'>lib/screens/homescreen/widgets<br/>practice_container.dart:7-111</a><br/>Open the lessons from the practice shortcut"]
    G["07. <a href='../../lib/screens/homescreen/widgets/community_compositions_section.dart#L43' style='text-decoration:underline'>lib/screens/homescreen/widgets<br/>community_compositions_section.dart:43-149</a><br/>Listen for shared compositions and show loading, error or song cards<br/>Card tap opens its viewer: community_compositions_section.dart:169-172"]
    H["08. <a href='../../lib/screens/composition/services/published_composition_service.dart#L11' style='text-decoration:underline'>lib/screens/composition/services<br/>published_composition_service.dart:11-30</a><br/>Read the shared songs saved in compositionPosts"]
    PLAY["<a href='../../lib/screens/homescreen/widgets/community_compositions_section.dart#L370' style='text-decoration:underline'>lib/screens/homescreen/widgets<br/>community_compositions_section.dart:370-396</a><br/>Play button calls the controller; its listener refreshes the button"]
    I["09. <a href='../../lib/screens/composition/controllers/published_composition_playback_controller.dart#L33' style='text-decoration:underline'>lib/screens/composition/controllers<br/>published_composition_playback_controller.dart:33-109</a><br/>Stop the previous song; request the MP3 URL and start playback<br/>Ignore older requests and reset controls on completion"]
    URL["<a href='../../lib/screens/composition/services/published_composition_service.dart#L79' style='text-decoration:underline'>lib/screens/composition/services<br/>published_composition_service.dart:79-89</a><br/>Get the song's MP3 download URL from Firebase Storage"]
    AUDIO["<a href='../../lib/screens/players/services/score_audio_playback_service.dart#L13' style='text-decoration:underline'>lib/screens/players/services<br/>score_audio_playback_service.dart:13-87</a><br/>Play the URL with audioplayers; report start, finish or failure"]
    J["10. <a href='../../lib/widgets/drawer.dart#L39' style='text-decoration:underline'>lib/widgets<br/>drawer.dart:39-558</a><br/>Show navigation, appearance, language, help and logout choices"]
    K["11. <a href='../../lib/widgets/drawer_profile_header.dart#L9' style='text-decoration:underline'>lib/widgets<br/>drawer_profile_header.dart:9-166</a><br/>Show the latest profile information and open Profile when tapped"]
    L["12. <a href='../../lib/screens/homescreen/screens/home_screen.dart#L307' style='text-decoration:underline'>lib/screens/homescreen/screens<br/>home_screen.dart:307-321</a><br/>Wait for a successful upload, then open the sheet collection"]
    UI["<a href='../../lib/screens/homescreen/screens/home_screen.dart#L87' style='text-decoration:underline'>lib/screens/homescreen/screens<br/>home_screen.dart:87-274</a><br/>Build the page and connect each widget to its callback<br/>Search opens the music library: home_screen.dart:155-164"]
    A --> B
    UI --> C
    B -- "Update displayed profile values" --> UI
    UI --> D --> E
    UI --> F
    UI --> G --> H
    H -- "Stream returns the latest 3 songs" --> G
    G -- "Play preview" --> PLAY --> I
    I -- "Request URL" --> URL
    URL -- "Return URL to controller" --> I
    I -- "Start audio" --> AUDIO
    AUDIO -. "Completion updates the controller and button" .-> PLAY
    G -- "See All or tap a card" --> E
    UI --> J --> K
    K -- "Profile tap uses callback in drawer.dart:89-102" --> PROFILE["Open ProfileScreen"]
    E -- "Add sheet" --> L```
