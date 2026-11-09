# Feature 12: Sheet selection and preview

[Checklist](README.md) | [Previous](11-appearance-language-and-logout.md) | [Next](13-sheet-upload-and-saving.md)

Click the underlined file path inside a diagram box to open the code. Line ranges show the beginning and end of the code group.

```mermaid
flowchart TD
    A["01. <a href='../../lib/screens/capture_upload_sheet/widgets/capture_upload_header.dart#L160' style='text-decoration:underline'>lib/screens/capture_upload_sheet/widgets<br/>capture_upload_header.dart:160-160</a><br/>Tap Upload PDF"]
    B["02. <a href='../../lib/screens/capture_upload_sheet/screens/capture_upload_sheet_screen.dart#L707' style='text-decoration:underline'>lib/screens/capture_upload_sheet/screens<br/>capture_upload_sheet_screen.dart:707-730</a><br/>Check that the PDF can be added with the current selection"]
    C["03. <a href='../../lib/screens/capture_upload_sheet/screens/capture_upload_sheet_screen.dart#L506' style='text-decoration:underline'>lib/screens/capture_upload_sheet/screens<br/>capture_upload_sheet_screen.dart:506-559</a><br/>Open the file picker and read the selected PDF"]
    D["04. <a href='../../lib/screens/capture_upload_sheet/screens/capture_upload_sheet_screen.dart#L561' style='text-decoration:underline'>lib/screens/capture_upload_sheet/screens<br/>capture_upload_sheet_screen.dart:561-616</a><br/>Check that it is one PDF within the size and page limits"]
    E["05. <a href='../../lib/screens/capture_upload_sheet/screens/capture_upload_sheet_screen.dart#L618' style='text-decoration:underline'>lib/screens/capture_upload_sheet/screens<br/>capture_upload_sheet_screen.dart:618-629</a><br/>Open the PDF locally and count its pages"]
    F["06. <a href='../../lib/screens/capture_upload_sheet/widgets/capture_upload_header.dart#L174' style='text-decoration:underline'>lib/screens/capture_upload_sheet/widgets<br/>capture_upload_header.dart:174-174</a><br/>Tap Capture Pages"]
    G["07. <a href='../../lib/screens/capture_upload_sheet/screens/capture_upload_sheet_screen.dart#L657' style='text-decoration:underline'>lib/screens/capture_upload_sheet/screens<br/>capture_upload_sheet_screen.dart:657-705</a><br/>Open the camera and check the picture and page limits"]
    H["08. <a href='../../lib/screens/capture_upload_sheet/models/selected_sheet_file.dart#L3' style='text-decoration:underline'>lib/screens/capture_upload_sheet/models<br/>selected_sheet_file.dart:3-25</a><br/>Keep the selected file's name, contents and location"]
    I["09. <a href='../../lib/screens/capture_upload_sheet/widgets/selected_sheets_container.dart#L10' style='text-decoration:underline'>lib/screens/capture_upload_sheet/widgets<br/>selected_sheets_container.dart:10-196</a><br/>Show selected files; tap to preview or swipe to remove"]
    J["10. <a href='../../lib/screens/capture_upload_sheet/dialogs/selected_sheet_preview_dialog.dart#L8' style='text-decoration:underline'>lib/screens/capture_upload_sheet/dialogs<br/>selected_sheet_preview_dialog.dart:8-78</a><br/>Show the PDF or a picture that can be zoomed"]
    A --> B --> C --> D --> H
    D -. "Count pages" .-> E
    F --> G --> H --> I --> J```
