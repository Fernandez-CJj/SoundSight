# Feature 31: AR practice

[Checklist](README.md) | [Previous](30-synthesia.md) | [Next](32-flyaway-practice.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/players/ar/screens/ar_practice_screen.dart#L759' style='text-decoration:underline'>lib/screens/players/ar/screens<br/>ar_practice_screen.dart:759-819</a><br/>Choose a saved piano setup or create a new one"]
    B["02. <a href='../../lib/screens/piano_calibration/services/piano_calibration_firestore_service.dart#L58' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>piano_calibration_firestore_service.dart:58-112</a><br/>Read the saved key positions; see Feature 27"]
    C["03. <a href='../../lib/screens/piano_calibration/screens/piano_calibration_screen.dart#L1639' style='text-decoration:underline'>lib/screens/piano_calibration/screens<br/>piano_calibration_screen.dart:1639-1712</a><br/>Fit the saved key positions to the camera and open practice"]
    D["04. <a href='../../lib/screens/players/ar/services/ar_score_timeline_loader.dart#L33' style='text-decoration:underline'>lib/screens/players/ar/services<br/>ar_score_timeline_loader.dart:33-131</a><br/>Load this song's MIDI file"]
    E["05. <a href='../../lib/screens/players/ar/services/midi_timeline_parser.dart#L11' style='text-decoration:underline'>lib/screens/players/ar/services<br/>midi_timeline_parser.dart:11-415</a><br/>Read the notes and when they should be played"]
    F["06. <a href='../../lib/screens/players/ar/widgets/ar_falling_notes_overlay.dart#L14' style='text-decoration:underline'>lib/screens/players/ar/widgets<br/>ar_falling_notes_overlay.dart:14-87</a><br/>Draw falling notes over the real piano keys"]
    G["07. <a href='../../lib/screens/players/ar/services/ar_practice_performance_tracker.dart#L69' style='text-decoration:underline'>lib/screens/players/ar/services<br/>ar_practice_performance_tracker.dart:69-851</a><br/>Check the piano notes played against the song"]
    H["08. <a href='../../lib/screens/piano_calibration/screens/piano_calibration_screen.dart#L4119' style='text-decoration:underline'>lib/screens/piano_calibration/screens<br/>piano_calibration_screen.dart:4119-4371</a><br/>Show completion, Retry and View Results choices"]
    I["09. <a href='../../lib/screens/practice_result/services/practice_result_service.dart#L60' style='text-decoration:underline'>lib/screens/practice_result/services<br/>practice_result_service.dart:60-126</a><br/>Save the completed performance"]
    A --> B --> D --> E --> C --> F
    F -- "Read the connected piano" --> G --> H
    H -- "Playing results" --> I```
