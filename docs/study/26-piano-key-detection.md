# Feature 26: Finding piano keys with the camera

[Checklist](README.md) | [Previous](25-midi-connection.md) | [Next](27-piano-key-mapping-and-saving.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/players/ar/screens/ar_practice_screen.dart#L822' style='text-decoration:underline'>lib/screens/players/ar/screens<br/>ar_practice_screen.dart:822-878</a><br/>Choose New Piano Setup"]
    B["02. <a href='../../lib/screens/piano_calibration/screens/piano_calibration_screen.dart#L1718' style='text-decoration:underline'>lib/screens/piano_calibration/screens<br/>piano_calibration_screen.dart:1718-1775</a><br/>Open the phone camera"]
    C["03. <a href='../../lib/screens/piano_calibration/screens/piano_calibration_screen.dart#L1513' style='text-decoration:underline'>lib/screens/piano_calibration/screens<br/>piano_calibration_screen.dart:1513-1633</a><br/>Send each camera image for checking"]
    D["04. <a href='../../lib/screens/piano_calibration/services/piano_keyboard_detector.dart#L62' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>piano_keyboard_detector.dart:62-239</a><br/>Look for a piano keyboard on the phone"]
    E["05. <a href='../../lib/screens/piano_calibration/services/camera_image_converter.dart#L10' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>camera_image_converter.dart:10-69</a><br/>Turn the camera image into shades of gray"]
    F["06. <a href='../../lib/screens/piano_calibration/services/keyboard_image_preprocessor.dart#L4' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>keyboard_image_preprocessor.dart:4-81</a><br/>Make the dark parts easier to find"]
    G["07. <a href='../../lib/screens/piano_calibration/services/keyboard_search_band_masker.dart#L6' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>keyboard_search_band_masker.dart:6-54</a><br/>Look through likely keyboard areas in the image"]
    H["08. <a href='../../lib/screens/piano_calibration/services/black_key_candidate_finder.dart#L6' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>black_key_candidate_finder.dart:6-90</a><br/>Find shapes that could be black piano keys"]
    I["09. <a href='../../lib/screens/piano_calibration/services/black_key_pattern_analyzer.dart#L8' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>black_key_pattern_analyzer.dart:8-489</a><br/>Look for the repeated groups of two and three black keys"]
    J["10. <a href='../../lib/screens/piano_calibration/services/piano_detection_stabilizer.dart#L7' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>piano_detection_stabilizer.dart:7-139</a><br/>Wait until the keyboard is found consistently across images"]
    K["11. <a href='../../lib/screens/piano_calibration/services/keyboard_area_estimator.dart#L7' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>keyboard_area_estimator.dart:7-179</a><br/>Estimate the keyboard's four corners"]
    L["12. <a href='../../lib/screens/piano_calibration/widgets/keyboard_area_overlay.dart#L13' style='text-decoration:underline'>lib/screens/piano_calibration/widgets<br/>keyboard_area_overlay.dart:13-50</a><br/>Show an outline the user can adjust"]
    A --> B --> C --> D --> E --> F --> G --> H --> I --> J --> K --> L
    J -- "Unstable; next frame" --> C```
