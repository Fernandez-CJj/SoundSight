# Feature 21: Recorded composition

[Checklist](README.md) | [Previous](20-manual-composition.md) | [Next](22-composition-file-generation.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/composition/screens/new_composition_screen.dart#L15' style='text-decoration:underline'>lib/screens/composition/screens<br/>new_composition_screen.dart:15-22</a><br/>Choose recording and enter the song settings"]
    B["02. <a href='../../lib/screens/composition/models/recording_composition_draft.dart#L1' style='text-decoration:underline'>lib/screens/composition/models<br/>recording_composition_draft.dart:1-15</a><br/>Pass those settings to the recording screen"]
    C["03. <a href='../../lib/screens/composition/screens/record_composition_screen.dart#L125' style='text-decoration:underline'>lib/screens/composition/screens<br/>record_composition_screen.dart:125-184</a><br/>Prepare the camera preview and video recording"]
    D["04. <a href='../../lib/screens/composition/screens/record_composition_screen.dart#L197' style='text-decoration:underline'>lib/screens/composition/screens<br/>record_composition_screen.dart:197-228</a><br/>Connect the piano before starting"]
    E["05. <a href='../../lib/screens/composition/screens/record_composition_screen.dart#L304' style='text-decoration:underline'>lib/screens/composition/screens<br/>record_composition_screen.dart:304-338</a><br/>Start recording video and the timing of played piano notes"]
    F["06. <a href='../../lib/screens/midi/services/midi_input_service.dart#L133' style='text-decoration:underline'>lib/screens/midi/services<br/>midi_input_service.dart:133-180</a><br/>Read when each piano key is pressed or released and how strongly"]
    G["07. <a href='../../lib/screens/composition/screens/record_composition_screen.dart#L258' style='text-decoration:underline'>lib/screens/composition/screens<br/>record_composition_screen.dart:258-302</a><br/>Remember those piano actions using the recording clock"]
    H["08. <a href='../../lib/screens/composition/screens/record_composition_screen.dart#L371' style='text-decoration:underline'>lib/screens/composition/screens<br/>record_composition_screen.dart:371-446</a><br/>Stop recording, finish held notes and prepare the captured notes"]
    I["09. <a href='../../lib/screens/composition/services/recorded_performance_processor.dart#L76' style='text-decoration:underline'>lib/screens/composition/services<br/>recorded_performance_processor.dart:76-122</a><br/>Turn key presses and releases into notes, keeping their timing"]
    J["10. <a href='../../lib/screens/composition/services/recorded_performance_timing.dart#L5' style='text-decoration:underline'>lib/screens/composition/services<br/>recorded_performance_timing.dart:5-55</a><br/>Help calculate timing and group notes played together"]
    K["11. <a href='../../lib/screens/composition/dialogs/recording/recording_completion_dialog.dart#L10' style='text-decoration:underline'>lib/screens/composition/dialogs/recording<br/>recording_completion_dialog.dart:10-33</a><br/>Ask what to do with the finished recording"]
    L["12. <a href='../../lib/screens/composition/screens/record_composition_screen.dart#L543' style='text-decoration:underline'>lib/screens/composition/screens<br/>record_composition_screen.dart:543-552</a><br/>Choose a saved-song ID and save this recording only once"]
    M["13. <a href='../../lib/screens/composition/services/composition_service.dart#L64' style='text-decoration:underline'>lib/screens/composition/services<br/>composition_service.dart:64-96</a><br/>Save the played notes and their timing in Firestore"]
    N["14. <a href='../../lib/screens/composition/screens/record_composition_screen.dart#L554' style='text-decoration:underline'>lib/screens/composition/screens<br/>record_composition_screen.dart:554-587</a><br/>Request the music files, then remove the temporary video"]
    O["15. <a href='../../lib/screens/composition/services/composition_generation_service.dart#L4' style='text-decoration:underline'>lib/screens/composition/services<br/>composition_generation_service.dart:4-9</a><br/>Wait for the backend to create the score and audio; see Feature 22"]
    P["The song is saved as piano notes with timing<br/>The camera video is temporary; the music files come from the notes"]
    A --> B --> C --> D --> E --> F --> G --> H --> I --> K
    I -. "Work out when notes were played" .-> J
    K -- Generate --> N --> L --> M --> O
    N -. "Temporary camera file" .-> P```
