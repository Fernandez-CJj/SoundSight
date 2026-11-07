# SoundSight ShowcaseView Checklist

Implement and review one feature at a time. Do not implement the next feature until the user explicitly approves the current feature.

Current stage: planning. No ShowcaseView tours have been implemented or approved through this checklist.

The pre-login introduction is a separate task and is outside this checklist.

## Workflow for every feature

1. Agree on the controls to highlight, their order, and the explanation for each step.
2. Implement only that feature's tour. Build the shared tutorial support alongside Home, the first feature.
3. Let the user manually try the feature and its tutorial in the app.
4. Fix issues and repeat the manual review for the current feature.
5. Mark the approval checkbox only after the user confirms it works and approves moving on.

Keep all unreviewed checkboxes unchecked. Implementation alone does not mean a feature is approved.

Respect the current development preference: no automated tests, formatting commands, or static analysis unless the user asks for them. The review checks below are for manual use in the app.

## Shared behavior to establish with Home

- [ ] Add ShowcaseView and the shared tour support.
- [ ] Provide Back, Next, Skip, and Done controls with appropriate first/last-step behavior.
- [ ] Match SoundSight's light and dark themes.
- [ ] Provide English and Filipino explanations and navigation labels.
- [ ] Store completion or explicit skipping separately for each signed-in user, feature, and tutorial version using local preferences.
- [ ] Keep a tour eligible if it could not start because its targets were unavailable.
- [ ] Provide a way to replay the current feature's tutorial; agree on its placement before implementing Home.
- [ ] Start only after the screen and its intended targets are ready and the screen is visible.
- [ ] Handle scrolling to targets that are offscreen; skip or defer targets that do not exist in an empty state.
- [ ] Allow only one active tour and dismiss its overlay when leaving its screen.
- [ ] Prevent tour navigation from accidentally playing, saving, publishing, deleting, or submitting anything.
- [ ] Keep tours short, usually three to five steps. Agree on any longer tour before implementation.

## Manual acceptance checklist

Use this checklist for each feature. Record any failures in that feature's review notes.

- [ ] The first eligible visit shows the correct tour once the screen is ready.
- [ ] Each highlight points to the correct control and its explanation matches the actual behavior.
- [ ] Back, Next, Skip, and Done behave correctly.
- [ ] Skipping or finishing does not automatically repeat the tour on reopening the feature or restarting the app.
- [ ] Replay works without resetting unrelated feature tutorials.
- [ ] A different signed-in account has its own tutorial state on this device.
- [ ] Text and controls fit in both languages, both themes, and the orientations supported by this feature.
- [ ] Scrolling, loading states, and empty states do not leave an overlay pointing to a missing control.
- [ ] Leaving the screen or pressing the system Back button does not leave an overlay behind.
- [ ] Normal feature actions still work after finishing or skipping the tour.
- [ ] The user has reviewed any issues and explicitly approved moving to the next feature.

## Feature sequence

The targets below are proposals. Confirm the exact targets and wording at the start of each feature. Reorder later features if the user prefers; do not treat this list as approval to implement them all.

### 1. Home — first implementation

Suggested targets: drawer/menu button, music-library search, quick actions, and community compositions. Introduce the drawer button here; explain drawer contents in the next feature.

- [ ] Targets, step order, wording, and replay location agreed.
- [ ] Home tour and shared support implemented.
- [ ] User completed the manual acceptance review; reported issues resolved.
- [ ] User approved Home and proceeding to the next feature.

Review notes: Pending.

### 2. Drawer navigation

Suggested targets: main feature destinations, profile, language, and theme controls. Start only while the drawer is open. Do not automatically navigate to every feature during this tour.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 3. Upload / capture music sheet

Suggested targets: choosing the input method, selecting or capturing a sheet, previewing the selection, and submitting it for processing. Explain permissions when relevant.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 4. My Music Sheets

Suggested targets: sheet list, processing status, opening a sheet, and available practice actions. Provide suitable guidance when the list is empty.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 5. Music sheet viewer

Suggested targets: PDF preview, expansion dialog, audio preview, and choosing a practice mode. Explain scrolling through multiple PDF pages in the dialog.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 6. Music Library

Suggested targets: searching, opening a result, and choosing a practice mode. Handle no results without targeting nonexistent cards.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 7. My Compositions

Suggested targets: creating a composition, manual versus recording entry, opening saved work, and playback. Handle an empty list.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 8. Manual Composition

Suggested targets: keyboard/note entry, duration, timeline editing, playback, and saving. Explain advanced controls separately if five steps are insufficient.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 9. Recording a composition

Suggested targets: MIDI connection, recording controls, duration settings, and reviewing/saving the recording. The tour must not start a recording automatically.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 10. Composition details

Suggested targets: generated sheet/audio, editing, practice modes, and publishing. Account for controls that vary with processing or publication state.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 11. Published Compositions

Suggested targets: Most liked/Newest sorting, tapping a card to open details, Play, and the Like/Comment/Save actions. Explain that the user's own publications appear first.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 12. Published composition details

Suggested targets: author and piece information, expandable musical details, Like/Comment/Save, PDF expansion dialog, and practice modes. The same tour should work when opened from Home, Published, or Saved.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 13. Saved Compositions

Suggested targets: saved cards, playback, opening details, and removing a saved item. Do not remove an item during the tutorial. Handle an empty list.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 14. Fundamentals / lessons

Suggested targets: stages, lesson selection, progress, and lesson activities. Explain unavailable or locked content only when relevant.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 15. Assessment

Suggested targets: instructions, starting the assessment, answering/playing, and viewing results. Do not start a timed attempt or submit answers automatically.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 16. Sight Reading

Suggested targets: MIDI connection, Wait/Performance selection, score cursor, and practice controls. Run the tour before an attempt, rather than interrupting active playing.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 17. Synthesia

Suggested targets: MIDI connection, falling notes/keyboard, Wait/Performance selection, and playback/practice controls. Run before active practice.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 18. AR setup / calibration

Suggested targets: camera setup, selecting or creating a piano calibration, aligning the keyboard, and confirming readiness. Do not bypass required setup or permissions.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 19. AR Practice

Suggested targets: overlays, MIDI connection, practice mode, and practice controls. Start only when setup and visible targets are ready, before an attempt begins.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 20. Practice Results

Suggested targets: results list, opening a result, and understanding the detailed performance feedback. Handle users with no results yet.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved proceeding.

Review notes: Pending.

### 21. Profile

Suggested targets: profile editing, skill/progress information, and achievements. Keep account changes under the user's direct control.

- [ ] Targets and wording agreed.
- [ ] Tour implemented.
- [ ] User review completed; reported issues resolved.
- [ ] User approved completion of the planned feature tours.

Review notes: Pending.

## Optional later additions

- [ ] Review whether Flyaway or any other separately accessible feature needs its own tour.
- [ ] Review whether an advanced composition tutorial is useful after the basic tour is approved.
- [ ] Plan the separate pre-login introduction after the feature tutorials are agreed.

## Approval record

After each feature review, record:

- Feature:
- App version/build reviewed:
- Device and orientation:
- Language and theme:
- Issues reported:
- Fixes reviewed:
- User approval/date:
- Next feature authorized:
