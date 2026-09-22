# AR Practice Feature Reference

This document describes the AR Practice feature as it currently works. Camera calibration itself is described separately in `PIANO_CALIBRATION_REFERENCE.md`.

## 1. Purpose

AR Practice places falling note blocks over a live camera view of a real piano.

It uses:

- a MIDI score stored through a challenge document;
- a previously saved map of the user's visible piano keys;
- the phone's rear camera; and
- a connected MIDI keyboard for performance input.

The feature supports continuous Performance Mode and step-by-step Wait Mode. Its result is displayed at the end but is not saved as challenge progress and does not award XP.

## 2. Complete user flow

### Opening AR Practice

1. The user selects a challenge item.
2. The user taps **AR Practice**.
3. The AR screen receives the score path `/challenge_items/{challengeItemId}`.
4. It watches the signed-in user's saved piano calibrations in Firestore.
5. Calibrations are shown with their names and most recent saved dates.

If there are no calibrations, the screen explains that one must be created. The user can tap **Create calibration** or the **New calibration** floating button.

Creating a calibration opens the camera calibration workflow without loading the challenge score. After saving and returning, the live list displays the new calibration. The user must then select it.

### Selecting a saved calibration

1. The user taps a saved calibration.
2. Other calibration tiles are disabled while loading.
3. The app loads the calibration's complete key geometry.
4. It reads `midiUrl` from the selected challenge document.
5. It downloads the MIDI file through HTTP.
6. It validates and converts the MIDI bytes into timed note events.
7. The app opens the shared Piano Calibration screen with both the saved calibration and score timeline.
8. The rear camera opens in landscape orientation.
9. The saved key map is restored over the current camera frame.

### Reviewing the mapping

The user can choose:

- **Recalibrate**, which detects and maps the piano again and updates the same saved calibration when saved; or
- **Use**, which tries to begin AR practice.

Before practice starts, every distinct MIDI pitch in the score must exist in the calibrated key map. If any key is missing, the app lists the missing notes and asks the user to use a wider calibration.

### Starting practice

After the calibration passes the range check:

1. Computer-vision frame processing stops, but the live camera preview remains.
2. The app prepares the falling-note animation with a four-second approach period before the first score note.
3. The user connects a MIDI device. The current connection action uses the first device returned by the MIDI service.
4. The user starts playback.
5. Falling blocks travel toward a perspective-aware hit line above the piano keys.
6. MIDI Note On messages are compared with the expected score groups.

Notes beginning at exactly the same score time are treated as one group. A group may contain one note or a chord.

### Performance Mode

Performance Mode is the default. The score moves continuously.

- A played pitch is matched to the closest pending group inside a 300-millisecond early-or-late window.
- All pitches in a chord must be attacked within 200 milliseconds.
- A correct pitch outside the timing window becomes a timing mistake.
- An unexpected pitch becomes a wrong note.
- A group not played before its window closes becomes missed.
- Correcting a group after making a mistake does not restore it to a fully correct result.

### Wait Mode

Wait Mode stops at each group until its expected pitches are newly pressed and held.

- A correct single note completes its group.
- Every required chord pitch must be held.
- Chord attacks must occur within 200 milliseconds.
- An unexpected Note On is recorded as a mistake.
- Extra notes that were already held do not prevent the required group from completing.

Switching between modes asks for confirmation and resets the current attempt.

### Completing practice

When all groups are evaluated, a non-dismissible dialog shows:

- mode;
- Accuracy;
- Correct;
- Wrong;
- Missed; and
- Mistakes.

**Retry** resets the attempt and plays the same score again. **Done** closes the practice screen.

## 3. Temporary local information

The AR selection screen temporarily stores:

- the live saved-calibration stream;
- which calibration is currently loading; and
- the downloaded and parsed score timeline while opening practice.

The practice screen temporarily stores:

- restored keyboard corners, key markers, and key outlines;
- MIDI note events, start times, and durations;
- the connected MIDI state and currently held notes;
- current animation time, pause state, and selected mode;
- the current Wait Mode target and note-attack times;
- each group's correct, timing-mistake, or incorrect result;
- Correct, Wrong, Missed, and Mistakes counters; and
- the latest feedback message and color.

All practice attempt information disappears when the screen closes. Retry also clears these attempt values.

## 4. When information is saved permanently

AR performance results are never saved permanently in the current code.

The only permanent write available from this flow is piano calibration:

- creating a calibration creates a document; and
- recalibrating a loaded calibration updates its existing document.

The challenge score documents and MIDI files are read-only from this feature.

## 5. Firebase and network paths used

| Information | Path or source |
| --- | --- |
| Selected challenge score | `/challenge_items/{challengeItemId}` |
| Saved calibration | `/users/{userId}/pianoCalibrations/{calibrationId}` |
| MIDI file | HTTP address stored in the challenge's `midiUrl` field |

The app does not use a Firebase Storage API directly in the AR folder. It downloads the supplied `midiUrl` as a normal HTTP address.

## 6. Fields read, created, and updated

### Challenge document

AR Practice reads:

- `midiUrl`.

It does not create or update challenge fields.

### Calibration documents

The selection list reads:

- document ID;
- `name`;
- `createdAt`; and
- `updatedAt`.

After selection, the app loads the saved corners, aspect ratio, piano-key markers, key outlines, name, and schema version. Creating or recalibrating these fields is handled by the Piano Calibration feature.

### Practice results

No result document or result fields are created or updated.

## 7. Client-side validation

### Score path and download

- The score document path cannot be empty.
- The score document must exist and contain data.
- `midiUrl` must be a non-empty string.
- The URL must parse and contain a scheme.
- The HTTP response must have status `200` and contain bytes.

### MIDI parsing

- The file must have a Standard MIDI `MThd` header.
- Only MIDI file formats `0` and `1` are accepted.
- At least one track and a valid time division are required.
- Track boundaries, event lengths, running status, and MIDI data bytes are checked.
- Both ticks-per-quarter and SMPTE timing are supported.
- Channel 10 percussion events are ignored.
- The file must contain at least one usable pitched note.

The parser shifts timeline zero to the first playable note, removes exact duplicate note events, and gives a malformed zero-length note a minimum duration of 80 milliseconds.

### Calibration and practice

- A saved calibration must pass its schema and geometry checks.
- The score cannot be empty.
- Every score pitch must have a calibrated marker before practice can start.
- MIDI attacks are evaluated using the timing and chord windows described above.

## 8. Firestore Rules protection

Challenge items can be read by any authenticated user. Client creation, update, and deletion of challenge items are denied.

Piano calibrations can be created, read, updated, or deleted only when the signed-in user owns the `/users/{userId}` path.

The calibration Rules enforce ownership but do not validate the calibration's field structure. Calibration shape validation is performed by the Flutter code.

Because AR results are not written, there are no AR-result Rules.

## 9. How notes, animation, and results are calculated

### MIDI timing

For normal metrical MIDI timing, the parser begins with the standard default tempo of 120 BPM and applies tempo-change events as it converts ticks into microseconds.

Leading silence is removed:

```text
AR start time = note's absolute MIDI time - first note's MIDI time
```

Total score duration ends when the last parsed note ends.

### Falling-note placement

The calibrated note name and octave are converted into a MIDI number. That MIDI number connects each score note to one on-screen piano-key marker.

The hit line follows the keyboard's perspective and is placed 8% of the way from the bottom corners toward the top corners. Each note spends four seconds moving from the top of the screen to this line.

White-key notes are blue before evaluation. Black-key notes are pink. Results recolor the complete simultaneous group:

- green: correct;
- yellow: timing mistake; and
- red: incorrect or missed.

Result color can remain visible for 650 milliseconds after a short note passes the hit line.

### Group counts and accuracy

A chord counts as one group because its notes share one start time.

Only a group completed without any recorded mistake increases Correct. A group with a wrong or timing mistake increases Wrong when finalized. An untouched group increases Missed and Mistakes.

Only the first mistake for one group increases the Mistakes counter.

```text
accuracy = correct groups / total groups x 100
```

The percentage is rounded to a whole number.

## 10. Resume, failure, and retry behavior

### Resume

Saved calibrations can be reused in later sessions. An unfinished AR practice attempt cannot be resumed after leaving the screen.

Playback can be paused and resumed while the same practice screen stays open.

### Expiration

AR scores, calibrations, and local attempts have no expiration behavior in this folder.

### Failure and retry

- A calibration-list error shows **Try again**, which creates a fresh Firestore stream.
- A calibration or score load failure shows a message. The user can select the calibration again.
- A missing, unreachable, empty, or malformed MIDI file prevents practice from opening.
- A saved mapping that cannot be restored falls back to fresh calibration detection.
- A calibration missing required score pitches blocks practice and lists the missing pitches.
- Camera and MIDI connection failures are displayed inside the shared calibration/practice screen.
- **Retry** in the completion dialog resets the local attempt.

There is no automatic download, connection, or result-save retry queue.

## 11. What happens after completion

After practice ends, the user can retry the same local attempt or close the screen. No completion mark, XP, score, or history entry is saved.

Closing the calibration/practice screen disposes its camera, MIDI listeners, MIDI connection, and animation controller, then returns orientation to portrait.

Closing the AR selection screen closes its owned HTTP client.

## 12. Simple example

Suppose a score contains these events:

```text
0.0 seconds: C4 and E4
1.0 seconds: G4
```

1. The parser groups C4 and E4 together because they start at the same time.
2. The four-second visual lead-in begins before that chord reaches the hit line.
3. If the user presses C4 and E4 within 200 milliseconds of one another and within 300 milliseconds of the target, the chord group becomes green and Correct increases by one.
4. If G4 is never played, its group becomes red, Missed increases by one, and Mistakes increases by one.
5. The attempt has two total groups, not three individual notes.
6. With one correct group, Accuracy is `1 / 2 x 100 = 50%`.
7. These results disappear after the screen closes.

