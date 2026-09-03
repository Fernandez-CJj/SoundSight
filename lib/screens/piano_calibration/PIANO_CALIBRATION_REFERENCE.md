# Piano Calibration Feature Reference

This document describes the Piano Calibration feature as it currently works. It also explains the AR practice behavior that is built into the calibration screen.

## 1. Purpose

The feature uses the rear phone camera to find a visible piano keyboard and create a map of its keys.

The saved map contains:

- the four corners of the visible keyboard area;
- the name and position of every mapped white and black key; and
- the outline of every mapped key.

A saved map can later be restored and used to position falling notes over the real keys during AR practice.

The keyboard detector uses OpenCV image processing. It looks for the repeating groups of two and three black keys. It is not an AI model and it does not recognize the piano by training data.

## 2. Complete user flow

### Opening the feature

The current entry point is the AR Practice screen. It shows the signed-in user's saved calibrations, ordered by their most recent update.

The user can either:

- create a new calibration; or
- select an existing calibration for the chosen AR score.

### Creating a new calibration

1. The calibration screen locks into landscape orientation.
2. It opens the rear camera at the `high` resolution preset with audio disabled.
3. It processes at most one camera frame every 225 milliseconds.
4. The app searches five horizontal bands of the image for dark shapes that resemble black piano keys.
5. It checks whether the shapes form alternating groups of two and three black keys.
6. The visible pattern must contain at least four complete groups, representing two complete octaves.
7. The app asks the user to move farther back, clear the keyboard, or hold the phone steady when needed.
8. A result is accepted after similar black-key positions are found in five frames.
9. The app estimates a four-corner keyboard area and shows it over the camera preview.
10. The user can drag the four corners to correct the area.
11. The user taps **Confirm area**.
12. The user taps the real keyboard's Middle C key. The tapped location is treated as `C4`.
13. The app uses the black-key pattern and C4 reference to label the visible white and black keys.
14. It tries to refine white-key centers from visible seams. If the seams are unclear, it keeps the estimated centers.
15. The app draws the key names and outlines for review.
16. The user can return to **Adjust area**, or tap **Confirm mapping**.
17. The user enters a calibration name and taps **Save**.
18. The app converts pixel positions into fractions of the camera image and saves the mapping in Firestore.
19. After a successful save, the user can choose **Edit mapping** or **Done**.
20. **Done** returns to the previous screen.

### Using an existing calibration

1. The user selects a saved calibration from AR Practice.
2. The app loads the complete calibration and the selected score's MIDI timeline.
3. The calibration screen opens the rear camera.
4. The saved position fractions are converted into pixel positions for the current camera frame.
5. The restored key names and outlines appear over the preview.
6. The user can choose **Recalibrate** or **Use**.
7. **Recalibrate** starts keyboard detection again. Saving the replacement mapping updates the same calibration document.
8. **Use** checks whether the calibration contains every MIDI pitch required by the score.
9. If keys are missing, the app shows the required range, calibrated range, and missing notes. Practice does not begin.
10. If the range is complete, camera image analysis stops, but the live preview remains visible.
11. The user connects the first available MIDI device and starts practice.
12. Falling notes are aligned with the saved key markers.

### AR practice modes

**Performance Mode** lets the score move continuously. A note group is correct when the required pitches are played within the timing rules.

**Wait Mode** pauses at each note or chord until the required new notes are pressed and held. Extra already-held notes do not prevent completion of the target.

The user can pause, resume, restart, or switch modes. Switching modes requires confirmation and resets the current attempt.

At the end, the app shows Accuracy, Correct, Wrong, Missed, and Mistakes. **Retry** starts the local attempt again. **Done** closes the calibration/practice screen.

## 3. Temporary local information

The following information exists only while the screen is open:

- camera controller, camera error, and frame-processing status;
- the current detection guidance and stability-frame count;
- detected black-key candidates and groups;
- the four editable keyboard-area corners;
- the grayscale frame used to inspect white-key seams;
- the user's C4 tap position;
- generated key markers, note names, and outlines;
- save, restore, and error states;
- the selected saved calibration's ID and name;
- the connected MIDI device status and currently held MIDI notes;
- falling-note animation position and pause state;
- Performance Mode or Wait Mode selection;
- the current Wait Mode target and note-press times; and
- the current practice counts and accuracy.

Detection progress and an unfinished mapping are not automatically saved. If the user leaves before **Confirm mapping** finishes successfully, that work is lost.

AR practice results are also local only. This feature does not save its Accuracy, Correct, Wrong, Missed, or Mistakes values to Firebase.

## 4. When information is saved permanently

A calibration is saved only after all of these actions occur:

1. the keyboard area is confirmed;
2. C4 is selected and key outlines are generated;
3. the user taps **Confirm mapping**;
4. the user enters a valid name and taps **Save**; and
5. the Firestore write succeeds.

There is no autosave.

A new calibration creates a new Firestore document. Recalibrating a loaded calibration writes to its existing document and preserves its original `createdAt` value.

No calibration images or camera recordings are saved to Firebase Storage.

## 5. Firebase paths used

| Information | Path |
| --- | --- |
| One user's saved calibration | `/users/{userId}/pianoCalibrations/{calibrationId}` |

The saved-calibration list reads the same collection and orders documents by `updatedAt`, newest first.

The AR score is loaded from the document path supplied by the selected challenge. That score path belongs to the AR practice feature rather than the calibration document itself.

## 6. Created and updated fields

### New calibration document

The first successful save creates:

- `name` - the user-entered name after surrounding spaces are removed;
- `schemaVersion` - currently `1`;
- `sourceImageAspectRatio` - camera-frame width divided by height;
- `topLeft`, `topRight`, `bottomRight`, and `bottomLeft`;
- `pianoKeys`;
- `createdAt` - a Firestore server timestamp; and
- `updatedAt` - a Firestore server timestamp.

Each corner contains:

- `horizontalFraction`; and
- `verticalFraction`.

Each item inside `pianoKeys` contains:

- `noteLetter`, such as `C` or `F#`;
- `octaveNumber`;
- `isBlackKey`;
- `markerPosition`, containing horizontal and vertical fractions; and
- `outlinePoints`, containing at least three fraction-based points.

### Updating an existing calibration

Recalibration updates:

- `name`;
- `schemaVersion`;
- `sourceImageAspectRatio`;
- all four corners;
- `pianoKeys`; and
- `updatedAt`.

The save uses merge mode. It does not replace `createdAt` during an update.

## 7. Client-side validation

### Camera and automatic detection

- A rear camera must exist and initialize successfully.
- A frame is ignored while another frame is processing.
- Frames arriving sooner than 225 milliseconds after the last processed frame are skipped.
- Black-key candidates must have similar dimensions and bottom alignment.
- Their spacing must form alternating groups of two and three.
- At least two complete octaves must be visible.
- Similar candidates must be seen across five stable frames.

### Keyboard area and key mapping

- Dragged corners stay inside the camera image.
- The keyboard area cannot become smaller than 8% of the image width or height.
- A corner move must leave a convex four-sided area instead of a folded or crossed shape.
- Mapping cannot be saved without a keyboard area, a C4 reference, key markers, and key regions.
- The number of key markers must equal the number of key regions.
- Every marker must have a matching outline.
- Source image width and height must be greater than zero.
- Saved point positions are clamped between `0` and `1` while being created.

### Calibration name

- Surrounding spaces are removed.
- The name cannot be empty.
- The text field allows at most 50 characters.

### Loading saved data

- The user must be signed in.
- The calibration ID cannot be empty.
- The document must exist and contain data.
- `schemaVersion` must be `1`.
- The name must be a non-empty string.
- The source aspect ratio must be a number greater than zero.
- At least one piano key must exist.
- Required point values must be numbers.
- Every key must contain a name, octave, key type, marker position, and at least three outline points.

The loader checks that saved fractions are numeric, but it does not explicitly reject values outside `0` to `1`.

### Before AR practice

Every distinct MIDI pitch in the selected score must have a matching calibrated key. Practice is blocked when any required pitch is missing.

## 8. Firestore Rules protection

Firestore Rules allow a calibration to be created, read, updated, or deleted only when:

- the request is authenticated; and
- the signed-in user's ID matches the `{userId}` in the calibration path.

This prevents one user from accessing another user's calibration collection.

The current calibration Rules do not validate field names, geometry, schema version, name length, or timestamps. Those checks are currently performed by the Flutter code. A client that bypasses the app could submit malformed fields to its own calibration document.

Firebase Storage is not used by this feature.

## 9. How geometry and practice results are calculated

### Normalized calibration positions

Pixel positions are converted to fractions so they are not tied to one preview resolution:

```text
horizontal fraction = pixel x / image width
vertical fraction = pixel y / image height
```

When loading, the fractions are converted back:

```text
pixel x = horizontal fraction x current image width
pixel y = vertical fraction x current image height
```

This adapts the stored overlay to a different camera-frame size. It does not detect whether the physical phone mount, angle, zoom, or piano position has changed.

### Key names

The user's tap is labeled `C4`. The app uses nearby two-key and three-key black-key groups to locate other C notes, then fills in the white-key sequence `C, D, E, F, G, A, B`. Black-key labels and regions are added from the detected black-key shapes.

### Practice grouping and accuracy

Score notes with the same exact start time form one note group, such as one chord.

In Performance Mode:

- expected notes use a timing tolerance of 300 milliseconds;
- notes in a chord must be attacked within 200 milliseconds of one another;
- an unexpected pitch is wrong;
- a correct pitch outside the timing window is a timing mistake; and
- an unplayed group becomes missed.

Wait Mode also uses a 200-millisecond chord timing limit, but waits until the target notes are newly pressed and held.

Accuracy is calculated as:

```text
accuracy = correct note groups / total note groups x 100
```

The result is rounded to a whole percentage.

## 10. Skip, resume, failure, and retry behavior

### Skip and unfinished work

There is no Skip button for calibration. The back button can leave the screen, but unfinished detection or mapping work is not saved.

### Resume

A successfully saved calibration can be loaded in a later session. An unfinished calibration cannot be resumed.

Practice playback can be paused and resumed while the screen remains open. Its position and results are not saved for a later app session.

### Expiration

Saved calibrations do not expire in the current code.

### Failure and retry

- Camera failure shows an on-screen camera error.
- A frame-processing error resets the detection state and continues allowing another detection attempt.
- **Detect again** clears detection and starts over.
- **Adjust area** returns to corner editing.
- Cancelling the name dialog returns to mapping review without saving.
- A failed Firestore save shows a connection message; the user can tap **Confirm mapping** and save again.
- A saved-calibration load or score-load failure is shown by AR Practice, and the user can select it again.
- A saved calibration that cannot be restored falls back to fresh keyboard detection.
- A score outside the calibrated range is blocked until the user selects or creates a wider calibration.
- **Retry** after practice resets the local attempt and starts it again.

There is no automatic retry queue.

## 11. What happens after completion

After a new calibration is saved, **Done** returns to the previous screen. The new document then appears in the live saved-calibration list.

After an existing calibration is accepted for a score, the screen changes into AR practice instead of returning immediately. Computer-vision processing stops to reduce CPU, heat, and battery use, while the camera preview remains behind the falling-note overlay.

After practice finishes, **Retry** repeats the same score locally and **Done** closes the screen. No practice result is written to Firebase.

When the screen closes, it disposes the camera, MIDI listeners, MIDI connection, and animation controller, then restores portrait orientation.

## 12. Simple example

Suppose the camera sees keys from `C3` through `B5`.

1. The detector recognizes the repeating two-black-key and three-black-key groups and holds the result for five matching frames.
2. The user corrects the four corners and taps Middle C.
3. The app labels that tap `C4`, derives the surrounding notes, and draws each key outline.
4. The user names it **Bedroom Piano** and saves it.
5. Firestore creates `/users/ana123/pianoCalibrations/calibration456` with normalized corners, all mapped keys, and timestamps.
6. In a later session, a marker saved at horizontal fraction `0.50` is restored halfway across the current camera image.
7. If a selected score needs `C3` through `A5`, the calibration can be used.
8. If it needs `C6`, the app blocks practice because `C6` is outside the saved mapping.

