# Feature 13: Saving uploaded sheets

[Checklist](README.md) | [Previous](12-sheet-selection-and-preview.md) | [Next](14-sheet-recognition-requests.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/capture_upload_sheet/widgets/save_sheet_container.dart#L41' style='text-decoration:underline'>lib/screens/capture_upload_sheet/widgets<br/>save_sheet_container.dart:41-41</a><br/>Run the Save action when the button is tapped"]
    B["02. <a href='../../lib/screens/capture_upload_sheet/screens/capture_upload_sheet_screen.dart#L411' style='text-decoration:underline'>lib/screens/capture_upload_sheet/screens<br/>capture_upload_sheet_screen.dart:411-487</a><br/>Check sign-in and ask for the sheet name"]
    C["03. <a href='../../lib/screens/capture_upload_sheet/dialogs/capture_upload_dialogs.dart#L264' style='text-decoration:underline'>lib/screens/capture_upload_sheet/dialogs<br/>capture_upload_dialogs.dart:264-267</a><br/>Require a name, then return it to the upload screen"]
    D["04. <a href='../../lib/screens/capture_upload_sheet/services/music_sheet_upload_service.dart#L13' style='text-decoration:underline'>lib/screens/capture_upload_sheet/services<br/>music_sheet_upload_service.dart:13-129</a><br/>Recheck the files and choose an ID for the new sheet"]
    E["05. <a href='../../lib/screens/capture_upload_sheet/services/music_sheet_upload_service.dart#L51' style='text-decoration:underline'>lib/screens/capture_upload_sheet/services<br/>music_sheet_upload_service.dart:51-61</a><br/>Upload the PDF or pictures in page order"]
    F["06. <a href='../../lib/screens/capture_upload_sheet/services/music_sheet_upload_service.dart#L63' style='text-decoration:underline'>lib/screens/capture_upload_sheet/services<br/>music_sheet_upload_service.dart:63-69</a><br/>Update how much of the upload is finished"]
    G["07. <a href='../../lib/screens/capture_upload_sheet/services/music_sheet_upload_service.dart#L99' style='text-decoration:underline'>lib/screens/capture_upload_sheet/services<br/>music_sheet_upload_service.dart:99-110</a><br/>Save the sheet record and award the first-upload badge if needed"]
    H["08. <a href='../../lib/screens/capture_upload_sheet/screens/capture_upload_sheet_screen.dart#L471' style='text-decoration:underline'>lib/screens/capture_upload_sheet/screens<br/>capture_upload_sheet_screen.dart:471-471</a><br/>Show success, clear selected files and close the upload screen"]
    I["09. <a href='../../lib/screens/homescreen/screens/home_screen.dart#L307' style='text-decoration:underline'>lib/screens/homescreen/screens<br/>home_screen.dart:307-321</a><br/>Open the collection after the upload screen reports success"]
    J["10. <a href='../../lib/screens/capture_upload_sheet/services/music_sheet_upload_service.dart#L117' style='text-decoration:underline'>lib/screens/capture_upload_sheet/services<br/>music_sheet_upload_service.dart:117-121</a><br/>If saving fails, try removing files already uploaded"]
    K["11. <a href='../../lib/screens/capture_upload_sheet/screens/capture_upload_sheet_screen.dart#L484' style='text-decoration:underline'>lib/screens/capture_upload_sheet/screens<br/>capture_upload_sheet_screen.dart:484-484</a><br/>Show the failure and keep the selection so the user can retry"]
    A --> B --> C --> D --> E --> F --> G --> H --> I
    E -- Error --> J
    G -- Error --> J
    J --> K
    K -- Retry --> B```
