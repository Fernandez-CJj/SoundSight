# Home Screen Feature Reference

This document describes the Home Screen as it currently works.

## 1. Purpose

The Home Screen is SoundSight's main dashboard after login or assessment entry.

It lets the user:

- see their username and current skill level;
- open Practice;
- open music-sheet, capture, upload, and composition features;
- preview recent community compositions;
- open the full published-composition list;
- open Profile; and
- use the app drawer for the other main features, theme selection, and logout.

The Home Screen does not calculate a skill level, XP, practice score, or recommendation.

## 2. Complete user flow

### Opening Home

The Home Screen can be opened:

- after a login that is allowed to continue to Home;
- after continuing from the assessment entry screen; or
- from the app drawer.

When it opens:

1. The local theme initially uses the value passed by the previous screen, or light mode when no value was supplied.
2. The app reads the signed-in user's `/users/{userId}` document.
3. The saved `theme`, `username`, and `skillLevel` replace the initial local values.
4. A greeting, skill-level card, Practice banner, quick-action grid, and Community Compositions section are displayed.

The greeting always says **Good Morning**. It does not currently change according to the actual time.

### Profile

The profile icon in the app bar opens the Profile screen and passes the Home Screen's current colors.

The drawer's profile header also opens Profile.

Returning from Profile does not call `loadHomeData()` again. A username, skill-level, profile-picture, or theme change made on Profile may therefore not appear on this existing Home Screen instance until Home is recreated.

### Practice banner

Tapping **Start Practice** opens `PracticeScreen`.

The banner changes its background image and text/button colors for light or dark mode. Its message and destination are fixed; it does not choose a practice activity based on the user's skill level.

### Quick Actions

The current quick-action grid contains:

- **Music Sheets** - opens the user's music-sheet library;
- **Upload Sheet** - opens Capture/Upload Sheet with Upload selected initially;
- **Capture Sheet** - opens Capture/Upload Sheet with Capture selected initially;
- **Saved Sheets** - currently has no action connected;
- **Composition** - opens My Compositions; and
- **Practice Results** - currently has no action connected.

The grid displays four columns when at least 520 logical pixels wide and three columns on narrower layouts.

### Community Compositions

1. The section starts a live Firestore stream when its widget is created.
2. It requests the three most recently published compositions, ordered by `publishedAt` from newest to oldest.
3. Each card shows the author, current version, title, key, tempo, and live like count for that version.
4. Tapping a card opens the Published Composition Viewer.
5. Tapping **See All** opens the full Published Compositions screen.
6. Tapping **Play** loads the current version's stored note list and plays it with the app's piano playback service.
7. While playback is loading, the button shows a spinner. The same button becomes **Stop** once playback begins.

Only one community composition can be prepared or played by this Home section at a time. While the playback controller is busy, every community Play button is disabled.

The Home cards only display like counts. Liking, commenting, saving, viewing the PDF, and unpublishing happen after opening the Published Composition Viewer or other composition screens.

### Drawer actions

The Home drawer provides navigation to:

- Home;
- Music Sheets;
- Upload / Capture Sheet;
- Practice;
- MIDI;
- Flyaway;
- Saved Sheets;
- Composition;
- Published Compositions; and
- Profile.

The drawer's **Practice Results** row currently has an empty action.

The drawer also lets the user change Dark Mode and log out. Logout asks for confirmation, signs out through Firebase Authentication, opens Login, and removes the older routes.

## 3. Temporary local information

### Home Screen memory

- whether dark mode is active;
- the loaded username;
- the loaded skill level; and
- the color and asset choices derived from the current theme.

### Community section memory

- the live stream of the three recent published compositions;
- the currently loading or playing composition version;
- whether the playback controller is busy; and
- temporary playback data and generated audio owned by the playback service.

These values are not Home Screen records in Firebase. Closing the screen disposes the community playback controller and stops its playback resources.

## 4. When information is saved permanently

The Home Screen's normal dashboard, quick actions, community list, and playback do not save anything.

The only direct permanent write available through Home is the drawer's Dark Mode switch:

1. the local Home colors change immediately;
2. the app writes the new theme to `/users/{userId}`; and
3. `updatedAt` receives a Firestore server timestamp.

Community composition content, likes, comments, bookmarks, and private compositions are saved by their own composition screens and services, not by the Home Screen cards.

## 5. Firebase paths used

| Information | Path |
| --- | --- |
| Home username, skill level, and theme | `/users/{userId}` |
| Recent public composition summaries | `/compositionPosts/{postId}` |
| Current version notes used for Home playback | `/compositionPosts/{postId}/versions/{versionNumber}` |
| Live like count for the current version | `/compositionPosts/{postId}/versions/{versionNumber}/likes/{likingUserId}` |

The Home Screen also uses local image assets for its logo and Practice banner. The card's direct preview playback uses stored version notes and the app's piano samples rather than downloading the published PDF.

## 6. Fields read, created, and updated

### User document fields read

The Home Screen reads:

- `theme`;
- `username`; and
- `skillLevel`.

Missing `theme` uses `light`. Missing username and skill level use empty strings.

### User document fields updated

Changing Dark Mode writes:

- `theme`, as either `dark` or `light`; and
- `updatedAt`, as a Firestore server timestamp.

The operation uses merge mode and preserves the user's other fields. If the user document did not exist, this operation could create a document containing only those theme fields.

### Published composition fields read

The recent cards read these top-level post values:

- document ID;
- `compositionId`;
- `ownerId`;
- `authorName`;
- `authorProfileImageUrl`;
- `currentVersion`, with `versionNumber` also accepted by the model;
- `title`;
- `tempo`;
- `key`;
- `beatsPerMeasure`;
- `beatUnit`;
- `measureCount`;
- `noteCount`;
- `pdfStoragePath`; and
- `publishedAt`.

The Home Screen does not create or update those fields.

For playback, it reads `notes` and the other composition information from the selected current-version document. Like documents are counted but are not created or removed from the Home card.

## 7. Client-side validation and defaults

The Home Screen contains no editable form, so it performs little direct input validation.

### User data

- The saved theme activates dark mode only when its value equals `dark`.
- Any other or missing theme value displays light mode.
- Username and skill level default to empty text when missing.

The current user-data load expects username and skill level to have compatible string values. It has no friendly recovery for incorrect field types.

### Published composition cards

When post fields are absent, the model uses defaults such as:

- author: `SoundSight Musician`;
- title: `Untitled Composition`;
- current version: `1`;
- tempo: `80`;
- key: `C Major`;
- time signature values: `4/4`; and
- measure count: `1`.

Playback requires the current version document to exist and contain a non-empty `notes` list. The loaded composition model and playback service then validate whether the note data can be used.

## 8. Firestore Rules protection

### User document

The signed-in user can read or update only the `/users/{userId}` document whose ID matches their Firebase Authentication ID.

The Home theme update does not change `skillLevel`, so it uses the ordinary owner-update rule. The current Rules do not independently restrict `theme` to `dark` or `light`; that choice is made by the Flutter code.

### Community compositions

Top-level composition posts and their version documents can be read by any authenticated user. Direct client creation, update, and deletion are denied because publishing is handled by the backend.

Like documents can also be read by authenticated users, which allows the Home cards to count them.

The Home Screen performs no Firebase Storage operation itself. Storage permissions used after opening the composition viewer belong to the published-composition feature.

## 9. How displayed information is selected

### Theme

```text
saved theme == "dark" -> dark colors
anything else         -> light colors
```

The theme determines the logo, background and surface colors, text colors, and which Practice banner image is used.

### Skill level

The Home Screen displays the `skillLevel` string exactly as loaded. It does not capitalize it, replace an empty value with Beginner, or calculate it from assessment scores.

### Recent community items

```text
order by publishedAt descending
take the first 3 posts
```

The like count is the number of documents currently found in the current version's `likes` subcollection.

No home dashboard score, level progress, recommendation ranking, or completion percentage is calculated.

## 10. Resume, failure, and retry behavior

### Resume and expiration

The Home Screen has no resumable task or expiring local session. It reads current user and community data each time a new Home Screen instance is opened.

Published compositions update through a live Firestore stream while the section remains open.

### User-data loading failure

The direct `/users/{userId}` read has no loading indicator, `try/catch`, error message, or retry button in the current Home code. Until a successful load, the greeting and skill card use their initial empty values.

If no Firebase user is signed in, the user-document load returns immediately. The dashboard still builds, but protected community reads can fail under Firestore Rules.

### Community loading failure

- A spinner is shown while the recent-composition stream is waiting.
- An empty message is shown when no posts exist.
- A cloud-off message is shown when the stream reports an error.
- There is no explicit Try Again button; the live stream may recover when Firestore supplies a later snapshot, or the screen can be reopened.
- A like-count stream error appears as a count of `0` because the card uses zero when no count data is available.

### Playback failure

- Missing or empty current-version note data shows **This version has no playback data. Republish it first.**
- Other playback failures show **The published composition could not be played.**
- The user can tap Play again after the controller returns to its idle state.

### Theme-write failure

The Home colors change before the Firebase write completes. The drawer method does not catch a write failure or restore the earlier theme, so the screen may temporarily show a theme that was not saved permanently.

## 11. What happens after actions complete

Navigation actions push the selected feature on top of Home. Pressing Back in that feature normally returns to the same Home Screen state.

When community playback ends or is stopped, the card returns to its Play state. No playback position or listening history is saved.

After a successful theme write, future screens that load the user document can use the saved theme.

After logout, the Firebase session ends and Login replaces the full navigation history.

## 12. Simple example

Suppose Ana's user document contains:

```text
username: "Ana"
skillLevel: "intermediate"
theme: "dark"
```

When Home opens:

1. The screen changes to dark colors.
2. The greeting displays **Good Morning, Ana**.
3. The skill card displays **intermediate** exactly as stored.
4. Firestore supplies up to three newest community posts.
5. Ana taps Play on version 2 of **Morning Theme**.
6. The app reads `/compositionPosts/{postId}/versions/2` and plays its stored notes.
7. When playback finishes, nothing new is saved to Ana's user document.
8. If Ana changes Dark Mode to light in the drawer, only `theme: light` and `updatedAt` are written by Home.
