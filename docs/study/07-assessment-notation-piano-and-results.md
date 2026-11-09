# Feature 07: Note reading, piano assessment and results

[Checklist](README.md) | [Previous](06-assessment-questionnaire.md) | [Next](08-home-and-navigation.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/assessment/screens/assessment_entry_screen.dart#L371' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_entry_screen.dart:371-413</a><br/>Open the note-reading questions"]
    B["02. <a href='../../lib/screens/assessment/screens/assessment_notation_reading_screen.dart#L19' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_notation_reading_screen.dart:19-39</a><br/>Collect the user's answers about the notes"]
    C["03. <a href='../../lib/screens/assessment/widgets/assessment_notation_view.dart#L9' style='text-decoration:underline'>lib/screens/assessment/widgets<br/>assessment_notation_view.dart:9-36</a><br/>Draw the musical notes shown in each question"]
    D["04. <a href='../../lib/screens/assessment/services/assessment_attempt_service.dart#L262' style='text-decoration:underline'>lib/screens/assessment/services<br/>assessment_attempt_service.dart:262-317</a><br/>Score the answers and remember the next section"]
    E["05. <a href='../../lib/screens/assessment/screens/assessment_piano_execution_screen.dart#L127' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_piano_execution_screen.dart:127-183</a><br/>Connect the piano and begin the playing tasks"]
    F["06. <a href='../../lib/screens/midi/services/midi_input_service.dart#L133' style='text-decoration:underline'>lib/screens/midi/services<br/>midi_input_service.dart:133-180</a><br/>Read the notes played on the connected piano"]
    G["07. <a href='../../lib/screens/assessment/services/assessment_piano_performance_tracker.dart#L98' style='text-decoration:underline'>lib/screens/assessment/services<br/>assessment_piano_performance_tracker.dart:98-160</a><br/>Check whether the right notes were played at the right time"]
    H["08. <a href='../../lib/screens/assessment/models/assessment_piano_task.dart#L56' style='text-decoration:underline'>lib/screens/assessment/models<br/>assessment_piano_task.dart:56-110</a><br/>Define the notes, speed and difficulty of each task"]
    I["09. <a href='../../lib/screens/assessment/services/assessment_attempt_service.dart#L323' style='text-decoration:underline'>lib/screens/assessment/services<br/>assessment_attempt_service.dart:323-406</a><br/>Calculate the final level and save the result, profile and badge"]
    J["Note reading needs 4 of 6 correct in each required difficulty group<br/>Piano playing needs 70% in each required group<br/>The final level is the lower of the two section levels"]
    K["10. <a href='../../lib/screens/assessment/screens/assessment_results_screen.dart#L46' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_results_screen.dart:46-68</a><br/>Show the results and finish the review"]
    L["11. <a href='../../lib/screens/assessment/services/assessment_attempt_service.dart#L413' style='text-decoration:underline'>lib/screens/assessment/services<br/>assessment_attempt_service.dart:413-434</a><br/>Apply the earned level without lowering a higher existing level"]
    M["12. <a href='../../lib/screens/assessment/screens/assessment_entry_screen.dart#L649' style='text-decoration:underline'>lib/screens/assessment/screens<br/>assessment_entry_screen.dart:649-656</a><br/>Return to the previous screen or open Home"]
    A --> B --> D --> E
    B -. "Show the notes in the question" .-> C
    E --> F --> G --> I --> K --> L --> M
    E -. "Read the piano task instructions" .-> H
    I -. "Scoring rule" .-> J```
