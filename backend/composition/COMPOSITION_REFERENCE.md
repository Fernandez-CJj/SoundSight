# Composition Publishing Reference

## Purpose

The `composition` folder converts a saved SoundSight composition into a published piano score.

It copies current private PDF, MusicXML, MIDI, and MP3 files into immutable public versions, stores a public post and version history, and removes published data when the owner unpublishes.

## Complete publishing flow

1. In the composition details screen, the user selects Publish Composition.
2. The client refuses to continue when the composition has no notes.
3. The user confirms the publish dialog.
4. The Flutter client sends `POST /compositions/{compositionId}/publish` with a Firebase ID token.
5. FastAPI verifies the token, verified email, ownership, and current generated files.
6. The backend loads the authoritative composition and profile from Firestore.
7. If usable profile values are unavailable, it uses `SoundSight Musician` and an empty image URL.
8. The backend calculates the next published version.
9. It copies the private PDF, MusicXML, MIDI, and MP3 into public version paths.
13. Firestore receives the current post and the new immutable version document in one batch.
14. The backend returns the post ID, version, and public file paths.
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

Generated MusicXML and PDF files are written to a unique temporary system folder for each publish request.

If the composition ID is empty, the MusicXML file is named `composition.musicxml`.

Publishing does not create temporary score files. It copies the current private generated objects into immutable public version paths.

## Private composition file generation

The private composition generation route first writes the notation MusicXML:

1. music21 builds the score and writes one MusicXML file.
2. MuseScore reads that MusicXML and creates the PDF.
3. Manual compositions write MIDI directly from their stored measure, beat, duration, velocity, tempo, and tie data. Tied segments are combined into one sustained MIDI note.
4. Performance recordings write an exact MIDI from the captured microsecond timing.
5. MuseScore creates the MP3 from the resulting manual or performance MIDI, and FFmpeg trims it to the MIDI ending.
6. The MusicXML, PDF, MIDI, and MP3 are uploaded together.

The exact performance MIDI is kept separate from notation layout because readable MusicXML must spell notes and rests using supported rhythmic values. The MIDI and MP3 therefore share the captured performance timeline, while MusicXML and PDF remain the readable notation representation.

Manual MusicXML keeps ordinary tuplets such as `3:2` triplets. If music21 creates an unsupported filler-rest ratio whose normal-note count is not a power of two, the backend removes only that unstable tuplet markup before MuseScore opens the file. The numeric MusicXML duration remains unchanged. This prevents MuseScore from crashing on mixed triplet and straight-note timing while preserving the manual playback timeline.

Manual compositions may contain independent overlapping note layers. Notes
with the same start and duration become a chord. Other genuine overlaps are
assigned automatically to separate MusicXML voices on their treble or bass
staff, with rests filling each voice's unused time. The stored note schema and
the exact manual MIDI timeline remain unchanged.

Successful private generation stores `generatedFilesVersion: 2`. The backend and Flutter client require the current version before treating generated files as ready. Older documents without this field or with version 1 are shown as needing an update and can be regenerated through the existing composition UI. Regeneration overwrites the existing files at the same Firebase Storage paths.

For performance recordings, the backend recalculates the ending from the final matched Note Off. The MIDI end-of-track uses that ending and remains authoritative for Sight Reading timing. After MuseScore renders the MP3, FFmpeg trims it to the MIDI ending and applies a 5 ms fade so recording-stop silence, piano release, and reverb do not extend the preview.

### Performance-based recordings

Recording schema version 1 uses `performanceNotes` as its authoritative source. The exact MIDI writer maps captured microseconds to 960 ticks per quarter note, which keeps timing within approximately 2 ms even at the slowest supported tempo. It preserves velocity and assigns overlapping repetitions of the same key to separate piano channels. Tempo detection prioritizes Note On intervals and chooses the readable interpretation among similarly accurate candidates. The notation writer uses balanced 16th-note resolution, closes very small gaps, assigns genuine overlaps to MusicXML voices, groups equal start/end values into chords, and splits notes crossing bar lines with ties.

Both treble and bass staves are retained. MIDI 60 and above is written to treble and MIDI 59 and below is written to bass; an unused staff remains visible with rests. MuseScore creates the PDF from MusicXML and renders the MP3 from the exact MIDI, so playback and Sight Reading timing remain synchronized.

Private generation uses `POST /compositions/{compositionId}/generate`. The client sends a Firebase ID token as a bearer token. The backend verifies the token, requires a verified email, checks that the authenticated UID owns the private composition, and loads the musical data directly from Firestore. The request does not accept client-supplied musical data.

## Permanent Firebase information

### Firebase Storage

Each published version contains:

- `published_compositions/{ownerId}/{compositionId}/version_{versionNumber}.{pdf,musicxml,mid,mp3}`.

Private generated PDF, MusicXML, MIDI, and MP3 uploads include a Firebase Storage download token. This allows Firebase download URLs and the Firebase Console download action to access the generated objects. Regeneration replaces each private object and assigns it a new token.

Older version files remain available until the composition is unpublished.

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
- `publishedFilesVersion`;
- `pdfStoragePath`;
- `musicXmlStoragePath`;
- `midiStoragePath`;
- `mp3StoragePath`;
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

Verified clients can read published composition files. Storage Rules deny direct client writes and deletes under `published_compositions`.

The backend uses Firebase Admin, so it bypasses those rules.

Publish and unpublish verify a Firebase ID token, require a verified email, and use the authenticated UID to load or validate the owned composition.

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

1. The Flutter client sends `DELETE /compositions/{compositionId}/publish` with a Firebase ID token and a one-minute timeout.
2. The backend reads `compositionPosts/{compositionId}`.
3. A missing post returns `404`.
4. An owner mismatch returns `403`.
5. All versioned PDF, MusicXML, MIDI, and MP3 files under the composition's public Storage folder are deleted.
6. A legacy PDF at `published_compositions/{ownerId}/{compositionId}.pdf` is also deleted if present.
7. Every version's likes and comments are deleted.
8. Every version document is deleted.
9. Every `savedCompositionPosts` document whose `postId` matches the composition is deleted.
10. The current post is deleted.

Unpublishing does not delete the owner's private `users/{ownerId}/compositions/{compositionId}` document. Publish requests leave no generated local files after they finish.

## Failure and retry behavior

Publishing has no transaction covering local generation, Storage upload, and Firestore writes together. A failure after the Storage upload can leave an uploaded PDF behind. Temporary local files are removed when the request ends.

The two Firestore writes for the current post and version document are committed in one Firestore batch.

There is no pause, resume, skip, or expiration behavior. Retrying publishes again using the version found in the current Firestore post.

Unpublishing performs multiple deletions without one transaction. If a later deletion fails, earlier deletions are not restored automatically.

## Simple example

If a composition with ID `song123` is published for the first time by `userA`:

- its PDF is stored at `published_compositions/userA/song123/version_1.pdf`;
- its current post is `compositionPosts/song123`;
- its version is `compositionPosts/song123/versions/1`;
- publishing it again normally creates `version_2.pdf` and version document `2` while updating the current post to version 2.
