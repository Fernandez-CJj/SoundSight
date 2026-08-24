# Flyaway Feature Checklist

## Version 1 goal

Provide live, on-device flyaway-finger analysis for either one or two visible hands while a phone remains fixed above the keyboard. Do not require video recording or integration with Practice, MIDI, profiles, or other SoundSight features yet.

## Agreed behavior

- [ ] Analyze one visible hand without requiring a second hand.
- [ ] Analyze two visible hands simultaneously when both are present.
- [ ] Detect hands automatically by default.
- [ ] Track each visible hand independently.
- [ ] Continue analyzing one hand if the other leaves the frame.
- [ ] Treat missing, obscured, or low-confidence data as unscored time rather than a flyaway event.
- [ ] Support a calibrated portion of the keyboard instead of promising full-keyboard coverage.
- [ ] Process camera frames live without saving a video.
- [ ] Show results after the user ends the session.

## 1. Define the feature boundaries

- [ ] Write a precise user-facing definition of a possible flyaway-finger event.
- [ ] Define the supported phone orientation and mounting position.
- [ ] Define minimum hand visibility requirements.
- [ ] Define what happens when a hand approaches or leaves the analysis area.
- [ ] Define how crossed or heavily overlapping hands are handled.
- [ ] Define the minimum tracking coverage required to include a hand in the results.
- [ ] Decide whether version 1 offers optional Left only, Right only, and Both modes in addition to automatic detection.
- [ ] Confirm that exact height measurements, note correctness, MIDI, recording, and full-keyboard coverage are out of scope.

## 2. Establish the folder structure

- [ ] Keep `flyaway_screen.dart` as the feature entry screen.
- [ ] Add a setup screen for mount and camera guidance.
- [ ] Add a calibration screen for resting-hand baselines.
- [ ] Add a live-analysis screen.
- [ ] Add a session-results screen.
- [ ] Add `models/` for hands, fingers, calibration, events, and session results.
- [ ] Add `services/` for camera frames, hand tracking, calibration, and flyaway analysis.
- [ ] Add `controllers/` for the session lifecycle and UI state.
- [ ] Add `widgets/` for camera overlays, hand status, controls, and result cards.

## 3. Choose the camera and hand-tracking approach

- [ ] Confirm the supported platforms for version 1.
- [ ] Select a camera-frame source that supports a continuous live image stream.
- [ ] Select an on-device hand-landmark solution that can return two hands and all finger joints.
- [ ] Verify acceptable performance on a representative physical phone.
- [ ] Define the image format, rotation, and coordinate conversions between the camera and Flutter overlay.
- [ ] Decide the target analysis frame rate and resolution based on device performance.
- [ ] Keep the camera and hand-tracking implementations behind interfaces so they can be replaced independently.

## 4. Build the entry and setup experience

- [ ] Explain the feature and its limitations on `FlyawayScreen`.
- [ ] Add a Start setup action.
- [ ] Request camera permission with denied and permanently-denied states.
- [ ] Open the rear camera in landscape orientation.
- [ ] Display a guide showing the safe keyboard and hand-analysis area.
- [ ] Show whether zero, one, or two hands are currently visible.
- [ ] Show separate visibility indicators for the left and right hands.
- [ ] Prevent calibration until at least one complete hand is visible.
- [ ] Warn about poor lighting, unstable mounting, and hands near the frame edges when those conditions can be detected reliably.
- [ ] Allow the user to cancel and release the camera cleanly.

## 5. Implement hand identity and tracking

- [ ] Represent all five fingers and their required joints for each hand.
- [ ] Assign stable left- and right-hand identities.
- [ ] Preserve hand identity between frames instead of trusting each frame independently.
- [ ] Support a single hand entering and leaving the frame.
- [ ] Support a second hand appearing during the session.
- [ ] Track confidence separately for every hand and finger.
- [ ] Mark heavily overlapping or crossed-hand frames as uncertain when identity cannot be preserved.
- [ ] Smooth landmark motion without adding excessive delay.

## 6. Implement calibration

- [ ] Ask the player to rest the visible hand or hands naturally on the keys.
- [ ] Collect several seconds of stable landmarks for each visible hand.
- [ ] Calculate an independent baseline for every visible finger.
- [ ] Normalize measurements for hand size and camera distance.
- [ ] Store palm position, orientation, and scale needed to compensate for whole-hand motion.
- [ ] Reject calibration when fingertips are missing or tracking is unstable.
- [ ] Let the user retry calibration.
- [ ] Allow a hand that appears later to calibrate without discarding the already-calibrated hand.
- [ ] Keep calibration data local to the current session for version 1.

## 7. Implement live flyaway analysis

- [ ] Calculate finger elevation relative to its calibrated baseline.
- [ ] Compensate for palm translation, rotation, and scale changes.
- [ ] Compare an individual finger with the movement of its own hand.
- [ ] Require an elevation to persist across multiple frames before starting an event.
- [ ] Use separate start and stop thresholds to prevent rapid event flickering.
- [ ] Add a cooldown or merge window for repeated detections from the same movement.
- [ ] Do not create events from low-confidence or missing landmarks.
- [ ] Do not create events while hand identity is uncertain.
- [ ] Analyze the left and right hands independently.
- [ ] Timestamp event start, peak, and end.
- [ ] Store the affected hand, finger, confidence, duration, and relative elevation.
- [ ] Label detections as possible flyaway events rather than definitive technique errors.
- [ ] Make detection thresholds configurable for tuning instead of scattering constants through UI code.

## 8. Build the live-analysis UI

- [ ] Show the camera preview with a correctly aligned landmark overlay.
- [ ] Use a non-distracting indicator for successfully tracked hands.
- [ ] Indicate low-confidence and out-of-view hands without treating them as errors.
- [ ] Highlight a possible event visually without playing an interrupting sound.
- [ ] Show separate left- and right-hand tracking states.
- [ ] Add pause, resume, and finish controls.
- [ ] Stop analysis while paused.
- [ ] Handle app backgrounding, interruption, and camera loss safely.
- [ ] Avoid displaying raw technical confidence values to the player during practice.

## 9. Build session results

- [ ] Produce separate left- and right-hand summaries when both were analyzed.
- [ ] Omit a hand that did not have enough reliable data and explain why.
- [ ] Show tracking coverage for every analyzed hand.
- [ ] Show possible-event counts for each finger.
- [ ] Show total event duration and the most frequently elevated finger.
- [ ] Distinguish `no events detected` from `insufficient tracking data`.
- [ ] Provide a short, neutral explanation of what the results mean.
- [ ] Add actions to recalibrate, start another session, or return to the feature entry screen.
- [ ] Do not offer video replay because version 1 does not record or retain frames.

## 10. Privacy and resource cleanup

- [ ] State clearly that live video is processed without being saved.
- [ ] Keep camera frames out of logs, analytics, and persistent storage.
- [ ] Dispose of the camera stream, landmark detector, timers, and subscriptions when leaving the feature.
- [ ] Prevent analysis callbacks from updating disposed screens.
- [ ] Keep only the event summary needed for the current results screen.
- [ ] Decide whether session summaries should disappear when the user exits the feature.

## 11. Validation scenarios

- [ ] No hands visible during setup.
- [ ] Only the left hand is used for an entire session.
- [ ] Only the right hand is used for an entire session.
- [ ] Both hands are used for an entire session.
- [ ] A second hand enters after analysis begins.
- [ ] One hand temporarily leaves while the other remains visible.
- [ ] A hand moves close to the left or right edge of the camera view.
- [ ] Fingers briefly overlap.
- [ ] Hands cross or their identities become uncertain.
- [ ] The whole hand lifts without an individual finger flyaway.
- [ ] A finger moves briefly but does not remain elevated.
- [ ] A finger remains unusually elevated for a sustained period.
- [ ] Tracking confidence drops because of poor lighting or motion blur.
- [ ] The user pauses, resumes, and finishes normally.
- [ ] The app is backgrounded during live analysis.
- [ ] Camera permission is denied or permanently denied.

## Version 1 completion criteria

- [ ] A user can enter the Flyaway feature and complete setup without depending on another SoundSight feature.
- [ ] The app can analyze either one or two hands during the same live session.
- [ ] Each hand continues independently when the other is absent or temporarily lost.
- [ ] Possible flyaway events are based on calibrated, sustained individual-finger movement.
- [ ] Uncertain tracking never becomes a technique warning.
- [ ] The user receives a clear per-hand and per-finger summary after ending the session.
- [ ] No practice video or camera frame is saved.
- [ ] All feature code remains contained in `lib/screens/flyaway/`, apart from dependencies or unavoidable platform configuration approved later.

## Deferred integration

- [ ] Connect Flyaway sessions to Practice.
- [ ] Connect results to user profiles or progress history.
- [ ] Add MIDI or note-awareness.
- [ ] Add saved sessions or cloud synchronization.
- [ ] Add optional recording and annotated replay.
- [ ] Add full-keyboard or multi-camera support.
- [ ] Add real-time audio feedback.
