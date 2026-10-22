# SoundSight Localization Checklist

Last updated: 2026-10-22

## Localization Foundation

- [x] Add `flutter_localizations`, `intl`, and localization generation configuration.
- [x] Create English (`en`) and Filipino (`fil`) ARB files.
- [x] Configure `MaterialApp` with localization delegates and supported locales.
- [x] Create the app-level locale controller.
- [x] Add convenient localization access from widget contexts.

## Firestore Persistence

- [x] Add `languageCode: 'en'` to newly registered user documents.
- [x] Load the saved language during application startup.
- [x] Apply the saved language after login.
- [x] Fall back to English for missing or invalid values.
- [x] Reset the in-memory language to English after every implemented logout path.
- [x] Save language changes with `updatedAt`.
- [x] Restore the previous language and show an error if saving fails.
- [x] Restrict Firestore `languageCode` values to `en` and `fil`.

## Shared Drawer

- [x] Add the Language picker.
- [x] Show the active language in the drawer.
- [x] Translate all drawer navigation labels.
- [x] Translate Dark Mode and Logout.
- [x] Translate the logout confirmation dialog.
- [x] Translate drawer profile fallback and skill-level labels.
- [x] Keep English and Filipino language names understandable in both locales.
- [x] Group primary, composition, and planned-removal drawer destinations with dividers.

## Music Sheets Library

- [x] Translate the app-bar title and Add Sheet tooltip.
- [x] Translate the library heading and description.
- [x] Translate empty, error, loading, and signed-out states.
- [x] Translate sheet-card labels and actions.
- [x] Add localized singular and plural page counts.
- [x] Use locale-aware added-date formatting.
- [x] Translate rename validation and success/error messages.
- [x] Translate delete confirmation and success/error messages.
- [x] Keep user-created sheet titles unchanged.

## Music Sheet Viewer

- [x] Translate Play and practice-mode selection.
- [x] Translate Original and Recognized tabs.
- [x] Translate loading, missing-file, retry, and failure states.
- [x] Translate messages shown before opening linked practice modes.
- [x] Localize the linked AR Practice, Synthesia, and Sight Reading destination screens.

## OMR Translation

- [x] Translate Translate, Reconvert, Retry, Continue, Cancel, Done, and Close.
- [x] Translate processing, success, and failure dialogs.
- [x] Add localized note and part counts with plural handling.
- [x] Translate OMR status-card headings and descriptions.
- [x] Replace raw service messages with stable error types.
- [x] Convert stable error types into localized UI messages.
- [x] Keep MusicXML, MIDI, Audiveris, and technical identifiers unchanged.

## Audio Preview

- [x] Translate default playback status text.
- [x] Translate Play, Pause, and Stop tooltips.
- [x] Translate loading and playback errors.
- [x] Confirm shared controls and default messages localize wherever the widget is reused.
- [x] Preserve feature-specific English text explicitly supplied by deferred features.

## Capture/Upload

- [x] Translate the Add Sheet app bar and delete-all tooltip.
- [x] Translate PDF upload and camera capture choices and limits.
- [x] Translate capture tips.
- [x] Translate selected-file counts, metadata, preview instructions, and removal dialogs.
- [x] Translate PDF validation, size, page-count, and incompatible-selection messages.
- [x] Translate the sheet-title dialog and validation.
- [x] Translate saving progress and save success/failure dialogs.
- [x] Keep file names and user-entered sheet titles unchanged.

## Home Dashboard

- [x] Translate the greeting and encouragement text.
- [x] Translate the profile-button tooltip.
- [x] Translate the player-progress heading, rank, level, experience, and next-level labels.
- [x] Translate skill-level values without changing stored Firestore values.
- [x] Translate the quick-action heading and labels.
- [x] Translate the Home community heading, description, states, actions, and playback messages.
- [x] Keep usernames and user-created composition titles unchanged.
- [x] Translate the visible Home practice-card title, description, and button.
- [x] Leave the Practice destination screen excluded because the feature is planned for removal.
- [x] Leave destination screens opened from Home deferred.

## Profile

- [x] Translate the Profile app bar and edit tooltip.
- [x] Translate the profile-picture dialog and role badge.
- [x] Translate Account, Preferences, Dark Mode, and appearance labels.
- [x] Translate the shared player-progress card and skill-level values.
- [x] Translate every Profile assessment status and description.
- [x] Translate the edit-profile sheet, fields, helper text, and actions.
- [x] Translate username validation, image-size validation, and save failures.
- [x] Translate profile-save confirmation and progress dialogs.
- [x] Keep usernames, email addresses, profile images, and stored values unchanged.
- [x] Leave the Assessment destination screen deferred.

## Composition Library and Creation Entry

- [x] Translate the My Compositions app bar, headings, buttons, and tooltips.
- [x] Translate empty, loading-error, and signed-out states.
- [x] Translate composition-card method badges, file-generation states, and actions.
- [x] Use locale-aware last-edited dates.
- [x] Translate save, generation, deletion, and failure messages.
- [x] Translate the delete-composition confirmation dialog.
- [x] Style the composition dialog's Delete action in red.
- [x] Replace each composition card's delete menu with swipe-to-delete.
- [x] Translate the New Composition setup screen and validation.
- [x] Keep composition titles, key signatures, time signatures, BPM, and stored values unchanged.
- [x] Leave the manual editor and recording destination screens deferred.

## Composition Details

- [x] Translate the app bar, overflow actions, overview labels, and Play button.
- [x] Translate play-mode choices while leaving destination screens deferred.
- [x] Translate playback states, controls, summary labels, and locale-aware dates.
- [x] Translate generated-file states, descriptions, retry action, and messages.
- [x] Translate generated PDF and audio preview labels and loading errors.
- [x] Translate publish, update, unpublish, edit, and delete actions.
- [x] Translate publish and unpublish confirmation and progress dialogs.
- [x] Translate publication, playback, generation, loading, and deletion messages.
- [x] Retry a rejected publication request once with a reloaded Firebase user and fresh ID token.
- [x] Show a localized authentication-session message when publishing still returns 401.
- [x] Keep user-created titles, musical values, and technical file names unchanged.

## Manual Composition Editor

- [x] Translate editor tooltips, composition information, navigation, rest, overview, and save controls.
- [x] Translate playback and performance controls and their compact landscape variants.
- [x] Translate note-duration names, automatic duration guidance, and duration dialog.
- [x] Translate chord mode, layer notes, selection, history, tie, copy, paste, and deletion controls.
- [x] Translate piano-roll, measure navigation, measure actions, octave controls, and all-notes dialog.
- [x] Translate composition settings, save confirmation, and unsaved-changes dialogs.
- [x] Translate direct editor validation, playback, note-limit, generation, and save messages.
- [x] Preserve composition titles, pitches, octaves, key signatures, time signatures, BPM, and note values.
- [x] Leave MIDI connection labels and status messages excluded because MIDI is planned for removal.
- [x] Continue to the performance-recording workflow as the next composition feature.

## Composition Recording

- [x] Translate camera controls and camera failure/retry states.
- [x] Translate start/stop recording controls while preserving excluded MIDI connection labels.
- [x] Translate note-limit, duration-limit, held-key, and recording failure messages.
- [x] Translate the recording-completion dialog, performance summary, and actions.
- [x] Translate composition save, file-generation, retry, and completion states.
- [x] Preserve composition titles, BPM, counts, durations, and technical file names.
- [x] Leave MIDI connection labels and status messages excluded because MIDI is planned for removal.

## Published and Saved Compositions

- [x] Translate the Published Compositions library heading, description, count, and states.
- [x] Translate shared published/saved cards, metadata, playback, viewing, and unpublish actions.
- [x] Add localized singular and plural measure and note counts.
- [x] Use locale-aware published dates and comment dates.
- [x] Translate like, save, unsave, confirmation, and failure messages.
- [x] Translate the Saved Sheets library and its signed-out, empty, loading, and error states.
- [x] Translate the published composition viewer, PDF failure state, and play-mode dialog.
- [x] Translate comments, comment states, input, deletion dialog, and failures.
- [x] Preserve usernames, composition titles, comments, musical values, BPM, versions, and technical identifiers.
- [x] Localize the linked AR Practice, Synthesia, and Sight Reading destination screens.

## Piano Calibration

- [x] Translate the Piano Setup picker, saved cards, loading, empty, and error states.
- [x] Translate individual and bulk piano-setup deletion flows.
- [x] Show localized physical setup instructions before opening a new calibration.
- [x] Replace the preparation dialog with a four-slide visual calibration guide.
- [x] Add responsive Back, Next, Skip, and Start Calibration controls.
- [x] Emphasize that the corner outline must cover only SoundSight's detected key group.
- [x] Translate piano detection, camera guidance, keyboard-area adjustment, and error states.
- [x] Translate Middle C selection, connection assistance, manual guidance, and alignment states.
- [x] Translate calibration controls, naming, validation, saving, loading, success, and failure states.
- [x] Translate saved-calibration alignment and score-range review dialogs.
- [x] Preserve note names, C4, MIDI, USB, device names, note ranges, and technical identifiers.
- [x] Allow the status banner and bottom controls to wrap without ellipsis.
- [x] Keep dialog actions side by side while allowing buttons to grow vertically for longer Filipino labels.
- [x] Make calibration dialog content vertically scrollable in constrained landscape layouts.
- [x] Increase calibration dialog content width while retaining responsive screen constraints.
- [x] Localize the AR Practice portion embedded in the calibration screen.

## Synthesia

- [x] Translate loading, score-preparation failure, retry, and navigation states.
- [x] Translate Performance Mode and Wait Mode selection and explanations.
- [x] Translate MIDI connection requirements, statuses, and recovery guidance used by Synthesia.
- [x] Translate MP3 preview controls and playback failures.
- [x] Translate live note, chord, timing, duration, and connection feedback.
- [x] Translate the practice controls sheet and progress labels.
- [x] Translate completion summaries, statistics, result-saving states, and actions.
- [x] Translate performance insights and improvement suggestions.
- [x] Allow Filipino text and buttons to wrap without ellipsis.
- [x] Preserve composition titles, note names, MIDI, MP3, and technical values.

## Sight Reading

- [x] Translate score preparation, loading, retry, and failure states.
- [x] Translate Performance Mode and Wait Mode selection and explanations.
- [x] Translate MIDI connection prompts, statuses, and recovery guidance used by Sight Reading.
- [x] Translate MP3 preview controls and playback failures.
- [x] Translate live note, chord, timing, duration, hint, and held-note feedback.
- [x] Translate the controls sheet, progress, source, and timeline labels.
- [x] Translate completion summaries, statistics, XP messages, result-saving states, and actions.
- [x] Translate performance insights and improvement suggestions.
- [x] Allow English and Filipino text to wrap or scale without ellipsis.
- [x] Preserve score titles, note names, MIDI, MP3, MusicXML, XP, and technical values.

## AR Practice

- [x] Translate the AR Practice app bar, mode selector, progress, and controls.
- [x] Translate notation selection and number-notation video failures.
- [x] Translate MIDI connection, disconnection, reconnection, and recovery guidance.
- [x] Translate live note, chord, timing, duration, hold, and release feedback.
- [x] Translate Performance Mode and Wait Mode switching explanations.
- [x] Translate completion summaries, statistics, result-saving states, and actions.
- [x] Translate performance insights and improvement suggestions.
- [x] Allow English and Filipino text to wrap or scale without ellipsis.
- [x] Preserve score titles, note names, MIDI, device names, and technical values.

## Practice Results

- [x] Translate the Practice Results library, loading, signed-out, empty, and error states.
- [x] Translate search, practice-type chips, advanced filters, sorting, and no-match states.
- [x] Translate result-card metadata, counts, clef guidance, and suggestions.
- [x] Translate individual and bulk deletion dialogs, actions, and status messages.
- [x] Translate the Practice Result detail summary, statistics, breakdown, and suggestions.
- [x] Translate note-review issue types, timing feedback, clef labels, and error states.
- [x] Use locale-aware dates and times while preserving stored Firestore values.
- [x] Allow titles, labels, chips, and feedback to wrap without ellipsis.
- [x] Preserve score titles, note names, percentages, durations, and technical identifiers.

## Excluded: Planned Feature Removal

- [ ] Do not localize Practice.
- [ ] Do not localize MIDI.
- [ ] Do not localize Microphone.
- [ ] Do not localize Flyaway.

## Excluded: Authentication

- [ ] Do not localize Login.
- [ ] Do not localize Register.
- [ ] Do not localize Email Verification.

## Excluded: Assessment

- [ ] Do not localize Assessment screens.
- [ ] Keep only the Assessment status card shown on Profile localized.

## Manual Screen Test Checklist: Current Localization Scope

### Shared Drawer

- [ ] Confirm the first group is Home, Upload Sheet, Music Sheets, Practice, and Practice Results.
- [ ] Confirm the second group is Composition, Published Compositions, and Saved Sheets.
- [ ] Confirm the third group is MIDI, Mic, and Flyaway.
- [ ] Confirm divider lines separate all three groups from each other and from settings.
- [ ] Open the drawer from Home and switch from English to Filipino.
- [ ] Confirm every drawer label changes immediately.
- [ ] Confirm the selected language is shown under the Language/Wika row.
- [ ] Open the language dialog in dark mode and confirm both language labels and the selected checkmark are clearly visible.
- [ ] Confirm the profile fallback and skill-level label are translated.
- [ ] Confirm Dark Mode still works after switching languages.
- [ ] Open and cancel the logout confirmation in both languages.

### Home Dashboard

- [ ] Open Home in English and confirm the greeting includes the unchanged username.
- [ ] Switch to Filipino and confirm the greeting and encouragement update immediately.
- [ ] Confirm the profile icon tooltip is translated.
- [ ] Confirm Player Progress, rank, level, experience, XP-needed, and next-level labels are translated.
- [ ] Confirm Beginner, Intermediate, Advanced, and the under-assessment fallback display correctly in Filipino.
- [ ] Confirm all six quick-action labels are translated and still open their existing destinations.
- [ ] Confirm the community heading, description, See All, empty/error states, and Play/Stop labels are translated.
- [ ] Confirm each community card shows key/BPM and the heart count on one row.
- [ ] Confirm the full-width Play/Stop button has centered content within each community card.
- [ ] Play and stop a community composition and confirm its snackbar is translated while its title remains unchanged.
- [ ] Confirm the Home practice-card title, description, and button are translated.
- [ ] Confirm the English and Filipino practice-button icon and label are centered.
- [ ] Confirm opening the card still reaches the existing English Practice destination screen.
- [ ] Check Home in light and dark modes and look for clipped Filipino text.

### Profile

- [ ] Open Profile in English and Filipino and confirm the app-bar title and edit tooltip are translated.
- [ ] Confirm the username and email remain unchanged after switching languages.
- [ ] Open the profile-picture preview and confirm its title and close tooltip are translated.
- [ ] Confirm the role badge and complete player-progress card are translated.
- [ ] Confirm Account, Edit Profile, Preferences, Dark Mode, and App Appearance are translated.
- [ ] Check the assessment card while loading, not started, in progress, completed, expired, and failed when safely possible.
- [ ] Confirm tapping the assessment card still opens the existing English Assessment destination.
- [ ] Open Edit Profile and confirm the header, Username, Email, helper text, Cancel, and Save Changes are translated.
- [ ] Submit an empty username and confirm its snackbar is translated.
- [ ] Open and cancel the save-confirmation dialog in both languages.
- [ ] Save a username change and confirm user-entered text remains unchanged.
- [ ] Select an image larger than 5 MB and confirm the localized size warning.
- [ ] Trigger a save failure if safely possible and confirm the localized failure snackbar.
- [ ] Confirm the logout button and dialog remain translated.
- [ ] Check Profile and its dialogs in light and dark modes for clipped Filipino text.

### Composition Library and Creation Entry

- [ ] Open My Compositions in English and Filipino.
- [ ] Confirm the app bar, library heading, description, count, and New Composition controls are translated.
- [ ] Confirm Manual and Recording badges, last-edited dates, View, Retry, and generation states are translated.
- [ ] Confirm user-created composition titles, key signatures, BPM, and time signatures remain unchanged.
- [ ] Confirm composition cards no longer show a three-dot menu.
- [ ] Swipe a composition card from left to right and cancel the delete confirmation in both languages.
- [ ] Confirm the Delete button is red and its label is clearly visible in light and dark modes.
- [ ] Swipe and delete a disposable composition, then confirm the card disappears and its localized success message appears.
- [ ] Trigger a generation retry when safely possible and confirm localized success/failure messaging.
- [ ] Confirm empty, error, and signed-out states are translated when available.
- [ ] Open New Composition and switch between Manual and Recording.
- [ ] Confirm all setup headings, descriptions, field labels, hints, and buttons are translated.
- [ ] Test empty and over-80-character title validation.
- [ ] Test invalid, below-40, and above-200 tempo validation.
- [ ] Confirm key-signature and time-signature values are not translated.
- [ ] Confirm Start Composing and Open Recorder still open their existing English destination screens.
- [ ] Check both screens in light and dark modes for clipped Filipino text.

### Composition Details

- [ ] Open a composition in English and Filipino and confirm all detail labels update.
- [ ] Confirm the title, key signature, time signature, BPM, and technical file names remain unchanged.
- [ ] Check playback status labels and Play, Pause, Stop, and restart tooltips.
- [ ] Check singular and plural Measure and Note labels.
- [ ] Confirm edited and generated dates follow the selected locale.
- [ ] Check ready, outdated, generating, and failed music-file states when available.
- [ ] Confirm the Full screen button follows the theme colors in light and dark modes, then open the generated PDF and play its audio preview.
- [ ] Open and cancel the Publish, Publish Update, Unpublish, and Delete dialogs.
- [ ] Publish a ready composition in Filipino and confirm the request succeeds after the authentication retry if needed.
- [ ] Switch to English and repeat publishing with the same account and composition.
- [ ] If publishing still returns 401, confirm the localized session message appears, then sign out and sign in again.
- [ ] Confirm Edit still opens the existing English editor screen.
- [ ] Confirm Sight Reading, Synthesia, and AR Practice still open their existing destination screens.
- [ ] Check the screen and every dialog in light and dark modes for clipped Filipino text.

### Manual Composition Editor

- [ ] Open a manually created composition and enter Edit in English and Filipino.
- [ ] Check portrait and landscape layouts for clipped or overflowing Filipino text.
- [ ] Confirm the title, pitch names, octave numbers, key signature, time signature, BPM, and note values remain unchanged.
- [ ] Check Playback, Performance, Volume, Velocity, From Cursor, Loop Measure, Sustain, and Metronome controls.
- [ ] Open Note Duration and check every duration name and Automatic guidance.
- [ ] Toggle Chord Mode and finish a chord.
- [ ] Toggle Layer Notes and confirm the localized measure-and-beat position updates.
- [ ] Add, select, move, copy, paste, tie, and delete notes.
- [ ] Use Undo, Redo, Select All, and Delete Whole Chord.
- [ ] Navigate measures and test Add, Insert, Duplicate, Move, Clear, and Delete measure actions.
- [ ] Change octaves, open All Notes, and check empty and populated states.
- [ ] Open Composition Settings and test title and tempo validation.
- [ ] Open and cancel the save-confirmation dialog in both languages.
- [ ] Save a disposable edit and confirm success or file-generation messages are localized.
- [ ] Make an unsaved edit, press Back, and check Keep Editing and Discard.
- [ ] Confirm MIDI connection labels remain English as an intentionally excluded feature.
- [ ] Check all controls and dialogs in light and dark modes.

### Composition Recording

- [ ] Open New Composition, choose Recording, and enter the recorder in English and Filipino.
- [ ] Confirm Switch Camera, Start Recording, and Stop Recording tooltips are translated.
- [ ] Confirm MIDI connection button labels and statuses remain English as an intentionally excluded feature.
- [ ] Deny or disable camera access when safely possible and confirm the camera error and Try Again action are translated.
- [ ] Record without completing a note and confirm the No Notes Recorded dialog is translated.
- [ ] Record a short performance and confirm the completion dialog, summary labels, Record Again, and Generate are translated.
- [ ] Confirm the composition title, duration, note count, tempo, measure count, BPM, and technical file names remain unchanged.
- [ ] Trigger the held-key, note-limit, or duration-limit messages when safely possible and confirm they are translated.
- [ ] Generate a disposable recorded composition and confirm the progress overlay and success message are translated.
- [ ] If saving or file generation fails, confirm its dialog and retry actions are translated.
- [ ] Check portrait and landscape layouts in light and dark modes for clipped Filipino text.

### Published and Saved Compositions

- [ ] Open Published Compositions in English and Filipino and confirm its app bar, heading, description, count, and cards are translated.
- [ ] Confirm usernames, composition titles, key signatures, BPM, time signatures, versions, and technical identifiers remain unchanged.
- [ ] Check singular and plural measure and note labels on published cards.
- [ ] Confirm published dates follow the selected locale.
- [ ] Play and stop a composition and confirm the snackbar and button labels are translated.
- [ ] Like and unlike a composition; if an error occurs, confirm its message is translated.
- [ ] Save a composition, cancel the confirmation once, then confirm saving and verify the card changes to Saved/Naka-save.
- [ ] Open Saved Sheets and confirm the saved composition appears with the same localized card.
- [ ] Remove it from Saved Sheets, cancel once, then confirm removal.
- [ ] Open a published sheet and confirm Play, the play-mode dialog, playback tooltip, version, and PDF error/retry state are translated.
- [ ] Confirm AR Practice, Sight Reading, and Synthesia all follow the selected language.
- [ ] Open Comments and check the app bar, empty/error states, input hint, and locale-aware timestamps.
- [ ] Post a disposable comment and confirm user-entered comment text remains unchanged.
- [ ] Open and cancel the delete-comment dialog, then delete the disposable comment.
- [ ] If you own a published composition, open and cancel Unpublish, then verify its localized success/failure message when safely tested.
- [ ] Check Published, Saved, Viewer, Comments, and confirmation dialogs in light and dark modes for clipped Filipino text.

### Piano Calibration

- [ ] Open the Piano Setup picker in English and Filipino and confirm the title, heading, and New Piano Setup button are translated.
- [ ] Confirm saved setup names remain unchanged while their localized last-saved dates and times update correctly.
- [ ] Check the loading, empty-library, and load-error states in both languages.
- [ ] Swipe one saved setup and confirm the red Delete/Burahin action is visible without clipping.
- [ ] Open and cancel the individual delete dialog in both languages, then delete a disposable setup and verify its localized message.
- [ ] Open and cancel Delete All in both languages and confirm both dialog buttons stay side by side without clipping.
- [ ] Press New Piano Setup and confirm the four-slide visual guide appears before the camera screen opens.
- [ ] Confirm slides 1 through 4 show `guide_1`, `guide2`, `guide_3`, and `guide_4` in that order.
- [ ] Read every slide in English and Filipino and confirm no title, explanation, warning, or button is clipped or ends with an ellipsis.
- [ ] On slide 2, confirm the warning clearly says not to outline every key visible in the camera.
- [ ] On slide 3, confirm the instruction says to fit the four corners only around SoundSight's detected key group.
- [ ] Confirm Back and Next move one slide at a time and the page indicator updates correctly.
- [ ] Confirm Skip from slides 1, 2, and 3 closes the guide and starts the calibration flow.
- [ ] Confirm Start Calibration on slide 4 closes the guide and starts the calibration flow.
- [ ] Confirm the close button returns to the setup picker without starting calibration.
- [ ] Check the guide in portrait and landscape orientations and verify that its content can scroll when space is limited.
- [ ] Check all four slides in light and dark modes and confirm images remain contained without distortion.
- [ ] Open Piano Calibration in English and Filipino.
- [ ] Confirm the camera search, detection guidance, keyboard-area adjustment, and camera-error text are translated.
- [ ] Rotate to each supported landscape orientation and confirm the status banner wraps without clipping or ellipsis.
- [ ] Check Try Again, Keys Are Visible, Adjust Visible Keys, Save Piano Setup, and completion controls.
- [ ] Open the Middle C help dialog and verify both the MIDI and manual guide paths.
- [ ] Confirm all dialog actions are full width, can wrap, and never end with an ellipsis.
- [ ] Follow the manual Middle C guide and verify every instruction is translated.
- [ ] If available, connect and disconnect a digital piano and check connection statuses and dialogs.
- [ ] Select Middle C and confirm the labels and C4 technical value remain unchanged.
- [ ] Open the piano-setup naming dialog, test empty-name validation, and cancel once.
- [ ] Save a disposable piano setup and confirm the saving and success states are translated.
- [ ] If saving fails, confirm the localized failure guidance is fully visible.
- [ ] Load a saved setup and check Recalibrate, alignment guidance, Set Up Again, and Use.
- [ ] If a score exceeds the visible key range, check the More Piano Keys Needed dialog without translating note ranges.
- [ ] Check every calibration status, control, and dialog in light and dark modes for clipping, overflow, or ellipsis.
- [ ] Continue into AR Practice and confirm its app bar, controls, and feedback follow the selected language.

### Synthesia

- [ ] Open Synthesia from a converted music sheet in English and Filipino.
- [ ] Open Synthesia from a personal composition and a published composition when available.
- [ ] Confirm Preparing Synthesia, score-loading failures, Back, and Retry are translated.
- [ ] Switch between Wait Mode and Performance Mode and read both confirmation dialogs completely.
- [ ] Confirm Cancel and Switch Mode remain side by side and do not clip in Filipino.
- [ ] Start each mode without MIDI and confirm the connection dialog is fully translated.
- [ ] Connect, disconnect, and reconnect a MIDI keyboard and check every status and recovery message.
- [ ] Confirm MIDI, MP3, device names, note names, and user-created score titles remain unchanged.
- [ ] Play and stop an MP3 preview and check loading, listening, unavailable, and failure messages.
- [ ] Open Controls and verify Listen, Connect MIDI, Start/Resume, Restart, and Close controls.
- [ ] Confirm the controls sheet can scroll on a short landscape display.
- [ ] In Wait Mode, test correct notes, wrong notes, chords, held notes, early release, and timeline scrubbing feedback.
- [ ] In Performance Mode, test early, late, wrong, missed, correct, and interrupted feedback.
- [ ] Confirm the feedback banner wraps and never ends with an ellipsis.
- [ ] Complete a perfect attempt and an attempt with mistakes when practical.
- [ ] Check every result statistic, save state, Retry, Done, and View Full Result action.
- [ ] Confirm View Full Result opens the localized Practice Result detail screen.
- [ ] Confirm What to Work On and How to Improve are translated without clipped suggestions.
- [ ] Confirm Wait Mode explains that its result is not scored or saved.
- [ ] Check Synthesia in light and dark app modes and at different landscape widths.

### Sight Reading

- [ ] Open Sight Reading from a converted music sheet in English and Filipino.
- [ ] Open Sight Reading from a personal composition and a published composition when available.
- [ ] Confirm score preparation, loading, source, progress, target duration, failure, and retry text are translated.
- [ ] Switch between Wait Mode and Performance Mode and read both confirmation dialogs completely.
- [ ] Confirm Cancel and Switch Mode stay side by side and grow vertically instead of clipping in Filipino.
- [ ] Start each mode without MIDI and confirm the connection dialog is fully translated and scrollable.
- [ ] Connect, disconnect, and reconnect a MIDI keyboard and check every status and recovery message.
- [ ] Confirm MIDI, MP3, MusicXML, device names, note names, XP, and user-created score titles remain unchanged.
- [ ] Play and stop the MP3 preview and check loading, listening, unavailable, and failure messages.
- [ ] Open Controls and verify Listen, Connect MIDI, Retry, and Close controls are translated.
- [ ] Confirm the controls sheet scrolls on a short landscape display.
- [ ] In Wait Mode, test correct notes, wrong notes, chords, hints, held notes, early release, and notes held too long.
- [ ] In Performance Mode, test early, late, wrong, missed, correct, and chord-timing feedback.
- [ ] Confirm feedback, hints, statuses, and buttons never end with an ellipsis or become clipped.
- [ ] Complete a perfect attempt, an attempt with mistakes, and a hint-required retry when practical.
- [ ] Check every result statistic, XP explanation, Retry, Done, save status, and View Full Result action.
- [ ] Confirm What to Work On and How to Improve are translated and their suggestions are fully readable.
- [ ] Confirm View Full Result opens the localized Practice Result detail screen.
- [ ] Check all Sight Reading screens, sheets, and dialogs in light and dark modes at different landscape widths.

### AR Practice

- [ ] Open AR Practice from a converted music sheet in English and Filipino.
- [ ] Open AR Practice from a personal composition and a published composition when available.
- [ ] Select a saved piano setup and confirm its user-created name remains unchanged.
- [ ] Confirm the AR Practice title, score title fallback, Wait/Performance selector, progress, and Controls are translated.
- [ ] Confirm score titles, note names, MIDI, device names, percentages, and timing values remain unchanged.
- [ ] Start each mode without MIDI and confirm connection guidance is translated.
- [ ] Connect a MIDI piano and check Connecting, Connected, and ready states.
- [ ] Open Controls and verify MIDI status, Start, Stop, the warning, and Close controls are translated.
- [ ] Confirm the controls sheet scrolls on a short landscape display.
- [ ] Open the notation dialog and verify Notes and Number Notation are translated and remain side by side without clipping.
- [ ] If the number-notation video cannot load, confirm its error message is translated and fully visible.
- [ ] Switch between Wait Mode and Performance Mode and read both confirmation dialogs completely.
- [ ] Confirm Cancel and Switch Mode remain side by side and grow vertically instead of clipping in Filipino.
- [ ] Disconnect and reconnect the MIDI piano during an attempt and check every recovery message.
- [ ] In Wait Mode, test correct notes, wrong notes, chords, held notes, early release, notes held too long, and retry feedback.
- [ ] In Performance Mode, test early, late, wrong, missed, correct, chord-timing, and duration feedback.
- [ ] Confirm the feedback banner wraps and never ends with an ellipsis.
- [ ] Complete a perfect attempt and an attempt with mistakes when practical.
- [ ] Check every result statistic, save state, Retry, Done, and View Full Result action.
- [ ] Confirm What to Work On and How to Improve are translated with fully readable suggestions.
- [ ] Confirm Wait Mode explains that its result is not scored or saved.
- [ ] Confirm View Full Result opens the localized Practice Result detail screen.
- [ ] Check AR Practice in light and dark modes at narrow and wide landscape sizes for clipping or overflow.

### Practice Results

- [ ] Open Practice Results in English and Filipino with no saved results and confirm the empty state is translated.
- [ ] Open it with Sight Reading, Synthesia, and AR Performance results when available.
- [ ] Confirm the app bar, result-type chips, search field, cards, dates, counts, and suggestions are translated.
- [ ] Confirm score titles, note names, percentages, durations, and stored technical values remain unchanged.
- [ ] Confirm the AR Performance badge fits in English and Filipino without a right-overflow warning.
- [ ] Search using part of a score title, clear the search, and verify the no-match state.
- [ ] Open Filters and test every Date, Accuracy, Source, and Sort option in both languages.
- [ ] Confirm Clear All, Reset, and Apply Filters remain fully visible and usable.
- [ ] Confirm long Filipino labels, card titles, chips, and suggestions wrap without ellipses.
- [ ] Swipe a result, cancel its delete dialog, then delete a disposable result.
- [ ] Confirm the Delete action is red and deletion failures display a localized message.
- [ ] Open Delete All, cancel once, and verify both actions remain visible before testing deletion with disposable data.
- [ ] Open a result detail screen and check its summary, statistics, What to Work On, and How to Improve sections.
- [ ] Expand Notes to Review and verify issue types, clef names, expected/played notes, timing, and error states.
- [ ] Confirm dates and times follow the selected locale after switching languages.
- [ ] Check the library, filter sheet, dialogs, cards, and detail screen in light and dark modes at narrow widths.

### Music Sheets Library

- [ ] Open Music Sheets with at least one saved sheet.
- [ ] Confirm the app bar, library heading, description, sheet metadata, date, and menu actions are translated.
- [ ] Confirm one-page and multiple-page labels display correctly.
- [ ] Open the rename dialog and test its empty-title validation.
- [ ] Rename a sheet and confirm the success message is translated.
- [ ] Open the three-dot menu and confirm it contains Rename but not Delete.
- [ ] Swipe a sheet card right and cancel the delete confirmation.
- [ ] Swipe it right again, confirm deletion, and confirm only that sheet is removed.
- [ ] Trigger a delete failure if safely possible and confirm the card remains visible with a translated error.
- [ ] Open Music Sheets with an empty library and confirm the empty state is translated.
- [ ] Confirm the Add Music Sheet button opens the localized Capture/Upload screen.

### Music Sheet Viewer

- [ ] Open a PDF music sheet.
- [ ] Open an image-based music sheet with multiple pages.
- [ ] Confirm Play, the play-mode dialog, page labels, and retry states are translated.
- [ ] On an unconverted sheet, choose Play → Synthesia and confirm a snackbar appears without opening Synthesia.
- [ ] On a converted sheet with a missing MIDI file, choose Synthesia and confirm the missing-file snackbar appears without navigation.
- [ ] Confirm Original and Recognized labels are translated when a recognized PDF exists.
- [ ] Open AR Practice, Sight Reading, and Synthesia and confirm all three follow the selected language.

### Capture/Upload

- [ ] Open Add Sheet from the Music Sheets app bar.
- [ ] Open Add Sheet from the drawer.
- [ ] Confirm the header, PDF option, camera option, limits, and capture tips are translated.
- [ ] Select one valid PDF and confirm its file metadata and page count are translated.
- [ ] Preview the selected PDF and close the preview.
- [ ] Remove the selected PDF using the swipe confirmation.
- [ ] Select a PDF again and use Delete All, then cancel and confirm each path.
- [ ] Try a PDF larger than 20 MB and confirm the localized size error.
- [ ] Try a PDF with more than 20 pages and confirm the localized page-limit error.
- [ ] Try an invalid or locked PDF and confirm the localized read error.
- [ ] Capture one valid page and confirm its metadata is translated.
- [ ] Capture multiple pages and confirm the count updates.
- [ ] Preview and remove a captured image.
- [ ] Confirm PDF and captured images cannot be combined and the warning is translated.
- [ ] Tap Save Sheet, submit an empty title, and confirm the localized validation message.
- [ ] Save a valid sheet and confirm progress, success dialog, and navigation back to Music Sheets.
- [ ] Start Upload Sheet from the Home drawer, finish an upload, tap Done, and confirm Music Sheets opens instead of Home.
- [ ] Trigger a save failure if safely possible and confirm the localized failure dialog.
- [ ] Repeat the main PDF and camera paths in English and Filipino.
- [ ] Check the screen in light and dark modes and look for clipped Filipino text.

### OMR Translation

- [ ] Open the initial Translate confirmation and cancel it.
- [ ] Start translation and confirm the loading dialog is translated.
- [ ] Confirm the success dialog and singular/plural note and part counts.
- [ ] Open the Reconvert confirmation and cancel it.
- [ ] Confirm failed OMR operations show a localized error instead of a raw backend exception.

### Audio Preview

- [ ] Play, pause, seek, and stop the translated audio preview.
- [ ] Confirm status text and Play/Pause/Stop tooltips are translated.
- [ ] Confirm an unavailable audio file shows a localized playback error.

### Persistence and Compatibility

- [ ] Confirm Firestore stores `languageCode: "fil"` after selecting Filipino.
- [ ] Fully close and reopen the app and confirm Filipino is restored.
- [ ] Switch back to English and confirm Firestore stores `languageCode: "en"`.
- [ ] Sign out and confirm the login screen returns to English.
- [ ] Sign in with a different account and confirm that account's own language is loaded.
- [ ] Check the localized drawer and Music Sheets screens in both light and dark modes.
- [ ] Confirm non-localized features remain usable even though their text is still English.

## Deferred Verification

- [ ] Re-run `flutter gen-l10n` after the latest AR Practice and Practice Results localization changes.
- [x] Run dependency resolution if the local SDK requires a lockfile update.
- [ ] Format changed Dart files.
- [ ] Run `flutter analyze`.
- [ ] Run automated tests.
- [ ] Perform manual English and Filipino review.

The verification tasks above were intentionally not performed during this implementation pass.
