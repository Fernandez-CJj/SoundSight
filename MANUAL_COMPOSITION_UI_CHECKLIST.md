# Manual Composition UI Checklist

## Implemented

- [x] Size the measure-actions popup from its translated action labels.
- [x] Keep the English popup compact while giving Filipino labels the additional space they need.
- [x] Allow action labels to wrap to two lines without ellipses.
- [x] Keep icons and disabled states aligned with wrapped labels.
- [x] Preserve every existing measure action and translation.

## Manual Test Checklist

- [ ] Open a manual composition in Filipino.
- [ ] Open the Measure actions menu.
- [ ] Confirm Add Measure After is fully readable without overflow.
- [ ] Confirm Insert Measure Before is fully readable without overflow.
- [ ] Confirm Duplicate, Move Left, and Move Right are fully readable.
- [ ] Confirm Clear Measure and Delete Measure are fully readable.
- [ ] Check enabled and disabled action colors in dark mode.
- [ ] Check enabled and disabled action colors in light mode.
- [ ] Switch to English and confirm the menu remains aligned.
- [ ] Test the menu in portrait and landscape orientations.
- [ ] Confirm tapping every enabled action still performs the correct operation.

## Deferred Verification

- [ ] Format the changed Dart file.
- [ ] Run `flutter analyze`.
- [ ] Run automated tests.
