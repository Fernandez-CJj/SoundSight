# Lessons Localization Checklist

## Implemented

- [x] Localize the Practice stage-map header, progress, loading, and error states.
- [x] Localize completed, current, and locked stage states.
- [x] Localize all 16 stage titles, short titles, and descriptions.
- [x] Localize stage-detail dialogs, rank milestones, and progress messages.
- [x] Keep stage numbers, `practiceLevel`, `skillLevel`, XP, and asset paths language-independent.
- [x] Replace translated activity-string comparisons with a stable activity enum.
- [x] Localize stage-card accessibility labels.
- [x] Localize the stage contents screen and asset-type labels.
- [x] Localize the video player's controls, tooltips, and loading error.
- [x] Keep the video files and their audio/on-screen content unchanged.
- [x] Add separate Filipino quiz assets for all ten video lessons.
- [x] Preserve the same correct-answer markers and perfect-score requirement in both languages.
- [x] Localize quiz navigation, results, answers, retry guidance, and errors.
- [x] Localize lesson sight-reading titles while keeping canonical saved result data unchanged.
- [x] Display localized lesson titles in Practice Results without rewriting Firestore documents.
- [x] Allow Filipino stage text to wrap or scale without ellipses.
- [x] Add responsive padding to lesson-dialog buttons.

## Media Kept Unchanged

- [x] Lesson video picture, narration, captions, and embedded text.
- [x] MIDI, MusicXML, and sheet-music PDF content.
- [x] The existing chord cheat-sheet PDF content; only its app title and controls are localized.

## Manual Test Checklist

- [ ] Run `flutter gen-l10n`, then fully restart the app.
- [ ] Set English and open Practice from both Home and the drawer.
- [ ] Set Filipino and open Practice from both Home and the drawer.
- [ ] Check the header, overall progress, Continue button, and all-complete state in both languages.
- [ ] Check all 16 stage cards in portrait and landscape without clipped text, overflow, or ellipses.
- [ ] Open a completed, current, and locked stage and verify every dialog label and button.
- [ ] Check Stage 9 and Stage 16 rank-milestone messages at applicable skill levels.
- [ ] Open each of the ten video lessons and confirm the app controls are translated while the video itself is unchanged.
- [ ] Confirm Play/Pause, Back to Practice, Start Quiz, and View PDF remain readable in landscape.
- [ ] Open every quiz in English and Filipino and confirm the matching language file loads.
- [ ] Complete one quiz with mistakes and verify the result review, Retry, and Back to stages actions.
- [ ] Complete one quiz perfectly and confirm the next stage unlocks exactly once.
- [ ] Open each piano-performance stage and confirm the localized stage title appears in Sight Reading.
- [ ] Complete a lesson performance and confirm Practice Results shows the title in the currently selected language.
- [ ] Switch languages and confirm the same saved result changes display title without creating another result.
- [ ] Simulate a progress-load failure and confirm no raw Firebase error appears.
- [ ] Simulate a progress-save failure, retry it, and confirm the localized recovery message.
- [ ] Check every Lessons screen and dialog in light and dark modes.

## Deferred Verification

- [ ] Format changed Dart files.
- [ ] Run `flutter analyze`.
- [ ] Run automated tests.
