# Backend Reference

## Purpose

The backend is a FastAPI server that supports two SoundSight features:

- publishing and unpublishing compositions;
- recognizing uploaded music sheets with optical music recognition (OMR).

It also has simple routes for checking whether the server is running.

## Starting the backend

The server must be started from the `backend` folder so its imports resolve correctly.

The Python packages are listed in `requirements.txt`:

- FastAPI;
- Uvicorn;
- music21;
- Firebase Admin;
- Pillow.

The Flutter clients currently call `http://127.0.0.1:8000`.

## Available routes

### `GET /`

Returns a message confirming that the backend is running.

### `GET /health`

Returns:

- `status: ok`;
- whether the expected Audiveris files and folders exist.

This health check does not test MuseScore, Firebase, or an actual OMR conversion.

### `POST /music-sheets/{sheetId}/recognize`

Starts recognition for an existing music sheet. The request body contains `ownerId`.

The complete recognition process is documented in `omr/OMR_REFERENCE.md`.

### `POST /compositions`

Builds and publishes a composition. The request body contains the composition details and notes.

The complete publishing process is documented in `composition/COMPOSITION_REFERENCE.md`.

### `POST /compositions/{compositionId}/generate`

Generates the private composition's MusicXML, PDF, MIDI, and MP3. The request requires a verified Firebase ID token in the bearer authorization header. The backend reads the authoritative composition from `users/{authenticatedUserId}/compositions/{compositionId}` and verifies its stored owner ID.

Manual compositions write MIDI directly from their exact measure-and-beat data. New performance recordings write MIDI directly from captured microsecond Note On/Note Off data. MuseScore renders each composition's MP3 from its resulting MIDI so playback and Sight Reading use the same timeline.

### `DELETE /compositions/{compositionId}`

Unpublishes a composition. The request body contains `ownerId`.

## Complete high-level flow

### Composition publishing

1. The Flutter app sends a saved composition to `POST /compositions`.
2. The backend reads the owner's public profile from Firebase.
3. music21 creates a two-staff piano score.
4. A MusicXML file is written to a temporary system folder.
5. MuseScore converts the MusicXML file to PDF.
6. The PDF is uploaded to Firebase Storage.
7. The current published post and a permanent version document are saved in Firestore.
8. The backend returns the post ID and score statistics.

### Music-sheet recognition

1. The Flutter app sends a sheet ID and owner ID to the recognition route.
2. The backend verifies that the Firestore sheet exists, belongs to that owner, and has files.
3. The sheet status becomes `processing`.
4. Uploaded files are downloaded to a temporary job folder.
5. Image pages are combined into one PDF when necessary.
6. Audiveris converts the PDF into compressed MusicXML, which the backend extracts.
7. music21 confirms that the extracted plain MusicXML is readable and contains notes.
8. MuseScore creates a recognized PDF, MIDI file, and MP3 preview from the extracted score.
9. The MusicXML, PDF, MIDI, and MP3 are uploaded to Firebase Storage.
10. The sheet document becomes `completed` and stores the results.
11. Temporary job files are deleted.

## Temporary local information

The backend temporarily holds Python objects for requests, scores, validation results, and response data.

OMR input and output files use a unique temporary system folder for each attempt. The folder is removed after recognition finishes.

Composition MusicXML, PDF, MIDI, and MP3 files use a temporary system folder and are removed after generation or publishing finishes, including on failure.

## Information saved permanently

The backend writes to:

- Firestore `compositionPosts/{compositionId}`;
- Firestore `compositionPosts/{compositionId}/versions/{versionNumber}`;
- Firestore `users/{ownerId}/musicSheets/{sheetId}`;
- Firebase Storage `published_compositions/{ownerId}/{compositionId}/...`;
- Firebase Storage `musicSheets/{ownerId}/{sheetId}/...`.

## Validation

FastAPI uses Pydantic models to validate request shapes and numeric ranges. Invalid request data is normally rejected before the route runs.

The OMR route also validates sheet ownership, source files, Audiveris output, and whether MusicXML contains notes.

The publish route validates numeric request fields, but some values such as non-empty owner IDs, titles, keys, and note lists rely on client behavior or later operations.

## Firebase protection

The backend uses the Firebase Admin SDK. Admin SDK operations bypass Firestore Rules and Storage Rules.

This means the deployed Firebase Rules protect direct requests from the Flutter client, but they do not validate backend writes. The backend must perform its own checks.

Current backend checks include:

- confirming ownership before OMR recognition;
- confirming ownership before unpublishing; and
- verifying a Firebase ID token, verified email, and private-composition ownership before file generation.

The publishing, unpublishing, and OMR routes still receive `ownerId` from their request bodies and do not currently verify a Firebase token. Private composition file generation is authenticated separately and does not trust musical data from the request.

## Failure and retry behavior

The recognition route converts common failures into these HTTP responses:

- `400` for invalid sheet data or invalid recognition output;
- `403` for an owner mismatch;
- `404` for missing sheets or files;
- `500` for Audiveris, MuseScore, and unexpected failures.

Invalid Pydantic request data normally returns `422`.

Unpublishing returns `403` for an owner mismatch and `404` when the post does not exist.

Publishing does not have custom error mapping. Unhandled failures are returned by FastAPI as server errors.

There is no backend queue, expiration system, pause, or resume feature. Retrying sends a new HTTP request and starts the operation again.

## Completion

Successful routes return JSON to the Flutter app. Permanent results are already saved in Firebase before a successful response is returned.

The Flutter app then displays a success message or refreshes from Firestore streams.
