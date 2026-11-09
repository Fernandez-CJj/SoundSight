# Feature 33: Lessons and progress

[Checklist](README.md) | [Previous](32-flyaway-practice.md) | [Next](34-practice-results.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/lessons/screens/fundamentals_screen.dart#L59' style='text-decoration:underline'>lib/screens/lessons/screens<br/>fundamentals_screen.dart:59-88</a><br/>Load the user's unlocked lesson and skill level"]
    B["02. <a href='../../lib/screens/lessons/data/practice_stages.dart#L4' style='text-decoration:underline'>lib/screens/lessons/data<br/>practice_stages.dart:4-177</a><br/>List the lessons and their included files"]
    C["03. <a href='../../lib/screens/lessons/models/practice_stage.dart#L4' style='text-decoration:underline'>lib/screens/lessons/models<br/>practice_stage.dart:4-20</a><br/>Describe each lesson and its activity"]
    D["04. <a href='../../lib/screens/lessons/screens/fundamentals_screen.dart#L456' style='text-decoration:underline'>lib/screens/lessons/screens<br/>fundamentals_screen.dart:456-658</a><br/>Check whether the lesson is unlocked and show its introduction"]
    E["05. <a href='../../lib/screens/lessons/screens/practice_content.dart#L15' style='text-decoration:underline'>lib/screens/lessons/screens<br/>practice_content.dart:15-139</a><br/>Open the activity matching the lesson files"]
    F{"Is this a video lesson with a quiz, or a piano challenge?"}
    G["06. <a href='../../lib/screens/lessons/screens/video_lesson_screen.dart#L10' style='text-decoration:underline'>lib/screens/lessons/screens<br/>video_lesson_screen.dart:10-32</a><br/>Play the lesson video and pause it before the quiz or PDF"]
    H["07. <a href='../../lib/screens/lessons/screens/practice_content.dart#L704' style='text-decoration:underline'>lib/screens/lessons/screens<br/>practice_content.dart:704-716</a><br/>Collect quiz answers and return whether the user passed"]
    I["08. <a href='../../lib/screens/players/sight_reading/screens/music_sheet_reading_screen.dart#L3023' style='text-decoration:underline'>lib/screens/players/sight_reading/screens<br/>music_sheet_reading_screen.dart:3023-3048</a><br/>Run the lesson's piano challenge and return whether it was passed"]
    J{"Did the user pass the current unlocked lesson?"}
    K["09. <a href='../../lib/screens/lessons/screens/fundamentals_screen.dart#L684' style='text-decoration:underline'>lib/screens/lessons/screens<br/>fundamentals_screen.dart:684-724</a><br/>Save the completed lesson and offer Retry if saving fails"]
    L["10. <a href='../../lib/screens/lessons/services/practice_progress_service.dart#L29' style='text-decoration:underline'>lib/screens/lessons/services<br/>practice_progress_service.dart:29-66</a><br/>Unlock the next lesson, add 50 XP and award a milestone badge when earned"]
    M["11. <a href='../../lib/screens/lessons/localization/lesson_localization.dart#L49' style='text-decoration:underline'>lib/screens/lessons/localization<br/>lesson_localization.dart:49-71</a><br/>Show lesson titles and instructions in the chosen language"]
    N["Save lesson level and XP in users/UID<br/>Completing stage 9 can promote to Intermediate; stage 16 to Advanced<br/>Replaying completed lessons does not repeatedly award completion XP"]
    O["Retry the activity or replay without unlocking another lesson"]
    A --> B --> D --> E --> F
    B -. "Saved details used by this feature" .-> C
    D -. "Localized labels" .-> M
    F -- "Video + quiz" --> G --> H --> J
    F -- "MIDI + MusicXML" --> I --> J
    J -- Yes --> K --> L --> N
    J -- No --> O
    N --> A```
