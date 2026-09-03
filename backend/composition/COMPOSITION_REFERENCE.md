# Composition Publishing Reference

## Purpose

The `composition` folder converts a saved SoundSight composition into a published piano score.

It creates MusicXML and PDF files, uploads the PDF, stores a public post and version history, and removes published data when the owner unpublishes.

## Complete publishing flow

1. In the composition details screen, the user selects Publish Composition.
2. The client refuses to continue when the composition has no notes.
3. The user confirms the publish dialog.
4. The Flutter client sends the composition to `POST /compositions` with a two-minute timeout.
5. FastAPI converts the JSON body into a `CompositionRequest`.
6. The backend reads `users/{ownerId}` for the public username and profile image.
7. If usable profile values are unavailable, it uses `SoundSight Musician` and an empty image URL.
8. music21 builds a grand-staff piano score with treble and bass staves.
9. The backend calculates the next published version.
10. It writes a local MusicXML file.
11. MuseScore converts the MusicXML file to PDF.
12. The PDF is uploaded to Firebase Storage.
13. Firestore receives the current post and the new immutable version document in one batch.
14. The backend returns the post ID and score statistics.
15. The Flutter app shows a success message.

## Score construction

The score title is the composition title. The composer name comes from the owner's public profile.

Notes are divided by MIDI number:

- MIDI 60 and higher go to the treble staff;
- MIDI 59 and lower go to the bass staff.

Each staff receives the requested number of measures. The first measure receives its clef, key signature, and time signature. Tempo is placed on the treble staff.

The beat length is calculated as `4 / beatUnit`.

Empty time before, between, and after notes is filled with rests.

Notes with the same start beat and duration are grouped into a chord. A difference smaller than `0.0001` is treated as the same time.

A tie is continued when a previous note:

- has the same MIDI number;
- ends where the current note starts;
- has `tieToNext` enabled.

The tie becomes `start`, `continue`, or `stop` depending on the neighboring notes.

## Temporary local information

During a request, the backend holds the validated request, music21 score, counters, and Firebase data in memory.

Generated files are written to:

- `backend/generated_files/{compositionId}.musicxml`;
- `backend/generated_files/{compositionId}.pdf`.

If the composition ID is empty, the MusicXML file is named `composition.musicxml`.

These generated files are local backend files. The current code does not delete them after publishing or unpublishing.

## Permanent Firebase information

### Firebase Storage

Each published PDF is uploaded to:

- `published_compositions/{ownerId}/{compositionId}/version_{versionNumber}.pdf`.

Older version PDFs remain available until the composition is unpublished.

### Current Firestore post

The current public post is written to:

- `compositionPosts/{compositionId}`.

Every publish replaces that document with these fields:

- `compositionId`;
- `ownerId`;
- `authorName`;
- `authorProfileImageUrl`;
- `currentVersion`;
- `title`;
- `tempo`;
- `key`;
- `beatsPerMeasure`;
- `beatUnit`;
- `measureCount`;
- `noteCount`;
- `pdfStoragePath`;
- `publishedAt`.

`publishedAt` uses a server timestamp. `noteCount` is the number of submitted note records.

### Firestore version history

Each publish creates or replaces:

- `compositionPosts/{compositionId}/versions/{versionNumber}`.

The version document contains all current-post fields plus:

- `versionNumber`;
- `notes`.

Each item in `notes` contains:

- `noteId`;
- `pitch`;
- `octave`;
- `midiNumber`;
- `measureIndex`;
- `startBeat`;
- `durationBeats`;
- `velocity`;
- `tieToNext`.

Republishing updates the current post and adds the next version. Existing older version documents are not changed.

## Version calculation

The backend reads `compositionPosts/{compositionId}.currentVersion`.

- If it is an integer, the next version is that value plus one.
- If the post is missing or the value is not an integer, publishing starts at version 1.

## Request validation

### Client-side validation

The composition details screen requires at least one note and asks for confirmation before publishing.

The Flutter HTTP client treats non-2xx responses as failures and has a two-minute publish timeout.

### Backend validation

Pydantic validates:

- octave from 0 through 8;
- MIDI number from 21 through 108;
- nonnegative measure index and start beat;
- duration greater than zero;
- velocity from 0 through 1;
- tempo from 40 through 200;
- beats per measure from 1 through 12;
- measure count from 1 through 128.

The backend model requires strings for IDs, pitch, owner, title, and key, but it does not require those strings to be non-empty. It also does not set a maximum note count or require at least one note.

The key-building code expects the key text to contain a name and mode separated by a space.

## Firestore and Storage Rules

Signed-in Flutter clients can read `compositionPosts` and version documents, but Firestore Rules deny direct client creation, update, and deletion of those documents.

Signed-in clients can read published PDFs. Storage Rules deny direct client writes and deletes under `published_compositions`.

The backend uses Firebase Admin, so it bypasses those rules.

The publish HTTP route does not verify a Firebase authentication token or independently confirm that `ownerId` belongs to the caller. It trusts the request body. The backend also does not compare the composition against the private `compositions/{compositionId}` document.

## Returned statistics

The successful HTTP response includes:

- submitted note-record count;
- generated score-note count, with every chord pitch counted;
- chord count;
- rest count;
- tied-note count;
- part count;
- local MusicXML and PDF existence results;
- PDF name and Storage path.

These response statistics are not all saved in Firestore. The post only stores the submitted `noteCount` and general composition information.

## Unpublishing flow

1. The Flutter client sends `DELETE /compositions/{compositionId}` with `ownerId` and a one-minute timeout.
2. The backend reads `compositionPosts/{compositionId}`.
3. A missing post returns `404`.
4. An owner mismatch returns `403`.
5. All versioned PDFs under the composition's Storage folder are deleted.
6. A legacy PDF at `published_compositions/{ownerId}/{compositionId}.pdf` is also deleted if present.
7. Every version's likes and comments are deleted.
8. Every version document is deleted.
9. Every `savedCompositionPosts` document whose `postId` matches the composition is deleted.
10. The current post is deleted.

Unpublishing does not delete the owner's private `compositions/{compositionId}` document or local files in `backend/generated_files`.

## Failure and retry behavior

Publishing has no transaction covering local generation, Storage upload, and Firestore writes together. A failure after an earlier step can leave a generated local file or uploaded PDF behind.

The two Firestore writes for the current post and version document are committed in one Firestore batch.

There is no pause, resume, skip, or expiration behavior. Retrying publishes again using the version found in the current Firestore post.

Unpublishing performs multiple deletions without one transaction. If a later deletion fails, earlier deletions are not restored automatically.

## Simple example

If a composition with ID `song123` is published for the first time by `userA`:

- its PDF is stored at `published_compositions/userA/song123/version_1.pdf`;
- its current post is `compositionPosts/song123`;
- its version is `compositionPosts/song123/versions/1`;
- publishing it again normally creates `version_2.pdf` and version document `2` while updating the current post to version 2.
