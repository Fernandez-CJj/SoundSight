# Feature 22: Composition file generation

[Checklist](README.md) | [Previous](21-recorded-composition.md) | [Next](23-composition-publishing.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/composition/services/composition_generation_service.dart#L4' style='text-decoration:underline'>lib/screens/composition/services<br/>composition_generation_service.dart:4-9</a><br/>Request score and audio files for this saved composition"]
    B["02. <a href='../../lib/services/processing_job_service.dart#L85' style='text-decoration:underline'>lib/services<br/>processing_job_service.dart:85-110</a><br/>Identify the user and follow the accepted request"]
    C["03. <a href='../../backend/jobs/routes.py#L73' style='text-decoration:underline'>backend/jobs<br/>routes.py:73-75</a><br/>Check the request before accepting the job"]
    D["04. <a href='../../backend/composition/repositories/private_composition_repository.py#L58' style='text-decoration:underline'>backend/composition/repositories<br/>private_composition_repository.py:58-108</a><br/>Check that the song belongs to this user and its saved notes are valid"]
    E["05. <a href='../../backend/jobs/repositories/store.py#L99' style='text-decoration:underline'>backend/jobs/repositories<br/>store.py:99-123</a><br/>Reserve a place in the processing waiting list"]
    F["06. <a href='../../backend/jobs/worker.py#L78' style='text-decoration:underline'>backend/jobs<br/>worker.py:78-188</a><br/>Take the job and start the processing program"]
    G["07. <a href='../../backend/composition/services/job_processor.py#L4' style='text-decoration:underline'>backend/composition/services<br/>job_processor.py:4-21</a><br/>Load the composition, create its files and return their locations"]
    H["08. <a href='../../backend/composition/services/generation_service.py#L14' style='text-decoration:underline'>backend/composition/services<br/>generation_service.py:14-77</a><br/>Prepare the score in a temporary folder"]
    I["09. <a href='../../backend/composition/processing/score_builder.py#L17' style='text-decoration:underline'>backend/composition/processing<br/>score_builder.py:17-128</a><br/>Use music21 to build the piano score and song settings"]
    J["10. <a href='../../backend/composition/processing/music_writer.py#L267' style='text-decoration:underline'>backend/composition/processing<br/>music_writer.py:267-315</a><br/>Arrange manually entered notes into readable measures"]
    K["11. <a href='../../backend/composition/processing/performance_music_writer.py#L267' style='text-decoration:underline'>backend/composition/processing<br/>performance_music_writer.py:267-326</a><br/>Arrange recorded notes and their timing into sheet music"]
    L["12. <a href='../../backend/composition/processing/file_exporter.py#L5' style='text-decoration:underline'>backend/composition/processing<br/>file_exporter.py:5-24</a><br/>Save the MusicXML score file"]
    M["13. <a href='../../backend/core/integrations/musescore_service.py#L42' style='text-decoration:underline'>backend/core/integrations<br/>musescore_service.py:42-95</a><br/>Ask MuseScore to create a PDF"]
    N["14. <a href='../../backend/composition/processing/performance_midi_writer.py#L216' style='text-decoration:underline'>backend/composition/processing<br/>performance_midi_writer.py:216-322</a><br/>Create MIDI from the manual notes or recorded performance"]
    O["15. <a href='../../backend/core/integrations/musescore_service.py#L171' style='text-decoration:underline'>backend/core/integrations<br/>musescore_service.py:171-241</a><br/>Turn MIDI into MP3 and match the intended song length"]
    P["16. <a href='../../backend/composition/repositories/composition_storage_repository.py#L123' style='text-decoration:underline'>backend/composition/repositories<br/>composition_storage_repository.py:123-234</a><br/>Upload the PDF, MusicXML, MIDI and MP3 files"]
    Q["17. <a href='../../backend/jobs/repositories/firebase_bridge.py#L120' style='text-decoration:underline'>backend/jobs/repositories<br/>firebase_bridge.py:120-149</a><br/>Save file links and the result, then allow the song to be edited again"]
    R["18. <a href='../../lib/screens/composition/screens/composition_details_screen.dart#L29' style='text-decoration:underline'>lib/screens/composition/screens<br/>composition_details_screen.dart:29-42</a><br/>Show the created score, audio and practice choices"]
    S{"Was the song entered manually or recorded?"}
    A --> B --> C --> D --> E --> F --> G --> H --> I --> S
    S -- Manual --> J --> L
    S -- Recorded --> K --> L
    L --> M --> N --> O --> P --> Q --> R```
