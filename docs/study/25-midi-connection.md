# Feature 25: MIDI connection

[Checklist](README.md) | [Previous](24-community-compositions-and-playback.md) | [Next](26-piano-key-detection.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/midi/screens/note_input_screen.dart#L5' style='text-decoration:underline'>lib/screens/midi/screens<br/>note_input_screen.dart:5-10</a><br/>Open the piano note-input feature"]
    B["02. <a href='../../lib/screens/midi/screens/midi_note_identifier_screen.dart#L9' style='text-decoration:underline'>lib/screens/midi/screens<br/>midi_note_identifier_screen.dart:9-15</a><br/>Show connected-piano choices and the notes being played"]
    C["03. <a href='../../lib/screens/midi/services/midi_input_service.dart#L56' style='text-decoration:underline'>lib/screens/midi/services<br/>midi_input_service.dart:56-58</a><br/>Ask the MIDI package for available piano devices"]
    D["04. <a href='../../lib/screens/midi/services/midi_input_service.dart#L60' style='text-decoration:underline'>lib/screens/midi/services<br/>midi_input_service.dart:60-106</a><br/>Connect to the chosen piano and start receiving updates"]
    E["The physical piano sends key-press and key-release messages"]
    F["05. <a href='../../lib/screens/midi/services/midi_input_service.dart#L133' style='text-decoration:underline'>lib/screens/midi/services<br/>midi_input_service.dart:133-180</a><br/>Read the played notes and remember which keys are held"]
    G["06. <a href='../../lib/screens/midi/models/midi_note_event.dart#L3' style='text-decoration:underline'>lib/screens/midi/models<br/>midi_note_event.dart:3-13</a><br/>Keep the note, time, strength and whether it was pressed or released"]
    H["07. <a href='../../lib/screens/midi/utils/midi_note_converter.dart#L3' style='text-decoration:underline'>lib/screens/midi/utils<br/>midi_note_converter.dart:3-8</a><br/>Turn the note number into a name such as C4"]
    I["Send played notes, held notes and connection updates to the screens"]
    J["08. <a href='../../lib/screens/midi/services/midi_input_service.dart#L238' style='text-decoration:underline'>lib/screens/midi/services<br/>midi_input_service.dart:238-247</a><br/>Clear held notes and tell the screen when the piano disconnects"]
    K["09. <a href='../../lib/screens/midi/services/midi_input_service.dart#L256' style='text-decoration:underline'>lib/screens/midi/services<br/>midi_input_service.dart:256-278</a><br/>Stop listening and disconnect when the service closes"]
    L["Used by assessment, composition and practice players<br/>Also helps identify Middle C during piano setup"]
    A --> B --> C --> D --> E --> F --> G --> I --> L
    F --> H --> B
    D -- "Device removed" --> J --> I
    B -- "Screen disposed" --> K```
