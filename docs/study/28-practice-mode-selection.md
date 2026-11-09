# Feature 28: Choosing a practice mode

[Checklist](README.md) | [Previous](27-piano-key-mapping-and-saving.md) | [Next](29-sight-reading.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/music_sheet/screens/music_sheet_viewer_screen.dart#L26' style='text-decoration:underline'>lib/screens/music_sheet/screens<br/>music_sheet_viewer_screen.dart:26-46</a><br/>Start practice from a converted sheet"]
    B["02. <a href='../../lib/screens/music_library/screens/music_library_piece_screen.dart#L237' style='text-decoration:underline'>lib/screens/music_library/screens<br/>music_library_piece_screen.dart:237-305</a><br/>Start practice from a library song"]
    C["03. <a href='../../lib/screens/composition/screens/composition_details_screen.dart#L247' style='text-decoration:underline'>lib/screens/composition/screens<br/>composition_details_screen.dart:247-331</a><br/>Start practice from a private composition"]
    D["04. <a href='../../lib/screens/composition/screens/published_composition_viewer_screen.dart#L21' style='text-decoration:underline'>lib/screens/composition/screens<br/>published_composition_viewer_screen.dart:21-34</a><br/>Start practice from a shared composition"]
    E{"How does the user want to practice?"}
    F["05. <a href='../../lib/screens/players/sight_reading/screens/music_sheet_reading_screen.dart#L54' style='text-decoration:underline'>lib/screens/players/sight_reading/screens<br/>music_sheet_reading_screen.dart:54-84</a><br/>Open Sight Reading to follow the written notes"]
    G["06. <a href='../../lib/screens/players/synthesia/screens/synthesia_screen.dart#L34' style='text-decoration:underline'>lib/screens/players/synthesia/screens<br/>synthesia_screen.dart:34-46</a><br/>Open Synthesia to follow falling notes"]
    H["07. <a href='../../lib/screens/players/ar/screens/ar_practice_screen.dart#L22' style='text-decoration:underline'>lib/screens/players/ar/screens<br/>ar_practice_screen.dart:22-40</a><br/>Open AR and choose a saved or new piano setup"]
    I["08. <a href='../../lib/screens/midi/services/midi_input_service.dart#L60' style='text-decoration:underline'>lib/screens/midi/services<br/>midi_input_service.dart:60-106</a><br/>Read the notes played on the connected piano"]
    J["09. <a href='../../lib/screens/practice_result/services/practice_result_service.dart#L60' style='text-decoration:underline'>lib/screens/practice_result/services<br/>practice_result_service.dart:60-126</a><br/>Save the finished playing results; see Feature 34"]
    A --> E
    B --> E
    C --> E
    D --> E
    E -- "Sight Reading" --> F
    E -- Synthesia --> G
    E -- AR --> H
    I -. "Notes played on the piano" .-> F
    I -. "Notes played on the piano" .-> G
    I -. "Notes played on the piano" .-> H
    F -. "Finished playing" .-> J
    G -. "Finished playing" .-> J
    H -. "Finished playing" .-> J```
