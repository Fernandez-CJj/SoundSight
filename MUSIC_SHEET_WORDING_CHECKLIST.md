# Music Sheet User-Friendly Wording Checklist

## Implemented

- [x] Replace Translate with Convert.
- [x] Replace Reconvert with Convert Again.
- [x] Remove generated file-format details from conversion and reconversion dialogs.
- [x] Remove Firebase from Music Sheet loading messages.
- [x] Remove Audiveris from conversion messages.
- [x] Remove backend and translation-service terminology from conversion errors.
- [x] Replace technical missing-file errors with practice-mode guidance.
- [x] Rename the Recognized sheet view to Converted.
- [x] Apply the simplified wording in English and Filipino.
- [x] Replace the default purple Converted/Original selector with a control that uses the active app theme.
- [x] Give Converted and Original equal-width responsive segments.
- [x] Allow translated toggle labels to wrap without ellipses.
- [x] Make Original and Converted PDF previews clickable.
- [x] Open clicked PDFs in a large themed dialog.
- [x] Keep PDF scrolling and zooming available inside the dialog.
- [x] Keep the Play button floating above the selected Music Sheet screen.

## Manual Test Checklist

- [ ] Run `flutter gen-l10n`, then fully restart the app.
- [ ] Open the Music Sheets screen in English and Filipino.
- [ ] Check the library load-error message in both languages.
- [ ] Open an unconverted music sheet and verify the Convert status card.
- [ ] Tap Convert and verify that the dialog does not list generated file formats.
- [ ] Check the conversion loading, success, and failure dialogs.
- [ ] Open a converted sheet and verify the Converted and Original tabs.
- [ ] Confirm the selected segment follows the light theme colors and has readable contrast.
- [ ] Confirm the selected segment follows the dark theme colors and has readable contrast.
- [ ] Confirm Converted and Original remain centered and unclipped in English and Filipino.
- [ ] Switch between Converted and Original and verify the correct PDF is displayed.
- [ ] Tap the inline PDF preview and confirm the large dialog opens.
- [ ] Scroll through every PDF page inside the dialog.
- [ ] Zoom and pan the PDF inside the dialog.
- [ ] Close the dialog using its Close button and by tapping outside it.
- [ ] Confirm captured-image sheets remain unchanged and still scroll through every page.
- [ ] Confirm the floating Play button remains visible while scrolling.
- [ ] Tap Convert Again and verify that the dialog does not list generated file formats.
- [ ] Check the audio preview loading, playing, paused, and idle messages.
- [ ] Attempt to open each practice mode before conversion.
- [ ] Attempt to open a practice mode when required files are unavailable.
- [ ] Check all updated messages in light and dark modes.
- [ ] Confirm Filipino text wraps without clipping or ellipses.

## Deferred Verification

- [ ] Format changed Dart files.
- [ ] Run `flutter analyze`.
- [ ] Run automated tests.
