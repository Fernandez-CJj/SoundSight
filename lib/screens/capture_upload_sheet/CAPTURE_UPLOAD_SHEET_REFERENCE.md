# Capture and Upload Sheet Reference

## Purpose

This feature lets a signed-in user add sheet music in either of two ways:

- upload one PDF from the device;
- upload up to 20 image files; or
- capture up to 20 photos using the phone camera.

The selected files can be previewed and removed before they are saved. Saving
uploads the files to Firebase Storage and creates a sheet record in Firestore.

## Ways to Open the Feature

The user can open the screen from:

- **Upload / Capture Sheet** in the app drawer;
- the music-sheet screen's add-sheet action; or
- the Home screen's Upload Sheet or Capture Sheet quick action.

The Home quick actions automatically open the file picker or camera after the
screen appears. The other entry points open the screen without automatically
choosing an action.

## Complete User Flow

1. The user opens the **Add Sheet** screen.
2. The app loads the signed-in user's theme from Firestore when possible.
3. The user chooses **Upload** or **Capture**.
4. The app checks the selected file type, size, page count, duplicate status,
   and remaining image slots.
5. Accepted files appear in the **Selected files** list.
6. The user can tap a file to preview it.
7. The user can swipe right on one file and confirm its removal.
8. The user can use the app-bar delete button and confirm removal of all files.
9. The user presses **Save Sheet**.
10. The app requires a signed-in Firebase user.
11. A dialog asks for a sheet title.
12. After a valid title is submitted, uploading begins.
13. The bottom button displays progress based on uploaded bytes.
14. Every file is uploaded to Firebase Storage.
15. After all files upload, a new Firestore `musicSheets` document is created.
16. On success, the local selection is cleared and a success dialog appears.
17. On failure, the selected files remain available and a failure dialog lets
    the user return to the selection.

The success dialog does not automatically open the saved sheet or return to the
music-sheet library. The user remains on the Add Sheet screen after closing it.

## Temporary Local Information

The following information exists only while this screen remains open:

- `isDarkMode`: the colors currently used by the screen.
- `selectedSheets`: the selected PDF, uploaded images, or captured images.
- `selectedPdfPageCount`: the number of pages found in the selected PDF.
- `isPickingFiles`: whether the device file picker is open or being processed.
- `isSavingSheet`: whether Firebase saving is in progress.
- `uploadProgress`: the current upload percentage from `0` to `1`.
- The image picker used to open the phone camera.
- The upload service used to validate and save the selected files.
- The temporary title text inside the title dialog.

The file picker requests file bytes with each selected file. Those bytes are
held in memory for previewing and uploading.

Leaving the screen before saving discards the screen's selection. There is no
local draft, saved upload queue, or resume record.

## When Information Is Saved Permanently

Nothing is saved to this feature's Firebase paths when the user merely selects,
captures, previews, or removes files.

Permanent saving begins only after all of these are true:

- at least one file is selected;
- the screen is not already picking or saving;
- a Firebase user is signed in; and
- the user submits a valid title.

The service generates a new Firestore sheet ID before uploading. It then saves
the files to Firebase Storage one at a time. The Firestore document is created
only after every file upload succeeds.

## Firebase Paths

### Theme read

```text
users/{userId}
```

The screen reads the existing `theme` field. It does not update the user
document.

### Music-sheet document

```text
musicSheets/{sheetId}
```

`sheetId` is an automatically generated Firestore document ID.

### PDF file

```text
musicSheets/{ownerId}/{sheetId}/sheet.pdf
```

### Image files

```text
musicSheets/{ownerId}/{sheetId}/page_01.{extension}
musicSheets/{ownerId}/{sheetId}/page_02.{extension}
...
musicSheets/{ownerId}/{sheetId}/page_20.{extension}
```

Image page numbers follow the order of `selectedSheets` and start at 1.

## Firestore Fields Created

Saving creates one new `musicSheets/{sheetId}` document with these fields:

| Field | Stored value |
| --- | --- |
| `ownerId` | The signed-in user's Firebase UID |
| `title` | The trimmed title entered by the user |
| `type` | `pdf` or `images` |
| `pageCount` | PDF page count or number of image files |
| `files` | List describing the uploaded Storage files |
| `createdAt` | Firestore server timestamp |
| `updatedAt` | Firestore server timestamp |

Every item inside `files` contains:

| Field | Stored value |
| --- | --- |
| `name` | Original selected file name |
| `storagePath` | Full Firebase Storage path |
| `sizeBytes` | Uploaded byte count |
| `contentType` | MIME type such as `image/jpeg` or `application/pdf` |
| `pageNumber` | Image position starting at 1, or `null` for a PDF |

## Existing Fields Updated

This feature does not update an existing music-sheet document or user field.

Although the new document contains a field named `updatedAt`, that field is
created during the initial save. This screen has no edit-existing-sheet flow.

## Firebase Storage Information

Each uploaded object receives a content type and these custom metadata fields:

- `ownerId`: signed-in user's UID;
- `sheetId`: generated Firestore sheet ID; and
- `originalName`: original file name.

Supported stored extensions are `pdf`, `png`, `jpg`, `jpeg`, `heic`, and
`webp`. An unknown extension falls back to a `.jpg` Storage name and JPEG
content type. The visible file picker itself only allows JPG, JPEG, PNG, and
PDF files.

## Client-Side Validation

Client-side validation runs in the Flutter app before Firebase accepts the
request.

### General selection rules

- The user can select one PDF or up to 20 images.
- PDFs and images cannot be mixed.
- A selected PDF must be removed before images can be added.
- Selected images must be removed before a PDF can be chosen.
- File picking and capturing are blocked while saving.
- Saving is blocked while file picking is still active.

### Image rules

- The file picker accepts JPG, JPEG, and PNG images.
- Each uploaded or captured image must be 5 MB or smaller.
- Images beyond the remaining 20 slots are skipped.
- Uploaded images with the same file name and byte size as an existing
  selection are treated as duplicates and skipped.
- Captured photos use image quality `90` before their bytes are checked.

If only some uploaded images are invalid, valid images can still be added. A
message reports oversized, duplicate, or excess files that were skipped.

### PDF rules

- Exactly one PDF must be selected by itself.
- The PDF must be 20 MB or smaller.
- Its bytes must be available and readable.
- It must contain between 1 and 20 pages.
- An invalid, unreadable, or locked PDF is rejected.

### Title rules

- The title is required after trimming spaces from its beginning and end.
- The title can contain at most 80 characters.
- The first file name, without its final extension, becomes the initial title.
- The initial title is shortened to 80 characters when necessary.
- `Untitled Sheet` is used when the derived initial title is empty.

### Final service validation

The upload service checks the files again immediately before uploading:

- there must be between 1 and 20 selected files;
- a PDF must be alone and have a known page count from 1 to 20;
- every file must contain non-empty bytes; and
- every file must remain within its size limit.

This second validation protects the save operation even if the screen-level
selection checks are bypassed accidentally.

## Firestore Rules Validation

Firestore Rules protect `musicSheets/{sheetId}` as follows:

### Create

- The request must come from a signed-in Firebase user.
- `ownerId` must equal that user's UID.
- `title` must be a string containing 1 to 80 characters.
- `type` must be a string and must work with one of the allowed structures.
- `pageCount` must be an integer from 1 to 20.
- `files` must be a list containing 1 to 20 entries.
- A `pdf` document must contain exactly one file entry.
- An `images` document must contain the same number of file entries as
  `pageCount`.

The current Firestore validation does not inspect every field inside each
`files` item. It also does not restrict the complete set of document keys or
validate the two timestamp fields. Those values are still created by the
client's save service.

### Read and delete

Only a signed-in user whose UID matches the stored `ownerId` may read or delete
the document.

### Update

Rules allow the owner to update a sheet only if `ownerId` remains unchanged and
the resulting document still passes `validMusicSheet`. This capture/upload
feature does not perform updates.

## Firebase Storage Rules Validation

Storage Rules protect every path under
`musicSheets/{ownerId}/{sheetId}/{fileName}`.

For every read, create, update, or delete, the request must be signed in and the
user's UID must match `ownerId` in the Storage path.

For an image upload:

- the content type must be an image type;
- the file must be 5 MB or smaller; and
- the name must be `page_01` through `page_20` with an allowed JPG, JPEG, PNG,
  HEIC, or WEBP extension.

For a PDF upload:

- the content type must be `application/pdf`;
- the file must be 20 MB or smaller; and
- the exact file name must be `sheet.pdf`.

## Page Count and Upload Progress

For an image sheet, `pageCount` is the number of selected image files.

For a PDF sheet, the app opens the PDF bytes and reads the document's page
count before accepting it.

Upload progress is based on bytes rather than the number of files:

```text
progress = already completed bytes + current uploaded bytes
           --------------------------------------------------
                        total selected bytes
```

The result is limited to the range `0` through `1`. The button converts it to a
rounded percentage such as **Saving 64%**.

## Cancel, Remove, Failure, and Retry

### Cancel before saving

- Cancelling the file picker adds nothing.
- Cancelling the camera adds nothing.
- Cancelling the title dialog starts no upload.
- Cancelling a remove or delete-all dialog keeps the selected files.

### Remove selected files

- Swiping one file to the right opens a confirmation dialog.
- The app-bar delete button asks before clearing all selected files.
- Removing the last file also clears the stored PDF page count.

These actions affect only temporary screen memory. They do not delete an
already saved sheet from Firebase.

### While saving

- Back navigation is blocked.
- The drawer is removed.
- Upload, capture, remove, and delete actions are disabled.
- The save button shows upload progress and cannot be pressed again.

### Save failure

If any upload or Firestore write fails, the service:

1. attempts to delete every Storage object uploaded during that attempt;
2. attempts to delete the generated Firestore document; and
3. sends the error back to the screen.

Cleanup errors are ignored so the original save error can continue.

The screen resets its saving state and progress but does not clear the selected
files. The failure dialog says to check the connection and try again. After the
user chooses **Back to selection**, they can press **Save Sheet** for another
attempt.

There is no automatic retry, background upload queue, resumable saved draft, or
expiration behavior.

## Preview Behavior

Tapping a selected PDF opens an in-memory PDF viewer. Tapping an image opens an
image preview that the user can zoom up to four times.

If the selected file does not contain bytes, the dialog displays **Preview is
not available**.

## What Happens After Completion

After a successful save:

- the temporary selected-file list is cleared;
- the temporary PDF page count is cleared;
- saving becomes inactive;
- upload progress returns to zero; and
- a non-dismissible success dialog displays the saved title.

Pressing **Done** closes only the dialog. The generated document ID is returned
by the upload service, but the current screen does not use it for navigation or
another operation.

## Simple Save Example

Suppose the user selects three images in this order:

```text
page-one.jpg
page-two.png
page-three.jpeg
```

The app creates Storage objects similar to:

```text
musicSheets/USER_ID/SHEET_ID/page_01.jpg
musicSheets/USER_ID/SHEET_ID/page_02.png
musicSheets/USER_ID/SHEET_ID/page_03.jpeg
```

The Firestore sheet document uses:

```text
type: images
pageCount: 3
```

Its three `files` items have page numbers 1, 2, and 3 in the same order.
