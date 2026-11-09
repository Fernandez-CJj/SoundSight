# Feature 19: Music library

[Checklist](README.md) | [Previous](18-sheet-collection-and-viewer.md) | [Next](20-manual-composition.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/music_library/screens/music_library_search_screen.dart#L51' style='text-decoration:underline'>lib/screens/music_library/screens<br/>music_library_search_screen.dart:51-100</a><br/>Load library songs a page at a time, ordered by name"]
    B["02. <a href='../../lib/screens/music_library/screens/music_library_search_screen.dart#L114' style='text-decoration:underline'>lib/screens/music_library/screens<br/>music_library_search_screen.dart:114-128</a><br/>Use the search text, or return to browsing when it is cleared"]
    C["03. <a href='../../lib/screens/music_library/screens/music_library_search_screen.dart#L318' style='text-decoration:underline'>lib/screens/music_library/screens<br/>music_library_search_screen.dart:318-340</a><br/>Sort streamed library records and filter titles in the app<br/>Every search word must appear in the title"]
    OPEN["<a href='../../lib/screens/music_library/screens/music_library_search_screen.dart#L397' style='text-decoration:underline'>lib/screens/music_library/screens/music_library_search_screen.dart:397-407</a><br/>A song-card tap opens MusicLibraryPieceScreen with its piece ID"]
    D["04. <a href='../../lib/screens/music_library/screens/music_library_piece_screen.dart#L42' style='text-decoration:underline'>lib/screens/music_library/screens<br/>music_library_piece_screen.dart:42-110</a><br/>Listen to the selected song's Firestore document and display its details<br/>Resolve saved file locations: <a href='../../lib/screens/music_library/screens/music_library_piece_screen.dart#L320' style='text-decoration:underline'>music_library_piece_screen.dart:320-325</a>"]
    E["05. <a href='../../lib/screens/music_library/screens/music_library_piece_screen.dart#L228' style='text-decoration:underline'>lib/screens/music_library/screens<br/>music_library_piece_screen.dart:228-235</a><br/>Load PDF bytes from Firebase for viewing inside the app<br/>Render the PDF: <a href='../../lib/screens/music_library/screens/music_library_piece_screen.dart#L170' style='text-decoration:underline'>music_library_piece_screen.dart:170-226</a><br/>This screen provides no Save PDF to Downloads button"]
    F["06. <a href='../../lib/screens/music_sheet/widgets/music_sheet_audio_preview.dart#L326' style='text-decoration:underline'>lib/screens/music_sheet/widgets<br/>music_sheet_audio_preview.dart:326-372</a><br/>Load and play the saved MP3 with audioplayers<br/>Library passes its MP3 location: <a href='../../lib/screens/music_library/screens/music_library_piece_screen.dart#L151' style='text-decoration:underline'>music_library_piece_screen.dart:151-164</a>"]
    G["07. <a href='../../lib/screens/music_library/screens/music_library_piece_screen.dart#L237' style='text-decoration:underline'>lib/screens/music_library/screens<br/>music_library_piece_screen.dart:237-305</a><br/>Choose a practice mode and check required file locations<br/>All modes require MIDI; Sight Reading also requires MusicXML and MP3<br/>Stop the preview before opening practice"]
    H["08. <a href='../../lib/screens/players/sight_reading/screens/music_sheet_reading_screen.dart#L54' style='text-decoration:underline'>lib/screens/players/sight_reading/screens<br/>music_sheet_reading_screen.dart:54-84</a><br/>Open Sight Reading"]
    I["09. <a href='../../lib/screens/players/synthesia/screens/synthesia_screen.dart#L34' style='text-decoration:underline'>lib/screens/players/synthesia/screens<br/>synthesia_screen.dart:34-46</a><br/>Open Synthesia"]
    J["10. <a href='../../lib/screens/players/ar/screens/ar_practice_screen.dart#L22' style='text-decoration:underline'>lib/screens/players/ar/screens<br/>ar_practice_screen.dart:22-40</a><br/>Open AR piano setup and practice"]
    K["The admin app manages songs in available_pieces/ID<br/>Their PDF, MusicXML, MIDI and MP3 files are in Storage<br/>See Feature 38"]
    K --> A
    A --> B
    B -- Search --> C --> OPEN --> D
    A -- "Open piece" --> OPEN
    D --> E
    D --> F
    D --> G
    G -- "Stop preview and open" --> H
    G -- "Stop preview and open" --> I
    G -- "Stop preview and open" --> J```
