# Music-Sheet OMR Reference

## Purpose

The `omr` folder recognizes notes from a music sheet that the user previously uploaded.

Audiveris performs optical music recognition and exports MusicXML. music21 validates the result, and MuseScore creates an MP3 preview.

## Complete user flow

1. The user uploads either one PDF or one or more image pages to the music-sheet library.
2. The Flutter app creates `musicSheets/{sheetId}` and uploads the source files to Firebase Storage.
3. The user opens the saved sheet and chooses Recognize or Recognize Again.
4. A confirmation dialog appears.
5. After confirmation, the screen sets its local `isConverting` value and shows a loading dialog that cannot be dismissed.
6. The Flutter client sends `POST /music-sheets/{sheetId}/recognize` with `ownerId` and a 15-minute timeout.
7. The backend loads `musicSheets/{sheetId}`.
8. It verifies that the document exists, its `ownerId` matches the request, and it contains at least one file.
9. The Firestore status becomes `processing`.
10. A fresh local job folder is created for the sheet.
11. Source files are downloaded from Firebase Storage.
12. Image pages are sorted and combined into one RGB PDF at 300 DPI. An uploaded PDF is used directly.
13. Audiveris processes the PDF and exports an `.mxl` MusicXML file.
14. music21 verifies that the MusicXML is readable and contains at least one note.
15. MuseScore converts the MusicXML into an MP3 preview.
16. The MusicXML and MP3 are uploaded to Firebase Storage.
17. The Firestore sheet becomes `completed` and receives its result fields.
18. The temporary job folder is deleted.
19. The Flutter screen receives the response and displays a success dialog.

## Temporary local information

### Flutter screen memory

The viewer temporarily stores:

- `isConverting`, which prevents another request from the same screen while one is active;
- the returned conversion result or error;
- loading-dialog state;
- futures used to load the displayed source sheet.

These values are not permanent Firebase fields.

### Backend memory and files

The backend temporarily stores the sheet data, downloaded paths, validation result, and output paths during the request.

Each attempt uses:

- `backend/omr_jobs/{safeSheetId}/input`;
- `backend/omr_jobs/{safeSheetId}/output`.

Slashes in the sheet ID are replaced with underscores for the local folder name.

If a folder already exists for that sheet, it is deleted before the new attempt starts. The attempt folder is deleted in the final cleanup after success or failure.

## Original sheet information

Before recognition, the Flutter upload feature permanently creates:

- Firestore `musicSheets/{sheetId}`;
- Storage `musicSheets/{ownerId}/{sheetId}/sheet.pdf` for a PDF;
- Storage `musicSheets/{ownerId}/{sheetId}/page_01.ext`, `page_02.ext`, and so on for images.

The original Firestore document contains:

- `ownerId`;
- `title`;
- `type`, either `pdf` or `images`;
- `pageCount`;
- `files`;
- `createdAt`;
- `updatedAt`.

Each `files` item contains its original name, Storage path, byte size, content type, and image page number when applicable.

## Recognition status fields

Recognition updates the existing `musicSheets/{sheetId}` document.

### When processing begins

The backend sets or updates:

- `omrStatus: processing`;
- `omrEngine: audiveris`;
- `omrError: null`;
- `omrStartedAt` to a server timestamp.

It deletes `omrFailedAt` when that field exists.

### When recognition succeeds

The backend sets or updates:

- `omrStatus: completed`;
- `omrEngine: audiveris`;
- `omrError: null`;
- `omrProcessedAt` to a server timestamp;
- `musicXmlStoragePath`;
- `previewAudioStoragePath`;
- `omrPartCount`;
- `omrNoteCount`.

It deletes `omrFailedAt` when that field exists.

### When recognition fails

The backend sets or updates:

- `omrStatus: failed`;
- `omrEngine: audiveris`;
- `omrError`;
- `omrFailedAt` to a server timestamp.

The stored error text is limited to 500 characters.

Failure does not clear older successful result paths, counts, or `omrProcessedAt`. Processing also does not clear those older result fields during reconversion.

## Generated Firebase Storage files

Successful recognition creates or replaces:

- `musicSheets/{ownerId}/{sheetId}/recognized.mxl`;
- `musicSheets/{ownerId}/{sheetId}/preview.mp3`.

If the MusicXML upload succeeds but the MP3 upload fails, the upload service attempts to delete the MusicXML it uploaded during that attempt.

## Client-side validation

The upload client allows:

- 1 through 20 pages;
- one PDF by itself;
- PDFs up to 20 MB;
- images up to 5 MB each;
- PDF, PNG, JPG, JPEG, HEIC, and WebP extensions.

Before calling the backend, the recognition client requires non-empty sheet and owner IDs.

The screen ignores a second recognition action while its local `isConverting` value is true.

## Backend validation

The request body must contain a string `ownerId`.

The backend requires:

- an existing `musicSheets/{sheetId}` document;
- a matching owner ID;
- at least one entry in `files`;
- every referenced Storage file to exist;
- JPG, JPEG, or PNG extensions for image-based recognition;
- an Audiveris installation at the configured paths;
- Audiveris to produce an `.mxl` file;
- music21 to read that file;
- at least one recognized note;
- MuseScore to create a non-empty MP3.

There is a current mismatch: the upload client accepts HEIC and WebP images, but the backend OMR downloader accepts only JPG, JPEG, and PNG images. HEIC or WebP sheets can be saved in the library but recognition rejects them as unsupported images.

## Note and part calculation

music21 reads the recognized score.

- A normal note adds one to `omrNoteCount`.
- Every pitch inside a chord adds one to `omrNoteCount`.
- The number of score parts becomes `omrPartCount`.

A result with zero notes is rejected.

## Audiveris behavior

Audiveris is expected under `C:\Program Files\Audiveris` with its bundled Java runtime and application files.

The command identifies version `5.11.0`, allows up to 8 GB of Java heap memory, lowers the minimum staff-length constant to `10.0`, and runs in batch mode.

Audiveris has a 30-minute backend timeout. The Flutter HTTP client has a shorter 15-minute timeout, so the client can report a timeout while the backend process continues and later updates Firestore.

## Firestore and Storage Rules

For direct Flutter access, Firestore Rules require the signed-in user to own `musicSheets/{sheetId}` for creation, reading, updating, or deletion. The document must keep a valid title, type, page count, and files list.

Storage Rules allow only the owner to read source and generated files under the sheet's Storage folder.

Direct client uploads are restricted to the expected original image names and sizes or `sheet.pdf`. The client rules do not allow direct `.mxl` or MP3 writes.

The backend uses Firebase Admin and therefore bypasses Firestore Rules and Storage Rules. It performs its own ownership check before starting recognition.

The recognition HTTP route does not verify a Firebase authentication token. It trusts the submitted `ownerId`, then compares that value with the owner stored in the sheet document.

## Failure, retry, and reconversion

Missing documents and files return `404`. Owner mismatches return `403`. Invalid data and invalid recognition output return `400`. Audiveris, MuseScore, and unexpected processing failures return `500`.

After most failures that happen after the ownership check, the backend records `omrStatus: failed` and cleans the job folder.

If the sheet lookup itself fails because the sheet is missing, belongs to another owner, or has no files, the status is not changed because that lookup occurs before the conversion error handler begins.

There is no pause, resume, skip, expiration, background queue, or automatic retry.

The user can manually retry. A new attempt deletes any existing local job folder and starts again. A completed sheet can also be recognized again; the successful result files are replaced at the same Storage paths.

The backend does not block two separate clients from requesting the same sheet at the same time. The `isConverting` check only protects one open Flutter screen instance.

If the backend process stops while a sheet is marked `processing`, the current code has no automatic expiration or recovery process to change that status.

## What happens after completion

The viewer listens to `musicSheets/{sheetId}` in real time. After completion, it displays the recognized part and note counts.

When `previewAudioStoragePath` is present and the sheet is not processing, the viewer displays an audio preview player.

The API response also returns the sheet ID, title, completed status, counts, and generated Storage paths.

## Simple example

For sheet `sheet123` owned by `userA`, a successful attempt stores:

- `musicSheets/userA/sheet123/recognized.mxl`;
- `musicSheets/userA/sheet123/preview.mp3`.

The document `musicSheets/sheet123` is updated to `completed` with the two paths and recognized note and part counts.
