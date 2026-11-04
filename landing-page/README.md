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

- Three always-visible practice-mode cards, side by side on desktop and stacked
  on smaller screens, with every preview visible without clicking.
- Download panel with version, Android requirement, and file size.
- Native modal behavior: focus containment, Escape, close button, backdrop click,
  and focus restoration.
- Installation guide links, section navigation, and native expandable FAQs.
- Twelve review placeholders in a horizontal scroll row with swipe, scrollbar,
  previous/next buttons, and keyboard navigation (Left/Right, Home/End).
  Cards show no invented quotes, names, or photos. Scrolling never starts itself.
  The heading includes all testers. Each card reserves a name and role line;
  use the reviewer's actual role, such as IT Expert or Piano Player, when supplied.
- Responsive layouts and reduced-motion support.
- Scroll reveals: sections fade and slide upward as they enter view, with
  a short stagger for cards and steps entering together. Scrolling fully away
  and returning plays the animation again. Content stays visible without
  JavaScript, and reveals are disabled for reduced-motion preferences and printing.

## Design notes

`styles.css` defines interface color variables from `lib/theme/app_colors.dart`.
Secondary gray text is used on white surfaces; dark text is used on the light-gray
background for readable contrast. The logo is copied from the app.

Seven JPG screenshots are shown: Home in the hero; lesson levels,
a video lesson, and a quiz immediately below it; and three practice modes.
Conversion, results, and composition screenshots are kept as unused assets.
Images retain their original proportions and files and are
static, non-clickable previews.
There are no invented app captures or product statistics.

The page starts with exactly three lesson screenshots: levels, video, and quiz.
They appear side by side on desktop, with the landscape video between the two
portrait screens, and stack on smaller screens. Practice modes follow, then
testimonials, getting started, installation, and FAQs.

App screenshots use Android frames throughout the page.
Portrait captures stay upright; video and practice captures use landscape frames.
Frames are CSS decoration, with original image files and proportions preserved.

The hero shows one Home screenshot inside a CSS-built Android phone frame with
rounded bezels, a small camera cutout, and side buttons. The screenshot preserves
its original proportions and is a static image without a caption. The hero has no tabs
or automatic slideshow; the practice demonstrations stay in their section below.
All page sections share the app's plain light-gray background (`#F3F3F3`), with
no gradients, accent glows, or staff-line decorations. Cards retain white surfaces.

Detailed AR setup instructions stay in the app. The landing page includes the AR
feature preview and a short requirements FAQ, including the MIDI piano connection.

See `assets/screenshots/README.md` for the screenshot inventory and capture notes.

## Download state

All Download buttons open the same panel. `config.js` holds the APK metadata and
the public `v1.0.0/app-release.apk` download URL. The panel enables the direct APK
download when this HTTPS URL is configured. The 377 MB APK stays in GitHub Releases
and is not copied into the website folder.

The page makes no external requests, aside from an APK download when configured.

## GitHub Pages and APK release

1. In `Fernandez-CJj/SoundSight`, open Settings > Pages and select GitHub Actions
   as the source.
2. Create a public release with tag `v1.0.0` and title `SoundSight 1.0.0`.
   Attach the existing `build/app/outputs/flutter-apk/app-release.apk` file.
   Upload it as a release asset, without committing it to Git or rebuilding it.
3. After publishing, copy the direct APK link into `config.js` as `downloadUrl`.
   With the tag and filename above, the expected link is
   `https://github.com/Fernandez-CJj/SoundSight/releases/download/v1.0.0/app-release.apk`.
   Verify the actual asset link before using it.
4. Commit only `landing-page/` and `.github/workflows/deploy-landing-page.yml`,
   then push to `master`. Keep unrelated app changes out of this deployment commit.
5. In the Actions tab, wait for "Deploy SoundSight landing page" to succeed.
   The site is expected at `https://fernandez-cjj.github.io/SoundSight/`.
6. While signed out, open the site and download the APK. Compare its SHA-256
   with the original, install it on Android, and check the advertised app flows.

The workflow publishes only `landing-page/`. It runs on website/workflow changes
on `master`, or manually from the Actions tab. No Flutter or backend build runs.

APK verified locally on 4 November 2026: version 1.0.0, Android 7.0+,
376,840,828 bytes (377 MB), SHA-256
`e4346de77060588ce2d08f052105b554df7878342f976533917b968a6edeedd6`.
Recheck these values if the APK changes before uploading.

The published `v1.0.0` asset was checked anonymously on 4 November 2026. Its
size and GitHub SHA-256 digest match the local APK above. The download URL
returned HTTP 200 with Android APK content type and the matching content length.
Android installation and the deployed page still need to be checked.
