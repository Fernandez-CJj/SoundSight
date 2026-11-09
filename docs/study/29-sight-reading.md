# Feature 29: Sight Reading

[Checklist](README.md) | [Previous](28-practice-mode-selection.md) | [Next](30-synthesia.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/players/sight_reading/screens/music_sheet_reading_screen.dart#L428' style='text-decoration:underline'>lib/screens/players/sight_reading/screens<br/>music_sheet_reading_screen.dart:428-436</a><br/>Load the song from saved files, a composition or a lesson"]
    B["02. <a href='../../lib/screens/players/sight_reading/widgets/music_sheet_web_view.dart#L9' style='text-decoration:underline'>lib/screens/players/sight_reading/widgets<br/>music_sheet_web_view.dart:9-171</a><br/>Show and control the score inside the app's built-in browser"]
    C["03. <a href='../../lib/screens/players/sight_reading/utils/music_sheet_html.dart#L12' style='text-decoration:underline'>lib/screens/players/sight_reading/utils<br/>music_sheet_html.dart:12-1416</a><br/>Use OpenSheetMusicDisplay to draw the musical notation"]
    D["04. <a href='../../lib/screens/players/sight_reading/services/sight_reading_performance_tracker.dart#L6' style='text-decoration:underline'>lib/screens/players/sight_reading/services<br/>sight_reading_performance_tracker.dart:6-710</a><br/>Check which notes were played, when they started and how long they were held"]
    E["05. <a href='../../lib/screens/players/sight_reading/services/sight_reading_note_matcher.dart#L1' style='text-decoration:underline'>lib/screens/players/sight_reading/services<br/>sight_reading_note_matcher.dart:1-248</a><br/>Help compare played notes with the notes expected by the score"]
    F["06. <a href='../../lib/screens/players/sight_reading/services/sight_reading_progress_service.dart#L22' style='text-decoration:underline'>lib/screens/players/sight_reading/services<br/>sight_reading_progress_service.dart:22-22</a><br/>For an eligible perfect challenge, record completion and award 20 XP once"]
    G["07. <a href='../../lib/screens/midi/services/midi_input_service.dart#L133' style='text-decoration:underline'>lib/screens/midi/services<br/>midi_input_service.dart:133-180</a><br/>Receive key presses and releases from the connected piano"]
    H["08. <a href='../../lib/screens/practice_result/services/practice_result_service.dart#L60' style='text-decoration:underline'>lib/screens/practice_result/services<br/>practice_result_service.dart:60-126</a><br/>Save the completed performance and its mistakes"]
    I["Wait mode waits for the right notes and holds<br/>Performance mode checks playing against the clock and gives results<br/>Listening to a preview does not count as completing a performance"]
    A --> B --> C
    C -. "Notes and positions from the sheet" .-> D
    D -. "Compare with expected notes" .-> E
    G --> D
    D --> I
    I -- "Finished playing" --> H
    I -. "Eligible challenge played perfectly" .-> F```
