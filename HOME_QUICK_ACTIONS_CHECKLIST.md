# Home Quick Actions Checklist

## Implemented

- [x] Place Upload Sheet first.
- [x] Open the Upload Sheet screen without automatically opening the file picker.
- [x] Keep both Upload PDF and Capture Pages available from the Upload Sheet screen.
- [x] Place Music Sheets second.
- [x] Replace Capture Sheet with Practice Results in the third position.
- [x] Place Composition fourth.
- [x] Place Published Compositions fifth.
- [x] Place Saved Sheets last.
- [x] Keep all quick-action labels localized.

## Manual Test Checklist

- [ ] Open Home in English and verify all six quick actions are in the requested order.
- [ ] Switch to Filipino and verify the order remains the same.
- [ ] Tap Upload Sheet and confirm the upload/capture selection screen opens.
- [ ] Confirm Upload Sheet does not immediately open the device file picker.
- [ ] From Upload Sheet, confirm Upload PDF opens the file picker.
- [ ] From Upload Sheet, confirm Capture Pages opens the camera flow.
- [ ] Tap Music Sheets and confirm the personal sheet library opens.
- [ ] Tap Practice Results and confirm the results screen opens.
- [ ] Tap Composition and confirm My Compositions opens.
- [ ] Tap Published Compositions and confirm the published library opens.
- [ ] Tap Saved Sheets and confirm saved compositions open.
- [ ] Check the quick-action grid in light and dark modes.
- [ ] Confirm English and Filipino labels are centered and not clipped.

## Deferred Verification

- [ ] Format changed Dart files.
- [ ] Run `flutter analyze`.
- [ ] Run automated tests.
