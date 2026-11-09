# Feature 27: Matching notes to keys and saving the piano setup

[Checklist](README.md) | [Previous](26-piano-key-detection.md) | [Next](28-practice-mode-selection.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/piano_calibration/screens/piano_calibration_screen.dart#L2093' style='text-decoration:underline'>lib/screens/piano_calibration/screens<br/>piano_calibration_screen.dart:2093-2113</a><br/>Confirm the area that contains the piano keys"]
    B["02. <a href='../../lib/screens/piano_calibration/services/reference_key_deriver.dart#L10' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>reference_key_deriver.dart:10-198</a><br/>Find reference C-key positions"]
    C["03. <a href='../../lib/screens/piano_calibration/services/white_key_position_deriver.dart#L12' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>white_key_position_deriver.dart:12-315</a><br/>Work out where the white keys are"]
    D["04. <a href='../../lib/screens/piano_calibration/services/white_key_boundary_detector.dart#L16' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>white_key_boundary_detector.dart:16-671</a><br/>Adjust the lines between neighboring white keys"]
    E["05. <a href='../../lib/screens/piano_calibration/services/black_key_position_deriver.dart#L14' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>black_key_position_deriver.dart:14-402</a><br/>Work out where the black keys are"]
    F["06. <a href='../../lib/screens/piano_calibration/services/piano_key_region_deriver.dart#L10' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>piano_key_region_deriver.dart:10-307</a><br/>Draw the area belonging to each playable key"]
    G["07. <a href='../../lib/screens/piano_calibration/services/middle_c_guide_service.dart#L5' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>middle_c_guide_service.dart:5-70</a><br/>Use the connected piano or a manual guide to identify Middle C"]
    H["08. <a href='../../lib/screens/piano_calibration/screens/piano_calibration_screen.dart#L2137' style='text-decoration:underline'>lib/screens/piano_calibration/screens<br/>piano_calibration_screen.dart:2137-2204</a><br/>Confirm the note labels and ask for a setup name"]
    I["09. <a href='../../lib/screens/piano_calibration/services/piano_calibration_normalizer.dart#L16' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>piano_calibration_normalizer.dart:16-95</a><br/>Store positions as proportions so they can fit another image size"]
    J["10. <a href='../../lib/screens/piano_calibration/services/piano_calibration_firestore_service.dart#L119' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>piano_calibration_firestore_service.dart:119-165</a><br/>Save this piano setup in users/UID/pianoCalibrations/ID"]
    K["11. <a href='../../lib/screens/piano_calibration/services/piano_calibration_firestore_service.dart#L58' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>piano_calibration_firestore_service.dart:58-112</a><br/>Load the saved piano setup"]
    L["12. <a href='../../lib/screens/piano_calibration/services/piano_calibration_restorer.dart#L17' style='text-decoration:underline'>lib/screens/piano_calibration/services<br/>piano_calibration_restorer.dart:17-112</a><br/>Fit the saved key positions to the current camera image"]
    M["Use the saved setup in AR practice; see Feature 31<br/>Set it up again if the phone or piano moves"]
    A --> B --> C --> D --> E --> F --> H --> I --> J
    G -. "Identify which key is C" .-> B
    J -- "Open saved setup later" --> K --> L --> M```
