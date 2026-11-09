# Feature 30: Synthesia

[Checklist](README.md) | [Previous](29-sight-reading.md) | [Next](31-ar-practice.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/players/synthesia/screens/synthesia_screen.dart#L369' style='text-decoration:underline'>lib/screens/players/synthesia/screens<br/>synthesia_screen.dart:369-408</a><br/>Load the chosen song"]
    B["02. <a href='../../lib/screens/players/synthesia/services/synthesia_score_loader.dart#L36' style='text-decoration:underline'>lib/screens/players/synthesia/services<br/>synthesia_score_loader.dart:36-54</a><br/>Turn saved notes or MIDI into a sequence with timing"]
    C["03. <a href='../../lib/screens/players/ar/services/midi_timeline_parser.dart#L11' style='text-decoration:underline'>lib/screens/players/ar/services<br/>midi_timeline_parser.dart:11-415</a><br/>Read the notes, lengths and speed from MIDI"]
    D["04. <a href='../../lib/screens/players/synthesia/widgets/synthesia_falling_notes.dart#L11' style='text-decoration:underline'>lib/screens/players/synthesia/widgets<br/>synthesia_falling_notes.dart:11-59</a><br/>Draw falling notes in time with the song"]
    E["05. <a href='../../lib/screens/players/synthesia/widgets/synthesia_keyboard.dart#L5' style='text-decoration:underline'>lib/screens/players/synthesia/widgets<br/>synthesia_keyboard.dart:5-34</a><br/>Draw the on-screen piano and playing feedback"]
    F["06. <a href='../../lib/screens/players/synthesia/services/synthesia_wait_mode_engine.dart#L53' style='text-decoration:underline'>lib/screens/players/synthesia/services<br/>synthesia_wait_mode_engine.dart:53-492</a><br/>In Wait mode, check notes and holds and handle retries"]
    G["07. <a href='../../lib/screens/players/synthesia/services/synthesia_performance_report_builder.dart#L5' style='text-decoration:underline'>lib/screens/players/synthesia/services<br/>synthesia_performance_report_builder.dart:5-183</a><br/>Prepare the results of a timed performance"]
    H["08. <a href='../../lib/screens/players/services/score_audio_playback_service.dart#L13' style='text-decoration:underline'>lib/screens/players/services<br/>score_audio_playback_service.dart:13-87</a><br/>Play the song's saved audio preview"]
    I["09. <a href='../../lib/screens/practice_result/services/practice_result_service.dart#L60' style='text-decoration:underline'>lib/screens/practice_result/services<br/>practice_result_service.dart:60-126</a><br/>Save the results and let the user review them"]
    A --> B --> D --> E
    B -. "Read the saved piano notes" .-> C
    D -- "Wait for the right piano notes" --> F
    D -- "Check piano playing against time" --> G --> I
    A -- "Audio preview" --> H```
