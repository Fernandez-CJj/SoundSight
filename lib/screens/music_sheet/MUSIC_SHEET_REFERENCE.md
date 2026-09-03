# Music Sheet Feature Reference

This document describes the Music Sheet library, viewer, translation, audio preview, renaming, and deletion behavior in the current code.

The separate Capture and Upload Sheet feature creates the original sheet record and uploads its source files. Its detailed behavior is documented in `../capture_upload_sheet/CAPTURE_UPLOAD_SHEET_REFERENCE.md`.

## 1. Purpose

The Music Sheet feature lets a signed-in user:

- view their uploaded PDF or image music sheets;
- add another sheet through the Capture and Upload Sheet feature;
- rename a saved sheet;
- delete a sheet and its stored files;
- ask the backend to recognize printed music with OMR;
- view the number of recognized parts and notes; and
- listen to an MP3 preview created from the recognized music.

OMR means optical music recognition. It is the process of reading printed sheet-music images and converting them into structured music data.

The current backend uses Audiveris for recognition and MuseScore for MP3 generation.

## 2. Complete user flow

### Opening the library

The user can open **Music Sheets** from the drawer or home screen.

1. The screen reads the current Firebase user's ID.
2. It subscribes to `/musicSheets` documents whose `ownerId` matches that ID.
3. Sheets are sorted in the app by `createdAt`, newest first.
4. Each card shows the title, number of pages, PDF or Images type, and creation date.

A signed-out user sees **Sign in to view your music sheets**.

### Adding a sheet

The app-bar add button and empty-library button open `CaptureUploadSheetScreen`.

That feature lets the user upload one PDF or up to 20 images, then creates the source files in Firebase Storage and the initial `/musicSheets/{sheetId}` document.

The Music Sheet library updates automatically because it uses a Firestore stream.

### Viewing a sheet

Tapping a card opens the viewer.

- A PDF sheet downloads its first file and displays it in a PDF viewer.
- An image sheet sorts its files by `pageNumber` and shows each page vertically.
- Each image can be panned and zoomed up to five times.
- A single image download is limited to 5 MB.
- A PDF download is limited to 20 MB.
- File downloads time out after one minute.

If a source file cannot be loaded, the viewer shows **Try Again**.

### Translating a sheet

The viewer watches the sheet document's OMR fields in real time.

The initial status is treated as `notStarted` when `omrStatus` is missing.

1. The user taps **Translate**.
2. A confirmation dialog explains that translation may take a few minutes.
3. The app opens a non-dismissible loading dialog and asks the backend to recognize the sheet.
4. The backend confirms that the sheet exists, belongs to the supplied owner ID, and contains files.
5. The backend changes `omrStatus` to `processing`.
6. Source files are downloaded from Firebase Storage into a temporary backend job folder.
7. Image sheets are sorted by page number and combined into a 300-DPI PDF. PDF sheets are used directly.
8. Audiveris converts the prepared PDF into a compressed MusicXML `.mxl` file.
9. The backend opens the MusicXML and counts its parts and notes.
10. Recognition fails if the MusicXML cannot be read or contains no notes.
11. MuseScore converts the MusicXML into an MP3 audio preview.
12. The MusicXML and MP3 are uploaded to Firebase Storage.
13. The sheet document is updated to `completed` with the output paths and counts.
14. The temporary backend job folder is deleted.
15. The app closes the loading dialog and shows the recognized part and note counts.

The app waits up to 15 minutes for the HTTP request. Audiveris itself has a 30-minute process timeout, while MuseScore's MP3 export has a 10-minute process timeout.

The current backend address in the app is `http://127.0.0.1:8000`.

### Translation status

The status card displays:

- **Translate** when translation has not started;
- **Translating music sheet** while the backend is processing;
- **Translation ready** after success; or
- **Translation failed** after failure.

After success, the button becomes **Reconvert**. Reconvert runs the same flow and overwrites the current `recognized.mxl` and `preview.mp3` files rather than creating numbered versions.

After failure, the button becomes **Retry**.

### Audio preview

The audio controls appear when:

- the status is not `processing`; and
- `previewAudioStoragePath` is not empty.

On the first Play action, the app downloads at most 30 MB of audio bytes from Firebase Storage and keeps those bytes in screen memory. The user can:

- play;
- pause;
- resume;
- stop;
- seek with the progress slider; and
- see the current and total duration.

After playback completes, the position returns to the beginning.

### Play-mode button

The large **Play** button in the viewer opens a choice between Sight Reading and Synthesia.

In the current code:

- choosing **Sight Reading** closes the dialog but opens no screen; and
- choosing **Synthesia** opens `SynthesiaScreen`, but does not pass the selected sheet or its recognized MusicXML to that screen.

This button is separate from the generated MP3 audio-preview controls.

### Renaming

From a sheet card's menu, the user can choose **Rename**.

1. The current title is placed in the text field.
2. The title is trimmed.
3. It must contain at least one character and cannot exceed 80 characters.
4. If it differs from the current title, the app updates `title` and `updatedAt`.

Renaming does not rename files in Firebase Storage and does not rerun recognition.

### Deleting

From a sheet card's menu, the user can choose **Delete**.

The current screen refuses to delete a sheet while its stored `omrStatus` is `processing`.

After confirmation, the app collects and deletes:

- every source path inside the `files` list;
- the stored `musicXmlStoragePath`, when present;
- the stored `previewAudioStoragePath`, when present;
- the expected `recognized.mxl` path; and
- the expected `preview.mp3` path.

Duplicate paths are removed before deletion. A missing Storage object is ignored. After Storage cleanup succeeds, the Firestore sheet document is deleted.

## 3. Temporary local information

### Music Sheet library

- the signed-in user's ID;
- the live Firestore stream;
- the current theme; and
- the IDs of sheets currently being deleted.

### Viewer

- a copied and page-sorted list of source file descriptions;
- cached download futures for image bytes;
- the PDF download future;
- whether translation is currently running; and
- the backend conversion result or error used by the result dialog.

### Audio preview

- downloaded MP3 bytes, limited to 30 MB;
- player state;
- current playback position;
- audio duration; and
- whether audio is loading.

These audio bytes and playback values are not saved when the viewer closes.

### Backend job files

The backend creates `backend/omr_jobs/{sheetId}/input` and `output` folders during recognition. It deletes the entire sheet job folder in a `finally` step after success or failure.

## 4. When information is saved permanently

### Initial sheet

The Capture and Upload Sheet feature permanently saves the initial Firestore document only after all selected source files upload successfully.

Simply opening, downloading, or viewing a sheet does not update it.

### Rename

A valid changed title is saved immediately after the Rename dialog returns.

### Translation

The backend writes a processing status when recognition begins. It then writes either completed result fields or failure fields.

The generated MusicXML and MP3 become permanent Firebase Storage objects after successful upload. Reconversion replaces these same two objects.

### Playback

Playing, pausing, seeking, or stopping the audio preview saves nothing.

## 5. Firebase and backend paths

| Information | Path |
| --- | --- |
| Music-sheet document | `/musicSheets/{sheetId}` |
| User theme | `/users/{userId}` field `theme` |
| Uploaded PDF | `musicSheets/{ownerId}/{sheetId}/sheet.pdf` |
| Uploaded image page | `musicSheets/{ownerId}/{sheetId}/page_01.{extension}` through `page_20.{extension}` |
| Recognized MusicXML | `musicSheets/{ownerId}/{sheetId}/recognized.mxl` |
| Generated audio preview | `musicSheets/{ownerId}/{sheetId}/preview.mp3` |
| Recognition endpoint | `POST /music-sheets/{sheetId}/recognize` |

The library reads `theme` from the user document but does not update it.

## 6. Created and updated fields

### Fields created by Capture and Upload Sheet

The initial `/musicSheets/{sheetId}` document contains:

- `ownerId`;
- `title`;
- `type`;
- `pageCount`;
- `files`;
- `createdAt`; and
- `updatedAt`.

Each item inside `files` contains:

- `name`;
- `storagePath`;
- `sizeBytes`;
- `contentType`; and
- `pageNumber`.

For a PDF, `pageNumber` is `null`. For images, page numbers begin at `1`.

### Fields updated during rename

- `title`; and
- `updatedAt`, using a Firestore server timestamp.

No other sheet field is changed by rename.

### Fields updated when OMR starts

- `omrStatus`: `processing`;
- `omrEngine`: `audiveris`;
- `omrError`: `null`;
- `omrStartedAt`: server timestamp; and
- `omrFailedAt`: deleted if it existed.

### Fields updated after successful OMR

- `omrStatus`: `completed`;
- `omrEngine`: `audiveris`;
- `omrError`: `null`;
- `omrProcessedAt`: server timestamp;
- `omrFailedAt`: deleted if it existed;
- `musicXmlStoragePath`;
- `previewAudioStoragePath`;
- `omrPartCount`; and
- `omrNoteCount`.

The OMR backend does not update the sheet's `updatedAt` field.

### Fields updated after failed OMR

- `omrStatus`: `failed`;
- `omrEngine`: `audiveris`;
- `omrError`: the error text, shortened to at most 500 characters; and
- `omrFailedAt`: server timestamp.

A failed reconversion does not explicitly remove previously saved output paths or counts. Therefore, old generated information can remain in the document while the new status is `failed`.

## 7. Client-side validation

### Library and rename

- The library queries only documents whose `ownerId` matches the current user.
- A renamed title is trimmed, required, and limited by the text field to 80 characters.
- No update is sent when the new title is unchanged.
- The screen blocks deletion when `omrStatus` is exactly `processing`.

### Viewer downloads

- An empty Storage path immediately produces no data.
- Images are limited to 5 MB per download.
- PDFs are limited to 20 MB per download.
- MP3 previews are limited to 30 MB per download.
- Source PDF and image downloads time out after one minute.
- Empty downloaded audio is rejected.

### Recognition request

The Flutter service rejects an empty `sheetId` or `ownerId` before sending the request.

The backend then requires:

- an existing sheet document;
- an `ownerId` in the request matching the stored owner ID;
- at least one source file;
- every Storage object to exist;
- PDF input or JPG, JPEG, or PNG image input;
- readable MusicXML output; and
- at least one recognized note.

Although upload Storage rules support HEIC and WEBP names, the current OMR backend accepts only `.jpg`, `.jpeg`, and `.png` for image-sheet conversion. A HEIC or WEBP source therefore fails OMR in the current backend.

## 8. Firestore and Storage Rules protection

### Music-sheet documents

Firestore Rules require authentication and enforce that:

- a newly created document's `ownerId` equals the signed-in user's ID;
- only the owner can read or delete the document;
- only the existing owner can update it;
- `ownerId` cannot be changed during an update;
- title length is 1 to 80 characters;
- `pageCount` is 1 to 20;
- `files` contains 1 to 20 items;
- a PDF has exactly one file item; and
- an image sheet has the same number of file items as `pageCount`.

The current Firestore function does not restrict the complete field list. This allows the owner or trusted backend to add OMR fields while the original sheet structure remains valid.

The Rules do not validate every nested field inside `files`, the allowed OMR status values, OMR result counts, or timestamp values.

### Source and generated files

Firebase Storage Rules require the signed-in user's ID to match `ownerId` in the path before any file can be read or deleted.

Direct client uploads are limited to:

- image files up to 5 MB with a valid `page_01` through `page_20` name; or
- one PDF up to 20 MB named exactly `sheet.pdf`.

The Storage Rules do not permit a client to create or update `recognized.mxl` or `preview.mp3`. The backend uploads those files with Firebase Admin access, which bypasses client Storage Rules.

### Current backend authorization boundary

The Flutter recognition request does not send a Firebase ID token, and the current backend endpoint does not authenticate the Firebase user.

The backend checks only whether the `ownerId` supplied in the request matches the sheet document's stored `ownerId`. Because Firebase Admin operations bypass Firestore and Storage Rules, this comparison is not the same as proving that the caller is the signed-in owner.

## 9. How OMR results are calculated

### Page order

For an image sheet, the backend sorts source file entries by `pageNumber` before downloading and combining them.

### Part count

After Audiveris creates MusicXML, `music21` parses the score. `omrPartCount` is the number of musical parts in that parsed score.

### Note count

The backend visits the parsed score's notes:

- a normal note adds `1`; and
- a chord adds the number of pitches inside that chord.

Rests do not increase `omrNoteCount`.

For example, one C note followed by a C-E-G chord produces a note count of `4`.

These counts describe what Audiveris recognized. They are not accuracy scores and are not compared with the original printed sheet.

## 10. Cancel, retry, resume, expiration, and failure behavior

### Cancel

- Cancelling Rename changes nothing.
- Cancelling Delete keeps the sheet and files.
- Cancelling the Translate or Reconvert confirmation starts no backend work.
- The translation loading dialog cannot be dismissed with Back while the app is waiting.

### Retry

- A failed source-file download has a **Try Again** button.
- A failed OMR status displays a **Retry** button.
- A completed OMR status displays **Reconvert**.
- Failed audio loading can be retried by pressing Play again because empty or failed bytes are not cached successfully.

There is no automatic retry.

### Resume

- Paused MP3 playback can resume while the viewer remains open.
- OMR work is not stored as a resumable client job.
- If the app stops waiting or closes, the Firestore status stream can show the backend's later status when the user opens the sheet again, provided the backend finishes and updates it.

### Expiration

Music sheets and generated OMR files do not expire automatically.

### Failure cleanup

The backend marks the sheet `failed` and deletes its temporary job folder after an OMR error.

If uploading generated output fails partway through, it attempts to delete generated files uploaded during that attempt. It then records the failure.

The original uploaded PDF or images remain available after translation failure.

## 11. What happens after completion

### After upload

The new sheet appears in the library's live Firestore stream. The Capture and Upload Sheet success dialog itself does not automatically navigate back to the library or open the new sheet.

### After rename

The card title changes through the live stream, and a success message appears.

### After translation

The viewer's live sheet stream changes to **Translation ready**. It displays the part and note counts and shows the MP3 audio-preview controls.

### After deletion

The source files, recognized MusicXML, audio preview, and Firestore document are removed. The library's live stream removes the card.

## 12. Simple example

Suppose a user uploads two images as a sheet named **Practice Piece**.

The source files are stored as:

```text
musicSheets/USER_ID/SHEET_ID/page_01.jpg
musicSheets/USER_ID/SHEET_ID/page_02.jpg
```

When the user taps Translate:

1. the backend combines the two pages into one temporary PDF;
2. Audiveris creates MusicXML;
3. the validator finds two musical parts and 120 notes;
4. MuseScore creates the MP3; and
5. the backend uploads:

```text
musicSheets/USER_ID/SHEET_ID/recognized.mxl
musicSheets/USER_ID/SHEET_ID/preview.mp3
```

The Firestore document then contains:

```text
omrStatus: completed
omrEngine: audiveris
omrPartCount: 2
omrNoteCount: 120
musicXmlStoragePath: musicSheets/USER_ID/SHEET_ID/recognized.mxl
previewAudioStoragePath: musicSheets/USER_ID/SHEET_ID/preview.mp3
```

The user can listen to the MP3, but the current Sight Reading and Synthesia choices do not yet use this sheet's MusicXML.
