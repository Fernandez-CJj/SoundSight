# Composition Feature Reference

This document describes the Composition feature as it currently works. It covers private compositions, the editor, playback, publishing, public versions, likes, comments, and saved sheets.

## 1. Purpose

The Composition feature lets a signed-in user:

- create a piano composition;
- enter notes and chords with a virtual piano;
- arrange notes inside measures;
- listen to the composition;
- save a private editable copy;
- publish a generated music-sheet PDF;
- view, play, like, comment on, and save published versions; and
- unpublish a composition they own.

The feature does not currently calculate a score, level, grade, or completion status.

## 2. Complete user flow

### Opening the feature

The user can open **Composition** from the home screen or drawer. This opens **My Compositions**.

The drawer also has separate entries for:

- **Published Compositions**; and
- **Saved Compositions**, displayed as **Saved Sheets** on its screen.

All composition data screens require a signed-in Firebase user. A signed-out user sees a sign-in message instead of composition data.

### Creating a composition

1. The user taps **New Composition**.
2. The user chooses **Manual** or **Recording**.
3. Both methods request a title, key signature, and time signature.
4. Manual composition also requests tempo and opens the editor.
5. Recording composition detects tempo and measure count from the captured MIDI performance.
6. Nothing is saved until the editor saves or the recorder confirms generation.

The default values are:

- tempo: `80 BPM`;
- key: `C Major`;
- time signature: `4/4`;
- measure count: `1`; and
- no notes.

### Performance recording

New recorded compositions store `recordingSchemaVersion: 1`, `performanceNotes`, and `performanceDurationUs`. Each performance note keeps its MIDI number, velocity, microsecond start time, and microsecond held duration. The first Note On becomes time zero and the final matched Note Off becomes the ending, so idle time around the performance is removed.

The backend creates readable MusicXML/PDF notation from those notes and writes an exact MIDI directly from their captured timing. The score uses balanced 16th-note resolution and a tempo chosen to favor ordinary quarter, eighth, and dotted values. The MP3 is rendered from that MIDI, trimmed to the final matched Note Off, and finished with a 5 ms fade, so the Listen preview and Sight Reading timing follow the same performance without recording-stop silence or an added reverb tail. The detected tempo only controls notation layout and does not move the captured Note On or Note Off times.

Tempo is detected between 40 and 200 BPM for readable notation, with an 80 BPM fallback for sparse performances. Detection never moves the captured note times. Measure count is calculated from the detected tempo, selected meter, and trimmed duration.

The silent camera video is temporary review media. It can be played in the completion dialog and is deleted after success, Record Again, finishing a failed generation, or leaving the recorder. It is never uploaded.

The recorder warns at 240 notes and at 90 percent of its duration limit. It stops accepting Note On events at 256 notes, waits for held keys to be released, and then stops. Empty performances cannot be generated.

### Editing music

The editor lets the user:

- choose a note duration;
- choose note velocity, which controls how strongly the note sounds;
- choose an octave and tap a virtual piano key;
- select one or more existing notes;
- change a selected note's pitch, duration, velocity, or position;
- add notes at the current cursor position;
- enable Chord Mode to place several notes at the same starting beat;
- enable Layer Notes to enter an independent line while another note keeps
  sounding;
- insert a rest by moving the cursor forward without creating a note;
- move the cursor backward or forward;
- add, insert, duplicate, move, or delete measures;
- clear the notes from the remaining measure when a composition has only one
  measure, while keeping that blank measure available for new input;
- copy and paste notes;
- select all notes;
- tie a note to the immediately following note of the same pitch;
- delete selected notes or a whole chord;
- undo or redo up to 100 editor changes;
- change the title, tempo, key, or time signature through settings;
- show or hide the full-song overview; and
- play the composition before saving it.

Layer Notes can start from a selected note or the current cursor. Each new
virtual-piano note advances the layer cursor by that note's duration. With a
MIDI piano connected, the played key or chord supplies the duration and the
layer cursor advances by that captured step. Different pitches may overlap,
but the same piano key cannot overlap itself. Chord Mode and Layer Notes are
mutually exclusive.

The duration selector remains visible while a MIDI piano is connected. Its
default Automatic option converts the longest held key in a MIDI step to the
nearest supported written duration. Choosing a fixed duration instead ignores
the held time and assigns that duration to every note in the entered MIDI
chord. Note Off events are still used to determine when the complete chord has
been released. The fixed choice remains active until the user chooses another
duration or returns to Automatic, and it is not stored with the composition.

Changing the time signature can move or resize note timing. The change is rejected if the converted notes cannot fit correctly or would overlap the same piano key.

Playback controls include:

- volume;
- play from the current cursor;
- loop the selected measure;
- sustain; and
- metronome.

### Saving a private composition

The user must tap **Save Composition**. There is no autosave.

- If the composition has no ID, the app creates a new Firestore document.
- If it already has an ID, the app updates that document.
- After a successful save, the editor closes and returns to the previous screen.
- **My Compositions** updates through a live Firestore stream.

If the user tries to leave with unsaved changes, the app asks whether to keep editing or discard the changes.

### Managing private compositions

From **My Compositions**, the user can:

- play or stop a composition directly from its card;
- open its details;
- edit it; or
- delete it after confirming.

The details screen shows its musical settings, note and measure counts, estimated duration, dates, playback controls, and actions.

Deleting a private composition removes its PDF, MusicXML, MIDI, and MP3 files from `composition_files/{ownerId}/{compositionId}` before deleting `/users/{ownerId}/compositions/{compositionId}`. It does not automatically remove an already published post or its public version files. Publishing and unpublishing are separate actions.

### Publishing

Publishing is available from the private composition's details screen.

1. The composition must contain at least one note.
2. The user confirms the publish dialog.
3. The Flutter app sends the composition ID and Firebase authorization to `POST /compositions/{compositionId}/publish` on the Python backend.
4. The backend reads the user's public username and profile image.
5. The backend verifies that the private PDF, MusicXML, MIDI, and MP3 are current.
6. It copies those exact files into immutable public version paths.
7. The backend creates or updates the public post and creates a numbered version document.

The backend address for the app is configured in `lib/constants/backend_config.dart` and defaults to the PC's current LAN IPv4 address on port 8000. Publishing has a two-minute request timeout.

### Republishing and versions

The public post ID is the same as the private composition ID.

When the same composition is published again:

- the backend reads the public post's `currentVersion`;
- it adds `1` to get the new version number;
- the top-level post is updated to describe the newest version; and
- a new version document and public PDF, MusicXML, MIDI, and MP3 are created.

Older version documents and files remain available until the composition is unpublished.

Likes, comments, and saved bookmarks belong to a specific version, not to every version of the composition.

### Using published compositions

The **Published Compositions** screen shows the newest public posts first. A card lets the user:

- play or stop the current version;
- open its PDF music sheet;
- like or unlike that version;
- open its comments;
- save or remove that version from Saved Sheets; and
- unpublish it if the current user owns it.

The PDF viewer downloads at most 20 MB from Firebase Storage. If loading fails, the user can tap **Try Again**.

The viewer has two different play controls:

- The app-bar play button plays or stops the published composition audio.
- The large **Play** button opens a choice between Sight Reading and Synthesia.

Choosing **Sight Reading** opens the selected immutable published version. Choosing **Synthesia** opens `SynthesiaScreen`, but the selected published composition is not passed to that screen.

### Comments

Comments are shown oldest first.

- A comment can contain 1 to 500 characters after spaces are removed from its beginning and end.
- The app copies the current username and profile image URL into the new comment.
- If the username is missing, it uses `SoundSight Musician`.
- A user can delete their own comment.
- The owner of the published composition can also delete comments on that composition.

### Saved Sheets

Saving a sheet creates a bookmark for one exact published version. It does not copy the private composition and does not create another PDF.

Saved Sheets are ordered by the time they were saved. The app reads each saved version document separately. A bookmark is skipped if its referenced version no longer exists.

### Unpublishing

Only the owner is shown the unpublish action in the app.

After confirmation, the app sends authenticated `DELETE /compositions/{compositionId}/publish` to the backend. The request has a one-minute timeout.

The backend removes:

- every stored PDF for that published composition;
- every version document;
- every like under every version;
- every comment under every version;
- every Saved Sheets bookmark that points to the post; and
- the top-level public post.

Unpublishing does not delete the private composition in `/users/{ownerId}/compositions/{compositionId}`.

## 3. Temporary local information

Temporary information exists only while its screen or service is running. It is not automatically saved to Firebase.

### New Composition screen

- entered title and tempo;
- selected key and time signature; and
- whether the editor is currently opening.

### Composition editor

- the working note list before Save is tapped;
- current measure and insertion beat;
- selected note or selected group;
- selected duration, velocity, and octave;
- active chord position;
- copied notes in the editor clipboard;
- undo and redo history, limited to 100 snapshots;
- title, tempo, key, and time-signature edits that have not been saved;
- whether there are unsaved changes;
- volume, loop, sustain, metronome, and play-from-cursor settings; and
- playback state and currently highlighted notes.

The editor clipboard and undo history disappear when the editor closes.

### Other composition screens

- which composition is playing;
- playback position and duration;
- loading, deleting, saving, publishing, unpublishing, liking, commenting, and bookmarking flags;
- the unfinished comment text; and
- the PDF download result while the viewer is open.

### Temporary audio files

Before playback, the app mixes the required piano samples into a WAV file under the device's temporary `soundsight_compositions` directory. Rendered files are cached during that playback service's life and are deleted when the service is disposed, with the operating system also allowed to clear them.

The renderer refuses audio longer than 10 minutes.

## 4. When information is saved permanently

### Private composition

A private composition is saved only when the user taps **Save Composition** and all client validation passes.

Creating a composition saves it for the first time. Later saves update the same document.

### Public composition

Public data is saved only after the backend successfully generates and uploads the sheet and commits the Firestore post and version documents.

### Social information

- A like is saved when the user taps the heart button.
- A comment is saved when the user sends valid comment text.
- A Saved Sheets bookmark is saved after the user confirms Save.
- Repeating Like or Save deletes the existing like or bookmark instead.

## 5. Firebase and backend paths

| Information | Path |
| --- | --- |
| Private editable composition | `/users/{ownerId}/compositions/{compositionId}` |
| Public post describing the newest version | `/compositionPosts/{compositionId}` |
| One immutable published version | `/compositionPosts/{compositionId}/versions/{versionNumber}` |
| One user's like on a version | `/compositionPosts/{compositionId}/versions/{versionNumber}/likes/{userId}` |
| Comment on a version | `/compositionPosts/{compositionId}/versions/{versionNumber}/comments/{commentId}` |
| Saved-version bookmark | `/savedCompositionPosts/{userId}_{compositionId}_{versionNumber}` |
| Published files | `published_compositions/{ownerId}/{compositionId}/version_{versionNumber}.{pdf,musicxml,mid,mp3}` |
| User theme and public profile source | `/users/{userId}` |
| Publish endpoint | `POST /compositions/{compositionId}/publish` |
| Unpublish endpoint | `DELETE /compositions/{compositionId}/publish` |

The backend copies current private generated files into immutable public version paths. The private files remain owner-only and are not modified by publishing.

## 6. Created and updated fields

### Private composition document

The first save creates:

- `ownerId`;
- `title`;
- `key`;
- `tempo`;
- `beatsPerMeasure`;
- `beatUnit`;
- `measureCount`;
- `notes`;
- `createdAt`; and
- `updatedAt`.

Each item inside `notes` contains:

- `noteId`;
- `pitch`;
- `octave`;
- `midiNumber`;
- `measureIndex`;
- `startBeat`;
- `durationBeats`;
- `velocity`; and
- `tieToNext`.

New recording documents instead use an empty legacy `notes` list and add:

- `recordingSchemaVersion: 1`;
- `performanceDurationUs`; and
- `performanceNotes`, containing `midiNumber`, `velocity`, `startTimeUs`, and `durationUs`.

Older recording documents without the schema version continue using their legacy `notes` data.

A later save updates all musical fields and `updatedAt`. It does not change `ownerId` or `createdAt`.

### Top-level public post

Publishing creates or replaces these fields:

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
- `pdfStoragePath`; and
- `publishedAt`.

Republishing updates this document to the newest version.

### Published version document

Each new version creates the same public fields, plus:

- `versionNumber`; and
- `notes`, using the same stored note fields as the private composition.

The app does not edit an existing version document. It creates the next numbered version.

### Like document

Created fields:

- `userId`; and
- `createdAt`.

Likes are never updated. They are created or deleted.

### Comment document

Created fields:

- `userId`;
- `username`;
- `profileImageUrl`;
- `text`; and
- `createdAt`.

Comments are never edited. They are created or deleted.

### Saved Sheets bookmark

Created fields:

- `userId`;
- `postId`;
- `versionNumber`; and
- `savedAt`.

Bookmarks are never updated. They are created or deleted.

## 7. Client-side validation

The Flutter app validates a private composition before saving or playing it.

### Composition rules in the app

- The user must have an owner ID.
- Title length must be 1 to 80 characters.
- The key must be one of the supported major or minor keys.
- Tempo must be from 40 to 200 BPM.
- The time signature must be one of the supported choices.
- Measure count must be from 1 to 128.
- Note count cannot exceed 256.

Supported time signatures are:

- `2/4`, `3/4`, `4/4`, `5/4`, `6/4`, and `7/4`;
- `3/8`, `6/8`, `9/8`, and `12/8`.

### Note rules in the app

- Every note must have a non-empty, unique ID.
- Every note must be inside the 88-key piano range, MIDI `21` through `108`.
- Stored pitch and octave must agree with the MIDI number.
- The measure index must point to an existing measure.
- Start beat cannot be negative.
- Duration must be greater than zero.
- A note cannot extend beyond its measure.
- Velocity must be from `0` to `1`.
- The same piano key cannot overlap itself in one measure.
- A tied note must have the same pitch beginning exactly when it ends.

Editor operations apply these rules before changing the working note list. A rejected action shows a message and leaves the existing notes unchanged.

### Publishing validation

The details screen requires at least one note before publishing. The Python request model also checks basic ranges for tempo, measures, octave, MIDI number, start beat, duration, and velocity.

The backend's request validation is not as detailed as the Flutter composition validation. For example, the Flutter app is responsible for checking unique note IDs, matching pitch information, overlap, supported keys, and valid ties before normal publishing.

## 8. Firestore and Storage Rules protection

### Private compositions

Firestore Rules require authentication and enforce that:

- a new document's `ownerId` equals the signed-in user's ID;
- only the owner can read or delete it;
- only the existing owner can update it;
- `ownerId` and `createdAt` cannot be changed during an update;
- server timestamps are used for creation and updates;
- only the expected top-level fields are stored; and
- title, tempo, time signature, measure count, and note-count limits are valid.

The Rules check that `notes` is a list with at most 256 items, but they do not validate every field inside each note. The more detailed note validation currently happens in the Flutter app.

### Public posts and versions

Any authenticated user can read public post and version documents.

Client-side create, update, and delete operations are denied for public posts and versions. The trusted backend uses the Firebase Admin SDK to create and remove them, so these client Firestore Rules do not restrict the backend.

### Likes, comments, and saved bookmarks

Firestore Rules require authentication and enforce that:

- a like document belongs to the signed-in user and uses that user's ID as its document ID;
- only that user can remove the like;
- a comment belongs to the signed-in user, has only the expected fields, contains 1 to 500 characters, and uses a server timestamp;
- comments cannot be edited;
- a comment can be deleted by its author or the public post's owner;
- a bookmark belongs to the signed-in user, has a positive version number, and uses a server timestamp;
- bookmarks cannot be updated; and
- users can list and delete only their own bookmarks.

### Published composition files

Firebase Storage Rules allow verified users to read published PDF, MusicXML, MIDI, and MP3 files. Direct client creation, update, and deletion are denied. The backend performs those actions with Admin access.

### Current backend authorization boundary

Flutter sends a Firebase ID token for publishing and unpublishing. The backend requires a verified account, uses the authenticated UID to load the private composition, and confirms ownership before performing Admin SDK operations.

## 9. How musical results are calculated

### Piano notes

The virtual piano uses the standard 88-key MIDI range:

- MIDI `21` is A0;
- MIDI `60` is C4; and
- MIDI `108` is C8.

The pitch name and octave are derived from the MIDI number.

### Note timing

Note start positions and durations are rounded to the nearest `1/12` of a beat. This supports common straight, dotted, and triplet timing while avoiding tiny decimal differences.

An absolute note position is calculated as:

```text
absolute beat = measure index × beats per measure + start beat
```

### Chords and rests

Notes in the same measure with the same start beat are treated as a chord in the editor.

When the backend generates a sheet, notes are placed into one printed chord only when they have the same start beat and duration. Empty spaces before, between, and after notes are generated as written rests. Pressing **Insert Rest** in the editor therefore moves the cursor; it does not store a separate rest object in Firestore.

### Playback speed and duration

The duration of one stored beat is calculated from the tempo and beat unit:

```text
microseconds per beat = 60,000,000 ÷ tempo × (4 ÷ beat unit)
```

The details screen estimates the full written duration as:

```text
total beats = measure count × beats per measure
duration = total beats × beat length × 60,000 ÷ tempo
```

Playback mixes the piano WAV samples for all notes into one temporary 44,100 Hz WAV file. Velocity changes each note's volume. Tied notes of the same pitch are joined into one longer sound span.

### Published version number

```text
new version = currentVersion + 1
```

If no public post exists, `currentVersion` starts at `0`, so the first published version is `1`.

## 10. Skip, resume, expiration, failure, and retry behavior

### Skip

There is no feature-wide Skip action.

- Inserting a rest skips forward by the selected duration without storing a note.
- Published Sight Reading opens the selected immutable version document.

### Resume

- Paused audio can be resumed while the same screen and playback service remain open.
- A previously saved private composition can be reopened and edited later.
- Unsaved editor work cannot be resumed after it is discarded or the screen is closed.
- Playback position is not permanently saved.

### Expiration

Private compositions, published versions, likes, comments, and Saved Sheets bookmarks have no automatic expiration in the current code.

### Failure

The app shows a message when saving, deleting, playback, publishing, unpublishing, liking, commenting, bookmarking, or loading data fails. Failed writes leave the user on the current screen when possible.

The app does not queue failed writes for automatic retry.

### Retry

- The PDF viewer has an explicit **Try Again** button.
- Other failed actions can be retried by tapping their action again.
- Firestore list screens use live streams and update again when Firebase provides a new snapshot.

## 11. What happens after completion

### After saving

The editor closes, returns the saved composition ID, and the previous screen shows a success message. The live private-composition list reflects the created or updated document.

### After publishing

The user remains on the details screen and sees a success message. The public list updates from Firestore. Republishing makes the new version the current public version.

### After deleting a private composition

The private document disappears from My Compositions. Any separately published post remains until it is unpublished.

### After unpublishing

The public post, all versions, version-specific social data, Saved Sheets references, and published files are removed. The private editable composition remains.

## 12. Simple example

Suppose Ana creates **Morning Theme** in `4/4`, adds four quarter notes, and taps Save.

1. Firestore creates `/users/anaUid/compositions/abc123` with the musical fields, four note maps, `createdAt`, and `updatedAt`.
2. Ana can close the app and later reopen this private composition because it was saved permanently.
3. Ana publishes it. The backend creates version `1`, uploads `version_1.pdf`, and writes:
   - `/compositionPosts/abc123`; and
   - `/compositionPosts/abc123/versions/1`.
4. Ben likes and saves version `1`. His like is stored under version `1`, and his Saved Sheets bookmark also records version `1`.
5. Ana edits the private composition and publishes again. The public post now points to version `2`, while version `1` still exists.
6. Ben's saved item still opens version `1`, because bookmarks keep the exact saved version number.
7. If Ana unpublishes the composition, both public versions, their PDFs, likes, comments, and bookmarks are deleted. Ana's private `/users/anaUid/compositions/abc123` document remains editable.
