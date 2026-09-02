# SoundSight Assessment Reconstruction Checklist

This checklist tracks the reconstruction of the SoundSight assessment feature.
The SoundSight level measures the combination of sheet-music reading and piano
execution. A weakness in either required ability can limit the final level.

## Development Rules

- [x] Build the feature in small, reviewable parts.
- [x] Add useful learning comments to new assessment code.
- [x] Test the feature manually on a physical phone.
- [x] Use Firestore server time for protected lifecycle decisions.
- [x] Do not allow the phone clock to authorize assessment changes.
- [x] Do not automatically restart an expired assessment.
- [ ] Keep this checklist updated after every completed part.

## Phase 1: Remove the Old Assessment

- [x] Delete the old questionnaire assessment screen.
- [x] Delete the old profile assessment card.
- [x] Remove old assessment routing from login.
- [x] Remove old assessment score and date fields from registration.
- [x] Preserve the shared `skillLevel` field for challenge progression.

## Phase 2: Assessment Lifecycle Foundation

- [x] Create `AssessmentAttemptStatus`.
- [x] Create `AssessmentSection`.
- [x] Create the immutable `AssessmentAttempt` model.
- [x] Set the completion window to exactly 72 hours.
- [x] Add `startedAt` and `expiresAt`.
- [x] Add `serverCheckedAt` for authoritative lifecycle checks.
- [x] Calculate `effectiveStatus` without using the phone clock.
- [x] Calculate whether the attempt can continue.
- [x] Calculate the trusted remaining duration.
- [x] Add learning comments to the model.

## Phase 3: Firestore Attempt Service

- [x] Create `AssessmentAttemptService`.
- [x] Use the fixed document path `users/{userId}/assessment/current`.
- [x] Create the first attempt with Firestore server timestamps.
- [x] Calculate `expiresAt` from the server-generated `startedAt`.
- [x] Recover an attempt if deadline initialization was interrupted.
- [x] Refresh Firestore server time before checking expiration.
- [x] Resume an active attempt.
- [x] Preserve a completed attempt.
- [x] Permanently mark an unfinished expired attempt as `expired`.
- [x] Atomically assign `skillLevel: beginner` after expiration.
- [x] Prevent creation of a replacement attempt after expiration.
- [x] Add learning comments to the service.

## Phase 4: Firestore Security

- [x] Restrict assessment access to the authenticated owner.
- [x] Allow only the fixed `current` assessment document.
- [x] Validate the initial assessment document fields.
- [x] Require Firestore server timestamps when starting.
- [x] Enforce `expiresAt == startedAt + 3 days`.
- [x] Allow server-time refreshes without changing protected data.
- [x] Require server-confirmed expiration before assigning Beginner.
- [x] Require assessment expiration and Beginner assignment in one batch.
- [x] Deny assessment deletion from the client.
- [x] Remove all expired-attempt restart permission.
- [x] Compile the rules successfully with a Firebase dry run.
- [ ] Deploy the updated Firestore rules.
- [ ] Restrict direct client updates to protected user fields such as
      `skillLevel`.

## Phase 5: Authentication and Session Check

- [x] Check the current assessment after successful login.
- [x] Apply terminal expiration when the user returns to the app.
- [x] Handle assessment synchronization errors during login.
- [ ] Move session initialization into a dedicated startup/authentication gate
      when the application navigation is reconstructed.
- [ ] Decide whether exact background expiration requires a scheduled backend
      job. The current implementation finalizes expiration on the next server
      check.

## Phase 6: Assessment Entry and Introduction

- [ ] Create the assessment entry/status screen.
- [ ] Show Not Started, In Progress, Completed, or Expired state.
- [ ] Create the assessment introduction screen.
- [ ] Explain what the SoundSight level measures.
- [ ] Explain the 72-hour completion deadline.
- [ ] Explain that an expired assessment becomes Beginner permanently.
- [ ] Explain that the user receives only one assessment attempt.
- [ ] Show the equipment requirements.
- [ ] Add a Start Assessment confirmation dialog.
- [ ] Add a Resume Assessment action for active attempts.
- [ ] Show the trusted remaining time.
- [ ] Show an expired-and-locked message when applicable.
- [ ] Test the entry and introduction flow on a phone.

## Phase 7: Progress Persistence

- [ ] Add a service method for saving the current section.
- [ ] Define the only allowed section transitions.
- [ ] Prevent skipping required sections.
- [ ] Prevent progress writes after expiration.
- [ ] Add Firestore rules for section transitions.
- [ ] Restore the correct section after closing and reopening the app.
- [ ] Test resume behavior on a phone.

## Phase 8: Background Questionnaire

- [ ] Define questionnaire models.
- [ ] Create the questionnaire screen.
- [x] Save answers for personalization and reporting.
- [x] Allow only explicit lowest-skill answers to assign Beginner early.
- [x] Prevent questionnaire answers from awarding higher levels.
- [x] Prevent submission with unanswered required questions.
- [x] Add Firestore validation for questionnaire data.
- [x] Confirm the permanent Beginner shortcut before completion.
- [ ] Test questionnaire persistence on a phone.

## Phase 9: MIDI Setup and Unscored Practice

- [x] Detect a connected MIDI keyboard.
- [x] Confirm MIDI note-on and note-off input.
- [ ] Detect or record the available keyboard range.
- [x] Add a reconnect and retry flow.
- [ ] Create an unscored practice excerpt.
- [ ] Explain the countdown and performance feedback.
- [ ] Allow unlimited practice attempts before the scored sections.
- [ ] Prevent technical failures from consuming the assessment.
- [ ] Test MIDI setup and practice on a phone.

## Phase 10: Notation-Reading Assessment

- [x] Define notation-reading questions and difficulty levels.
- [x] Add treble-clef note-recognition questions.
- [x] Add bass-clef note-recognition questions.
- [x] Add note-value questions.
- [x] Add time-signature and accidental questions.
- [ ] Record accuracy and response time.
- [x] Calculate a separate notation-reading level.
- [x] Save notation-reading results.
- [x] Add Firestore validation for notation results.
- [ ] Test the section on a phone.

## Phase 11: Piano-Execution Assessment

- [x] Define guided keyboard patterns that do not require sight-reading.
- [x] Add right-hand control tasks.
- [x] Add left-hand control tasks.
- [x] Add two-hand coordination tasks.
- [x] Add rhythm measurement against a metronome.
- [x] Add chord and scale execution tasks.
- [x] Display every required key with its exact octave.
- [x] Explain whether notes occur every click or every second click.
- [x] Display a visible GO signal and current performance beat.
- [x] Display the key or chord currently expected from MIDI.
- [x] Calculate a separate piano-execution level.
- [x] Save piano-execution results.
- [x] Add Firestore validation for execution results.
- [ ] Test the section on a phone.

## Phase 12: Integrated Sight-Reading Assessment

Deferred from assessment version 1. The prototype MusicXML files are retained
for a future assessment version.

- [ ] Create assessment-only Beginner excerpts.
- [ ] Create assessment-only Intermediate excerpts.
- [ ] Create assessment-only Advanced excerpts.
- [ ] Keep scored excerpts hidden until performance begins.
- [ ] Add an immediate-start countdown after revealing an excerpt.
- [ ] Prevent pausing or saving halfway through a scored excerpt.
- [ ] Mark an interrupted excerpt as consumed.
- [ ] Measure correct, wrong, missed, and extra notes.
- [ ] Measure rhythm accuracy and tempo stability.
- [ ] Measure continuity and excessive pauses.
- [ ] Save excerpt IDs and performance results.
- [ ] Add Firestore validation for performance results.
- [ ] Test each difficulty on a phone.

## Phase 13: Placement and Scoring

- [ ] Define provisional pass thresholds using real performance data.
- [x] Require minimum note accuracy.
- [x] Require minimum rhythm accuracy.
- [x] Require every piano task to be completed.
- [x] Calculate `notationReadingLevel`.
- [x] Calculate `pianoExecutionLevel`.
- [x] Defer `sightReadingLevel` from assessment version 1.
- [x] Prevent one strong ability from hiding a weak required ability.
- [x] Calculate the final SoundSight level from the weakest required dimension.
- [x] Assign Beginner, Intermediate, or Advanced.
- [x] Keep scoring logic separate from widgets.

## Phase 14: Completion and Results

- [x] Save the completed assessment before updating the user profile.
- [x] Require completion before the server deadline.
- [x] Save `completedAt` using Firestore server time.
- [x] Apply the saved final SoundSight level when the user presses Done.
- [x] Allow a failed profile update to retry without repeating piano tasks.
- [x] Prevent completed assessment data from being changed by the client.
- [x] Create the assessment review screen.
- [x] Display the overall SoundSight level.
- [x] Display notation and piano-execution breakdowns.
- [x] Display saved background and notation answers.
- [x] Display every saved piano-task result.
- [ ] Explain strengths and areas for improvement.
- [ ] Recommend the appropriate lessons and challenges.
- [ ] Test successful completion on a phone.

## Phase 15: Application Integration

- [ ] Route an unassessed user to the assessment entry flow.
- [ ] Route an active user to Resume Assessment.
- [x] Route a completed user through Results and then to Home.
- [ ] Route an expired user to Home as Beginner.
- [x] Allow an unstarted user to skip to Home without starting the timer.
- [x] Allow an active user to continue later without pausing the deadline.
- [x] Add assessment access and status to the profile screen.
- [ ] Update challenge access from the final SoundSight level.
- [ ] Replace outdated assessment fields in existing user documents if needed.

## Phase 16: Final Phone Testing

- [ ] Test a brand-new account.
- [ ] Test closing and reopening during every section.
- [ ] Test the exact 72-hour boundary.
- [ ] Test changing the phone date backward.
- [ ] Test changing the phone date forward.
- [ ] Test an expired partial assessment becoming Beginner.
- [ ] Confirm an expired user cannot start again.
- [ ] Test an excellent pianist with weak notation reading.
- [ ] Test an excellent reader with weak piano execution.
- [ ] Test Beginner, Intermediate, and Advanced placement.
- [ ] Test MIDI disconnection during practice.
- [ ] Test MIDI disconnection during piano execution.
- [ ] Test temporary network failure and recovery.
- [ ] Confirm completed results remain unchanged after the old deadline.

## Current Next Step

- [ ] Review the complete assessment implementation before phone testing.
- [ ] Deploy the current Firestore rules.
- [ ] Test the complete flow on a phone.
