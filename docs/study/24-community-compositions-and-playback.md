# Feature 24: Community compositions and playback

[Checklist](README.md) | [Previous](23-composition-publishing.md) | [Next](25-midi-connection.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/composition/screens/published_compositions_screen.dart#L22' style='text-decoration:underline'>lib/screens/composition/screens<br/>published_compositions_screen.dart:22-33</a><br/>Browse songs shared by the community"]
    B["02. <a href='../../lib/screens/composition/services/published_composition_feed_service.dart#L30' style='text-decoration:underline'>lib/screens/composition/services<br/>published_composition_feed_service.dart:30-100</a><br/>Gather the song versions and details needed by the list"]
    C["03. <a href='../../lib/screens/composition/widgets/published_composition_card.dart#L10' style='text-decoration:underline'>lib/screens/composition/widgets<br/>published_composition_card.dart:10-41</a><br/>Show the song, its author, preview, likes, comments and Save"]
    D["04. <a href='../../lib/screens/composition/screens/published_composition_viewer_screen.dart#L21' style='text-decoration:underline'>lib/screens/composition/screens<br/>published_composition_viewer_screen.dart:21-34</a><br/>Open the shared score and practice choices"]
    E["05. <a href='../../lib/screens/composition/services/published_composition_social_service.dart#L36' style='text-decoration:underline'>lib/screens/composition/services<br/>published_composition_social_service.dart:36-62</a><br/>Add or remove this user's like for this song version"]
    F["06. <a href='../../lib/screens/composition/screens/published_composition_comments_screen.dart#L12' style='text-decoration:underline'>lib/screens/composition/screens<br/>published_composition_comments_screen.dart:12-25</a><br/>Read, add or delete comments"]
    G["07. <a href='../../lib/screens/composition/services/published_composition_social_service.dart#L173' style='text-decoration:underline'>lib/screens/composition/services<br/>published_composition_social_service.dart:173-200</a><br/>Save this song version or remove it from Saved"]
    H["08. <a href='../../lib/screens/composition/screens/saved_compositions_screen.dart#L18' style='text-decoration:underline'>lib/screens/composition/screens<br/>saved_compositions_screen.dart:18-26</a><br/>Show saved song versions and open the selected one"]
    I["09. <a href='../../lib/screens/composition/controllers/published_composition_playback_controller.dart#L33' style='text-decoration:underline'>lib/screens/composition/controllers<br/>published_composition_playback_controller.dart:33-109</a><br/>Use the same Play controls on Home, community, details and Saved"]
    J["10. <a href='../../lib/screens/composition/services/published_composition_service.dart#L79' style='text-decoration:underline'>lib/screens/composition/services<br/>published_composition_service.dart:79-89</a><br/>Get a playable link to the saved MP3"]
    K["11. <a href='../../lib/screens/players/services/score_audio_playback_service.dart#L13' style='text-decoration:underline'>lib/screens/players/services<br/>score_audio_playback_service.dart:13-87</a><br/>Play the MP3 and stop or release the player when finished"]
    L["Show a message if the file cannot be played<br/>Shared-song previews use the saved MP3"]
    A --> B --> C
    C -- Open --> D
    C -- Like --> E
    C -- Comment --> F
    C -- Save --> G --> H
    C -- Play --> I
    D -- Play --> I
    H -- Play --> I
    I --> J --> K
    K -- Error --> L```
