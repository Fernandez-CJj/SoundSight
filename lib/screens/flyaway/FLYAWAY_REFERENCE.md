# Flyaway Feature Reference

## Purpose

Flyaway analyzes the player's visible fingers through the phone's rear camera.
It identifies fingers that rise beyond the player's calibrated normal movement.

The phone is expected to remain on a fixed mount above the piano. The feature
can analyze one or two visible hands. Camera frames are processed live and are
not recorded.

## Complete User Flow

1. The user selects **Flyaway** from the app drawer.
2. The introduction screen explains the fixed-mount setup and live processing.
3. The user presses **Set Up Camera**.
4. The setup screen changes to landscape orientation.
5. The app opens the rear camera. It uses the first available camera if a rear
   camera cannot be found.
6. The camera uses high resolution, disables audio, and uses 1x zoom when the
   device supports it.
7. The hand detector starts and begins processing camera frames.
8. The screen shows the live camera, landmark dots, detector status, calibration
   values, and current measurements.
9. The user presses **Start calibration**.
10. A 3-second preparation countdown begins.
11. The user rests the visible fingers on the keys for 3 seconds.
12. The user moves the fingers normally for 7 seconds without intentionally
    making flyaway movements.
13. The app checks whether it captured a complete calibration for at least one
    hand.
14. If calibration succeeds, the user presses **Start analysis**.
15. The app displays `HIGH` when a finger passes both movement limits.
16. The app displays `FLYAWAY` when the finger remains high for at least 300
    milliseconds.
17. The user can press **Recalibrate** to replace the current calibration.
18. Pressing Back closes the camera screen and returns the app to portrait
    orientation.

## Storage at a Glance

| Storage type | Flyaway behavior |
| --- | --- |
| Temporary local information | Used while the camera screen is open |
| Permanent device storage | Nothing is saved |
| Firebase | Nothing is created or updated |
| Recorded camera frames | None |

## Temporary Local Information

The following information exists only in the camera screen's memory:

- The camera controller and camera error message.
- The hand detector and detector error message.
- Whether the camera stream and detector are ready.
- Whether a camera frame is currently being processed.
- The hands and 21 landmarks found in the latest frame.
- Five finger measurements for every detected hand.
- Previous measurements used to smooth the next frame.
- The current calibration stage and countdown values.
- Resting-depth samples collected during calibration.
- A calibration profile for every finger of each calibrated hand.
- The size of the image analyzed by the detector.
- The time each finger first became high.
- The fingers currently confirmed as flyaway fingers.

Hand information is grouped by the detector's handedness result: left or right.
The left hand is placed before the right hand in the displayed lists. A hand
without a handedness result is placed last, but it cannot receive a calibration
profile or flyaway result.

## Permanent Storage and Firebase

Flyaway does not save information permanently. Leaving the camera screen
discards the calibration, measurements, timers, detected hands, and results.

There are no Firebase collection paths, document paths, created Firebase
fields, or updated Firebase fields for this feature.

Firestore Rules do not validate or protect Flyaway information because the
feature does not read from or write to Firestore.

## Client-Side Validation

All Flyaway validation happens locally inside the Flutter app.

### Camera and detector checks

- The app requires an available and initialized camera before streaming frames.
- It prefers the rear camera and reports an error if no camera is available.
- It waits for the hand detector to initialize before starting detection.
- It does not process a new frame while another frame is still being processed.
- Camera and detector exceptions are converted into messages on the screen.

### Hand detection checks

- The full hand-landmark model is used.
- Detector confidence and minimum landmark score are both set to `0.5`.
- At most two hand detections are requested.
- Hand tracking is enabled between frames.
- The detector analyzes an image whose longest side is limited to 640 pixels.

### Duplicate-hand check

The detector can sometimes return the same physical hand twice. The service
compares the two sets of landmarks relative to their palm sizes.

If their normalized average landmark distance is below `0.20`, they are treated
as duplicates. Only the detection with the higher confidence score is kept.

### Calibration-success check

A hand is complete when:

- all five fingers have resting profiles; and
- every finger received at least one normal-movement sample.

Calibration succeeds when at least one detected hand is complete. If only one
hand is calibrated, only that handedness has the information required for
flyaway analysis.

## Finger and Landmark Mapping

The hand detector returns 21 landmarks numbered from 0 to 20. Flyaway uses the
following base and fingertip landmarks:

| Finger | Base | Fingertip |
| --- | ---: | ---: |
| Thumb | 1 | 4 |
| Index | 5 | 8 |
| Middle | 9 | 12 |
| Ring | 13 | 16 |
| Pinky | 17 | 20 |

Landmark 0 is the wrist. The other landmark numbers stored in the finger enum
identify the two joints between each base and fingertip, although the current
flyaway calculation uses only the base and fingertip.

## How Measurements Are Calculated

### 1. Relative depth

For every finger, the app subtracts the fingertip's estimated depth from the
finger base's estimated depth:

```text
relative depth = base Z - fingertip Z
```

`Z` is depth estimated by the hand-detection model. It is not a physical
distance in centimeters.

### 2. Smoothing

The app combines the previous and current relative-depth measurements:

```text
smoothed depth = previous depth × 0.6 + current depth × 0.4
```

This reduces rapid landmark jitter. When no previous measurement exists, the
current measurement is used without smoothing.

### 3. Resting reference

During the 3-second resting stage, the app collects relative-depth samples for
each visible finger.

A finger needs at least five samples. The samples are sorted, and their median
becomes the finger's resting depth. The median is the middle value, so one
unusually high or low reading is less likely to control the baseline.

### 4. Raw lift

During normal movement and later analysis, raw lift is calculated as:

```text
raw lift = current relative depth - resting depth
```

The largest raw lift observed during normal-movement calibration is stored for
that finger.

### 5. Independent lift

The app also checks whether one finger rose more than its neighboring fingers:

```text
independent lift = finger's raw lift - average neighboring raw lift
```

The neighbor relationships are:

- Thumb compares with Index.
- Index compares with Thumb and Middle.
- Middle compares with Index and Ring.
- Ring compares with Middle and Pinky.
- Pinky compares with Ring.

The largest independent lift observed during normal-movement calibration is
stored separately for every finger.

### 6. Raw and independent caps

The same safety-margin calculation is used for both values:

```text
margin = larger of 20% of the normal maximum or 0.5
cap = normal maximum + margin
```

A finger becomes `HIGH` only when both conditions are true:

- its raw lift is greater than its raw cap; and
- its independent lift is greater than its independent cap.

The second condition reduces false results when the detector changes the depth
of several neighboring fingers together.

### 7. Flyaway duration

Each finger has its own timer. When a finger first becomes high, the app stores
the current time.

The finger becomes `FLYAWAY` after remaining high for at least 300 milliseconds.
If it drops below either cap before then, its timer is cleared.

## Calibration, Failure, and Retry

Pressing the calibration button at any time starts the complete sequence again.
The app clears the previous resting samples, calibration ranges, flyaway timers,
and confirmed results.

Calibration has these stages:

1. **Get ready:** 3 seconds; no calibration samples are collected.
2. **Rest fingers on keys:** 3 seconds; resting samples are collected.
3. **Move normally:** 7 seconds; normal raw and independent lifts are collected.

If calibration succeeds, a dialog explains that the resting reference and
normal movement range were captured. Pressing **Start analysis** enables
flyaway decisions.

If calibration fails, the dialog reports that no complete hand measurement was
captured. Pressing **Try again** immediately restarts the sequence.

There is no saved calibration to resume and no automatic calibration expiration.
The user must recalibrate manually when needed.

If a detected hand disappears during analysis, the app removes that hand's
active flyaway timers. Detection can continue when a hand is visible again, but
it still needs a calibration profile for its handedness.

## What the User Sees

- The camera preview fills the screen using a cover fit, so some edges may be
  cropped.
- The first detected hand uses cyan landmark dots.
- The second detected hand uses orange landmark dots.
- The top-right label shows detector errors, loading state, no-hand state, or
  the number of detected hands.
- The left panel shows resting, raw, and independent calibration values.
- The bottom panel shows the current `Z`, raw lift (`L`), independent lift
  (`IL`), and any `HIGH` or `FLYAWAY` result.

## What Happens When the Screen Closes

The calibration countdown is cancelled. The camera controller and hand detector
are disposed so they stop using camera and machine-learning resources. The app
then allows portrait orientation again.

No analysis summary is created, and no result is saved or sent to another
feature.

## Simple Detection Example

Suppose the Ring finger has these values:

```text
Ring raw lift: 7.3
Middle raw lift: 6.6
Pinky raw lift: 3.2
```

Its average neighboring lift is `(6.6 + 3.2) / 2 = 4.9`.

```text
Ring independent lift = 7.3 - 4.9 = 2.4
```

If `7.3` passes the Ring raw cap and `2.4` passes the Ring independent cap, the
Ring finger becomes `HIGH`. It becomes `FLYAWAY` only if both conditions remain
true for at least 300 milliseconds.
