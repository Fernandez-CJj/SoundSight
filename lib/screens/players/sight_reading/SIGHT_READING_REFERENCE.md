# Sight Reading Feature Reference

This document describes the Sight Reading feature as it currently works.

## 1. Purpose

Sight Reading displays a MusicXML score and checks notes played on a connected MIDI piano.

It supports:

- Wait Mode, where the score advances after the correct note or chord is played;
- Performance Mode, where the cursor follows the MIDI score's timing;
- listening to a piano-sample preview of the MIDI timeline;
- immediate correct, wrong, timing, and hint feedback; and
- permanent challenge completion with a one-time 20 XP award for a perfect Performance Mode attempt.

## 2. Complete user flow

### Opening the feature

Sight Reading has two current entry paths.

From a challenge item:

- the score path is `/challenge_items/{challengeItemId}`; and
- `challengeItemId` is provided, so a qualifying Performance Mode result can save completion and award XP.

From a fundamentals lesson:

- the score path is `/fundamentals_folders/{folderId}/lessons/{lessonId}`; and
- no challenge item ID is provided, so the lesson cannot award XP.

### Loading and displaying the score

1. The screen locks into landscape orientation.
2. It shows a non-dismissible score-loading dialog.
3. It reads the supplied Firestore score document.
4. It reads `musicXmlUrl` and `midiUrl`.
5. The MusicXML file is downloaded through HTTP.
6. A WebView loads OpenSheetMusicDisplay version `2.1.1` from jsDelivr.
7. OpenSheetMusicDisplay renders the score as one horizontal staff line and creates a green cursor.
8. The WebView counts playable score positions and reports the notes under the cursor to Flutter.
9. The MIDI file is downloaded separately and parsed into timed note-or-chord events.
10. The signed-in user's `skillLevel` is loaded to select the Performance Mode timing tolerance.

### Connecting MIDI

1. The user taps **Connect MIDI**.
2. The app requests the available MIDI devices.
3. If at least one exists, it connects to the first device in the list.
4. The status changes to the connected device's name.
5. The screen listens to both the current held-note set and individual Note On events.

### Wait Mode

The mode button can switch from the default Performance Mode to Wait Mode. Switching mode reloads and resets the exercise.

In Wait Mode:

1. The green score cursor shows the current note or chord.
2. The expected MIDI notes are read from the MusicXML cursor.
3. Every expected note must be newly pressed for the current step.
4. The held-note set must exactly equal the expected set. Extra held notes count as a mistake.
5. Chord notes must be attacked within 200 milliseconds.
6. A correct match advances the score cursor to the next playable position.
7. Five consecutive failed attempts reveal a text hint containing the expected note names.
8. Reaching the end opens the completion dialog.

If a hint appeared at any time, the result requires a retry and the **Done** button is hidden. Wait Mode never awards XP.

### Performance Mode

Performance Mode is the default.

1. The MIDI timeline, rendered score, and MIDI connection must be ready.
2. The user taps **Start**.
3. A visible countdown shows `3`, `2`, and `1`.
4. A stopwatch and 20-millisecond performance update timer begin.
5. The score cursor slides toward each next playable position according to the MIDI event times.
6. Note On messages are compared with the closest current event.
7. The final event is evaluated after its allowed late window.
8. The cursor is hidden and the completion dialog opens.

Timing tolerance depends on the saved skill level:

- Beginner: 400 milliseconds early or late;
- Intermediate or an unrecognized level: 300 milliseconds; and
- Advanced: 200 milliseconds.

If loading the user or skill level fails, Beginner tolerance is used.

Every chord uses a separate 200-millisecond limit between its first and last note attacks.

### Listening to the score

The **Listen** button plays the parsed timeline with the app's piano samples.

- MIDI input is ignored while preview preparation or playback is active.
- The preview stops if the user taps **Stop**.
- Individual score notes without samples are skipped.
- Playback fails if none of the score pitches has an available piano sample.
- The preview ends 800 milliseconds after the last scheduled attack.

### Completion

The dialog shows the score, result message, time information, and XP status.

Performance Mode also shows:

- Correct on time;
- Wrong;
- Missed; and
- Timing accuracy.

The user can tap **Retry**. **Done** closes the screen unless Wait Mode displayed a hint and therefore requires a retry.

## 3. Temporary local information

The screen and its helpers keep these values only in memory:

- downloaded MusicXML text;
- the parsed MIDI timeline and calculated duration;
- the expected notes under the current score cursor;
- currently held MIDI notes and individual Note On events;
- MIDI connection status;
- current mode and completion state;
- loading, countdown, preview, and performance-running flags;
- stopwatch time and timer objects;
- total and completed score positions;
- per-position note presses and chord press times;
- consecutive and total Wait Mode mistakes;
- whether a hint appeared;
- per-event Performance Mode attempts;
- Correct, Wrong, Missed, and timing counts; and
- cursor position, color, and slide queue.

Retry resets the attempt counters, cursor, timers, held notes, and score rendering. Leaving the screen discards all unsaved attempt information.

## 4. When information is saved permanently

Information is saved only when all of these conditions are true:

- the screen was opened from a challenge item and therefore has a `challengeItemId`;
- Performance Mode was used;
- the timeline contains at least one event;
- every event was correct on time;
- Wrong is zero; and
- Missed is zero.

The app then runs one Firestore transaction that:

1. checks whether the challenge was already completed;
2. creates the completion document if it is new; and
3. adds 20 to the user's `experiencePoints`.

The same challenge awards XP only once. Wait Mode, imperfect Performance attempts, and fundamental lessons do not save completion or XP.

## 5. Firebase and network paths used

| Information | Path or source |
| --- | --- |
| Challenge score | `/challenge_items/{challengeItemId}` |
| Fundamental lesson score | `/fundamentals_folders/{folderId}/lessons/{lessonId}` |
| User skill level and XP | `/users/{userId}` |
| Saved challenge completion | `/users/{userId}/challenge_progress/{challengeItemId}` |
| MusicXML file | HTTP address stored in `musicXmlUrl` |
| MIDI file | HTTP address stored in `midiUrl` |
| Sheet-rendering library | `opensheetmusicdisplay@2.1.1` from jsDelivr |

The Sight Reading folder downloads the supplied URLs with HTTP. It does not directly use the Firebase Storage API.

## 6. Created and updated fields

### Score document fields read

Sight Reading reads:

- `musicXmlUrl`; and
- `midiUrl`.

It does not create or update the score document.

### New challenge-progress document

A first perfect challenge completion creates:

- `challengeItemId`;
- `completed`, set to `true`;
- `mode`, set to `performance`;
- `correctCount`;
- `wrongCount`, which must be `0`;
- `missedCount`, which must be `0`;
- `totalCount`;
- `xpAwarded`, set to `20`; and
- `completedAt`, using a Firestore server timestamp.

Challenge-progress documents are never updated or deleted by the client.

### User document update

The same transaction updates:

- `experiencePoints`, incremented by `20`; and
- `updatedAt`, using a Firestore server timestamp.

If the progress document already says `completed: true`, neither document is changed and the result reports that XP was already awarded.

## 7. Client-side validation

### Source loading

- The supplied Firestore document must be readable.
- `musicXmlUrl` must be present.
- MusicXML download must return HTTP status `200`.
- OpenSheetMusicDisplay must load and render the MusicXML.
- The WebView ignores rests when counting and advancing between playable positions.

### MIDI timeline

- `midiUrl` must be non-empty for Performance Mode.
- MIDI download must return status `200`.
- The file must contain a valid `MThd` header and complete tracks.
- MIDI formats up to `2` are accepted by this Sight Reading parser.
- Standard tick timing and SMPTE timing are supported.
- Channel 10 percussion is ignored.
- Only positive-velocity Note On events become timeline targets.
- Notes occurring at the same MIDI tick are grouped as one event or chord.
- At least one playable event is required.

Unlike the AR parser, this parser uses Note On positions only. It does not need Note Off events or note durations.

### Performance target duration

The displayed target duration is the time from the first playable Note On to the last playable Note On, rounded to a whole second with a minimum display value of one second.

### Wait Mode note matching

- Expected notes cannot be empty.
- Held notes must exactly equal the expected set.
- Every expected note must have a new Note On during the current step.
- Chord attacks must be within 200 milliseconds.
- One held-note attempt adds at most one mistake until all keys are released or a correct match is completed.

### Perfect completion

Before saving, the progress service checks:

```text
totalCount > 0
correctCount == totalCount
wrongCount == 0
missedCount == 0
```

The user must also be signed in.

## 8. Firestore Rules protection

Challenge items and fundamental lessons can be read by authenticated users. Client creation, update, and deletion of those source documents are denied.

A user can read only their own challenge-progress collection.

Creating a challenge-progress document requires:

- an authenticated owner matching `{userId}`;
- an existing `/challenge_items/{challengeItemId}` document;
- exactly the allowed completion fields;
- the document ID and stored `challengeItemId` to match;
- `completed: true`;
- `mode: performance`;
- integer result values;
- a positive total;
- Correct equal to Total;
- Wrong and Missed equal to zero;
- exactly 20 XP; and
- a server completion timestamp.

Progress documents cannot be updated or deleted by the client. This prevents the same progress document from being rewritten for another award.

The user-document Rules require ownership for the XP update. However, they do not independently require an `experiencePoints` increase to be paired with a valid challenge-progress creation. The transaction performs that pairing in the normal app flow, but the user-document Rules themselves do not fully protect the XP calculation from a modified client.

## 9. How scores, hints, timing, and XP are calculated

### Wait Mode score

Wait Mode tracks:

- completed positions; and
- positions completed correctly on the first try.

```text
Wait score = first-try correct positions / completed positions
```

Once a mistake occurs at the current position, eventually correcting that position still advances the score, but it does not increase the first-try count.

Consecutive mistakes reset to zero after a correct position. At five consecutive mistakes, the expected-note hint appears. A flag remembers that a hint appeared anywhere in the attempt.

### Performance Mode score

MIDI notes at the same scheduled time form one event. Each event becomes one of the following when its timing window closes:

- Correct: every required pitch was played inside the timing window, chord timing passed, and no mistake was recorded;
- Wrong: a wrong pitch, early/late pitch, or badly timed chord affected the event; or
- Missed: no relevant attempt was made.

An event stays Wrong even if the correct notes are played after a mistake.

```text
timing accuracy = correct events / total events x 100
```

The percentage is rounded to a whole number.

For Performance Mode, the displayed total mistake count is:

```text
total mistakes = wrong events + missed events
```

### Progress bar

```text
progress = completed or evaluated positions / total positions
```

The value is limited between 0% and 100% and visually animates over 350 milliseconds.

### XP

A first perfect Performance Mode completion of a challenge item awards 20 XP.

```text
new experiencePoints = existing experiencePoints + 20
```

Replaying an already completed challenge awards zero additional XP.

## 10. Resume, failure, and retry behavior

### Skip and resume

There is no Skip action. Rests are skipped automatically when the WebView moves between playable score positions.

An unfinished exercise is not saved and cannot be resumed after closing the screen. A permanently completed challenge remains completed through its progress document.

### Expiration

Exercises and saved challenge completions do not expire.

### Retry

**Retry** stops score preview, cancels countdown and performance timers, resets the stopwatch and trackers, clears active notes, and renders the downloaded MusicXML again.

Switching modes runs the same reset. It does not ask for confirmation.

If a hint was shown in Wait Mode, Retry is mandatory because the completion dialog hides **Done**.

### Loading and playback failure

- A missing MusicXML URL displays a message instead of a score.
- A failed MusicXML download displays its HTTP status.
- A score-rendering failure shows a message and snackbar.
- When MusicXML was never downloaded, the Retry button remains disabled; reopening the screen is the available full load retry.
- A missing, failed, or malformed MIDI file leaves Performance Mode and Listen unavailable, but a successfully rendered MusicXML score can still be used in Wait Mode.
- MIDI connection failure changes the status to **Connection failed**. The user can tap Connect MIDI again.
- Score-preview failure shows a snackbar and returns the preview controls to idle.
- A failed perfect-progress transaction shows **Progress could not be saved. Please try again.** Retrying the exercise and completing it perfectly attempts the save again.

There is no automatic retry queue.

## 11. What happens after completion

After an ordinary Wait Mode or imperfect Performance Mode result, the user can retry or tap **Done** to return.

After Wait Mode uses a hint, the user must retry before the screen allows Done.

After a first perfect challenge Performance:

- the completion document is created;
- 20 XP is added to the user document; and
- the completion dialog displays `+20 XP`.

The challenge list watches the user's progress collection, so the item can display as completed after the saved result arrives.

After another perfect run of the same challenge, the dialog says that it was already completed and XP is awarded only once.

Closing the screen cancels MIDI subscriptions and timers, disposes MIDI and score-preview services, and restores portrait orientation.

## 12. Simple example

Suppose a challenge contains three MIDI events:

```text
0.0 seconds: C4
1.0 seconds: E4 and G4
2.0 seconds: C5
```

For an Intermediate user, each event has a 300-millisecond early-or-late window. The E4-G4 chord also requires both attacks within 200 milliseconds of each other.

If the user plays all three events on time without a wrong pitch:

- Correct is `3`;
- Wrong is `0`;
- Missed is `0`;
- Timing accuracy is `100%`; and
- a first completion creates the progress document and awards 20 XP.

If E4 and G4 are pressed 350 milliseconds apart, that event becomes Wrong even if both pitches are eventually held. The result is no longer perfect, so no progress document or XP is saved.
