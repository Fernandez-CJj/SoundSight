# Music Library Localization Checklist

## Implemented

- [x] Translate the Music Library search title, heading, and description.
- [x] Translate the search hint and clear-search tooltip.
- [x] Translate signed-out, loading, empty, no-results, and failure states.
- [x] Translate Retry and missing-piece messages.
- [x] Add localized accessibility labels to library-piece cards.
- [x] Keep uploaded piece titles and musical files unchanged.
- [x] Show the complete uploaded title inside the piece screen without an app-bar ellipsis.
- [x] Translate PDF and audio-preview loading and playback states through the shared widgets.
- [x] Translate Play and the play-mode selection dialog.
- [x] Keep the play-mode dialog consistent with the existing Music Sheet and Composition dialogs.
- [x] Translate the missing practice-files snackbar.
- [x] Keep Sight Reading, Synthesia, and AR navigation behavior unchanged.

## Manual Test Checklist

- [ ] Run `flutter gen-l10n`, then fully restart the app.
- [ ] Open Music Library in English and Filipino.
- [ ] Confirm the app bar, heading, description, and search hint are translated.
- [ ] Search for a complete title and a partial title in both languages.
- [ ] Clear the search using the translated clear-search control.
- [ ] Confirm uploaded titles remain exactly as saved and are not translated.
- [ ] Check the signed-out, loading, empty-library, no-results, and load-failure states.
- [ ] Scroll beyond the first page and verify pagination loading and retry states.
- [ ] Open a piece with a long title and confirm the full title is readable in the content card without ellipses.
- [ ] Preview the audio and confirm the shared playback controls are translated.
- [ ] Confirm the PDF loads and its retry message is translated when loading fails.
- [ ] Press Play and verify the Sight Reading, Synthesia, and AR Practice labels.
- [ ] Confirm the play-mode dialog matches the existing Music Sheet and Composition play-mode dialogs.
- [ ] Select each play mode and confirm navigation still works.
- [ ] Test a piece with missing files and confirm the snackbar is translated.
- [ ] Check both screens and the dialog in light and dark modes for overflow or clipped Filipino text.

## Deferred Verification

- [ ] Format changed Dart files.
- [ ] Run `flutter analyze`.
- [ ] Run automated tests.
