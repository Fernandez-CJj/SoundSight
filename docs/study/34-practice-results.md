# Feature 34: Practice results

[Checklist](README.md) | [Previous](33-lessons-and-progress.md) | [Next](35-achievements-and-badges.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/players/sight_reading/services/sight_reading_performance_tracker.dart#L6' style='text-decoration:underline'>lib/screens/players/sight_reading/services<br/>sight_reading_performance_tracker.dart:6-710</a><br/>Check the notes and timing during Sight Reading"]
    B["02. <a href='../../lib/screens/players/synthesia/services/synthesia_performance_report_builder.dart#L5' style='text-decoration:underline'>lib/screens/players/synthesia/services<br/>synthesia_performance_report_builder.dart:5-183</a><br/>Prepare the Synthesia playing results"]
    C["03. <a href='../../lib/screens/players/ar/services/ar_practice_performance_tracker.dart#L69' style='text-decoration:underline'>lib/screens/players/ar/services<br/>ar_practice_performance_tracker.dart:69-851</a><br/>Prepare results from playing with AR"]
    D["04. <a href='../../lib/screens/practice_result/models/practice_result_models.dart#L242' style='text-decoration:underline'>lib/screens/practice_result/models<br/>practice_result_models.dart:242-394</a><br/>Keep the overall score, detailed counts and mistakes together"]
    E["05. <a href='../../lib/screens/practice_result/services/practice_result_service.dart#L60' style='text-decoration:underline'>lib/screens/practice_result/services<br/>practice_result_service.dart:60-126</a><br/>Check sign-in, then save the score and mistake details"]
    F["Save in users/UID/practice_results/ID<br/>Mistakes go in its error_events collection<br/>Remember whether saving is still in progress or complete"]
    G["06. <a href='../../lib/screens/practice_result/screens/practice_results_screen.dart#L34' style='text-decoration:underline'>lib/screens/practice_result/screens<br/>practice_results_screen.dart:34-41</a><br/>Show past results with filters and sorting"]
    H["07. <a href='../../lib/screens/practice_result/services/practice_result_service.dart#L22' style='text-decoration:underline'>lib/screens/practice_result/services<br/>practice_result_service.dart:22-37</a><br/>Keep the results list up to date"]
    I["08. <a href='../../lib/screens/practice_result/screens/practice_result_detail_screen.dart#L13' style='text-decoration:underline'>lib/screens/practice_result/screens<br/>practice_result_detail_screen.dart:13-758</a><br/>Show the score, note and clef details, mistakes and practice tips"]
    J["09. <a href='../../lib/screens/practice_result/services/practice_result_service.dart#L39' style='text-decoration:underline'>lib/screens/practice_result/services<br/>practice_result_service.dart:39-58</a><br/>Load the mistakes for the selected result"]
    K["10. <a href='../../lib/screens/practice_result/services/practice_result_service.dart#L128' style='text-decoration:underline'>lib/screens/practice_result/services<br/>practice_result_service.dart:128-138</a><br/>Delete the result and its saved mistake details"]
    A --> D
    B --> D
    C --> D
    D --> E --> F --> H --> G --> I --> J
    G -- Delete --> K```
