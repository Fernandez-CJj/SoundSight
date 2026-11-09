# Feature 18: Music-sheet collection and viewer

[Checklist](README.md) | [Previous](17-audio-transcription.md) | [Next](19-music-library.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/music_sheet/screens/music_sheet_screen.dart#L22' style='text-decoration:underline'>lib/screens/music_sheet/screens<br/>music_sheet_screen.dart:22-29</a><br/>Open the user's saved sheets and watch for updates"]
    B["02. <a href='../../lib/screens/music_sheet/widgets/music_sheet_card.dart#L9' style='text-decoration:underline'>lib/screens/music_sheet/widgets<br/>music_sheet_card.dart:9-202</a><br/>Show each sheet's name, type and processing progress"]
    C["03. <a href='../../lib/screens/music_sheet/screens/music_sheet_screen.dart#L444' style='text-decoration:underline'>lib/screens/music_sheet/screens<br/>music_sheet_screen.dart:444-463</a><br/>Open the selected sheet in the viewer"]
    D["04. <a href='../../lib/screens/music_sheet/screens/music_sheet_viewer_screen.dart#L75' style='text-decoration:underline'>lib/screens/music_sheet/screens<br/>music_sheet_viewer_screen.dart:75-127</a><br/>Watch for changes to that sheet's saved record"]
    E["05. <a href='../../lib/screens/music_sheet/screens/music_sheet_viewer_screen.dart#L1314' style='text-decoration:underline'>lib/screens/music_sheet/screens<br/>music_sheet_viewer_screen.dart:1314-1321</a><br/>Download the original or recognized file"]
    F["06. <a href='../../lib/screens/music_sheet/screens/music_sheet_viewer_screen.dart#L744' style='text-decoration:underline'>lib/screens/music_sheet/screens<br/>music_sheet_viewer_screen.dart:744-817</a><br/>Show the recognition button and progress messages"]
    G["07. <a href='../../lib/screens/music_sheet/widgets/music_sheet_audio_preview.dart#L13' style='text-decoration:underline'>lib/screens/music_sheet/widgets<br/>music_sheet_audio_preview.dart:13-22</a><br/>Play the sheet's saved MP3"]
    H["Show the original pictures/PDF or the recognized PDF<br/>Sheet recognition: Features 14 and 15; audio transcription: Feature 17"]
    I["08. <a href='../../lib/screens/music_sheet/screens/music_sheet_screen.dart#L478' style='text-decoration:underline'>lib/screens/music_sheet/screens<br/>music_sheet_screen.dart:478-509</a><br/>Save a new sheet name"]
    J["09. <a href='../../lib/screens/music_sheet/screens/music_sheet_screen.dart#L511' style='text-decoration:underline'>lib/screens/music_sheet/screens<br/>music_sheet_screen.dart:511-573</a><br/>Ask before deleting a sheet"]
    K["10. <a href='../../lib/screens/music_sheet/services/music_sheet_delete_service.dart#L5' style='text-decoration:underline'>lib/screens/music_sheet/services<br/>music_sheet_delete_service.dart:5-54</a><br/>Stop deletion during processing; otherwise remove its files and record"]
    L["11. <a href='../../lib/screens/music_sheet/dialogs/music_sheet_dialogs.dart#L7' style='text-decoration:underline'>lib/screens/music_sheet/dialogs<br/>music_sheet_dialogs.dart:7-19</a><br/>Show naming and deletion dialogs"]
    M["Choose Sight Reading, Synthesia or AR practice<br/>See Feature 28"]
    A --> B --> C --> D --> E --> H
    D --> F
    D --> G
    D --> M
    A -- Rename --> I
    A -- Delete --> J --> K
    I -. "Dialog" .-> L```
