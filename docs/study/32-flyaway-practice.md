# Feature 32: Flyaway practice

[Checklist](README.md) | [Previous](31-ar-practice.md) | [Next](33-lessons-and-progress.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/flyaway/screens/flyaway_screen.dart#L6' style='text-decoration:underline'>lib/screens/flyaway/screens<br/>flyaway_screen.dart:6-61</a><br/>Open finger-movement practice"]
    B["02. <a href='../../lib/screens/flyaway/screens/flyaway_practice_screen.dart#L100' style='text-decoration:underline'>lib/screens/flyaway/screens<br/>flyaway_practice_screen.dart:100-163</a><br/>Prepare the camera and hand recognition"]
    C["03. <a href='../../lib/screens/flyaway/services/flyaway_hand_tracking_service.dart#L22' style='text-decoration:underline'>lib/screens/flyaway/services<br/>flyaway_hand_tracking_service.dart:22-34</a><br/>Prepare the hand_detection package to find hands and finger points"]
    D["04. <a href='../../lib/screens/flyaway/screens/flyaway_practice_screen.dart#L220' style='text-decoration:underline'>lib/screens/flyaway/screens<br/>flyaway_practice_screen.dart:220-230</a><br/>Receive camera images and start checking them"]
    E["05. <a href='../../lib/screens/flyaway/services/flyaway_hand_tracking_service.dart#L37' style='text-decoration:underline'>lib/screens/flyaway/services<br/>flyaway_hand_tracking_service.dart:37-57</a><br/>Find up to two hands and their finger positions"]
    F["06. <a href='../../lib/screens/flyaway/controllers/flyaway_analysis_controller.dart#L9' style='text-decoration:underline'>lib/screens/flyaway/controllers<br/>flyaway_analysis_controller.dart:9-21</a><br/>Measure how far each fingertip lifts compared with its base"]
    G["07. <a href='../../lib/screens/flyaway/controllers/flyaway_practice_controller.dart#L105' style='text-decoration:underline'>lib/screens/flyaway/controllers<br/>flyaway_practice_controller.dart:105-108</a><br/>Learn the user's resting and moving finger positions"]
    H["08. <a href='../../lib/screens/flyaway/controllers/flyaway_practice_controller.dart#L158' style='text-decoration:underline'>lib/screens/flyaway/controllers<br/>flyaway_practice_controller.dart:158-172</a><br/>Start practice using those learned positions"]
    I["09. <a href='../../lib/screens/flyaway/services/flyaway_duration_tracker.dart#L2' style='text-decoration:underline'>lib/screens/flyaway/services<br/>flyaway_duration_tracker.dart:2-34</a><br/>An older helper that is not used by the current practice flow"]
    J["10. <a href='../../lib/screens/flyaway/painters/hand_landmark_painter.dart#L9' style='text-decoration:underline'>lib/screens/flyaway/painters<br/>hand_landmark_painter.dart:9-75</a><br/>Draw the detected hands and movement feedback"]
    K["11. <a href='../../lib/screens/flyaway/controllers/flyaway_practice_controller.dart#L174' style='text-decoration:underline'>lib/screens/flyaway/controllers<br/>flyaway_practice_controller.dart:174-207</a><br/>Count the finger-lift events and how long they lasted"]
    L["12. <a href='../../lib/screens/flyaway/screens/flyaway_practice_screen.dart#L369' style='text-decoration:underline'>lib/screens/flyaway/screens<br/>flyaway_practice_screen.dart:369-426</a><br/>Show the session summary on this phone"]
    M["13. <a href='../../lib/screens/flyaway/screens/flyaway_practice_screen.dart#L196' style='text-decoration:underline'>lib/screens/flyaway/screens<br/>flyaway_practice_screen.dart:196-218</a><br/>Close the camera and hand detector and stop timers when leaving"]
    N["The phone checks the camera images itself<br/>This practice does not send a processing job to Python"]
    A --> B --> C --> D --> E --> F --> G --> H
    F -. "Show feedback over the camera" .-> J
    H --> K --> L
    H -. "Older helper, not used here" .-> I
    D -- "Next frame" --> E
    L -- "Exit / background" --> M
    C -. "Runs on this phone" .-> N```
