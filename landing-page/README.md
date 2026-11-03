# SoundSight landing page — design preview

A standalone, light-only HTML/CSS/JavaScript website. No dependencies, build step,
network services, or deployment configuration are required.

## Preview

Open `index.html` directly in a modern browser. For a local HTTP preview, run this
from the `landing-page` folder and open http://localhost:4173:

```powershell
python -m http.server 4173 --bind 127.0.0.1
```

## Included interactions

- Three practice-mode tabs with arrow-key and Home/End navigation.
- Full-size screenshot viewer with Escape, backdrop dismissal, and focus restoration.
- Download panel with version, Android requirement, file size, and checksum.
- Native modal behavior: focus containment, Escape, close button, backdrop click,
  and focus restoration.
- Installation guide links, section navigation, and native expandable FAQs.
- Expandable AR calibration walkthrough using the four existing in-app guide assets.
- Responsive layouts and reduced-motion support.
- Scroll reveals: sections fade and slide upward once as they enter view, with
  a short stagger for cards and steps entering together. The AR guide's contents
  also reveal when opened. Content stays visible without JavaScript, and reveals
  are disabled for reduced-motion preferences and printing.

## Design notes

`styles.css` defines interface color variables from `lib/theme/app_colors.dart`.
Secondary gray text is used on white surfaces; dark text is used on the light-gray
background for readable contrast. The logo is copied from the app.

All eight supplied JPG screenshots are included: Home, Sight Reading, and AR Practice
in the hero, three practice
modes in the tabs, and lessons, converted recording, results, and composition in
the feature cards. Images retain their original proportions and files. Click a
screenshot to enlarge it; without JavaScript the link opens the original image.
There are no invented app captures or product statistics.

The hero combines a portrait home screen and two landscape practice screens in
a responsive three-screen gallery. Each opens in the same full-size viewer.
Background depth comes from faint staff lines, soft tints of the existing app
accent colors, and restrained shadows. Card surfaces stay white for readability.

The AR setup guide reuses the original images in `assets/calibration/`: phone
mounting is an illustration, while the other three images show calibration UI.
They explain setup and do not replace a screenshot of AR notes during practice.
Guide captions follow the current walkthrough and note that button wording in the
images may differ. AR practice needs a connected MIDI piano even when calibration
uses the manual Middle C guide.

See `assets/screenshots/README.md` for the screenshot inventory and capture notes.

## Download state

All Download buttons open the same panel. `config.js` holds the APK metadata and
an intentionally empty `downloadUrl`. Until a valid HTTPS URL is added, the panel
clearly says the download is not available. The existing 376 MB APK has not been
copied into the site, and no app files have been modified.

Deployment and real APK delivery are deferred while the layout and content are
being reviewed. The page makes no external requests, aside from an APK download
if one is configured later.
