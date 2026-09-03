# Profile Feature Reference

This document describes the Profile feature as it currently works.

## 1. Purpose

The Profile feature lets a signed-in user:

- view their username, email, and profile picture;
- view their skill rank, level, and experience progress;
- start, resume, or review their skill assessment;
- edit their username and profile picture;
- switch between light and dark mode; and
- log out.

The current **Change Password** row is visible but has no action connected to it.

## 2. Complete user flow

### Opening and loading the profile

The user can open **Profile** from the drawer or the profile icon on the home screen.

1. The screen starts with the theme passed by the previous screen.
2. It asks the assessment service for the current assessment document.
3. This assessment check can also permanently expire an overdue attempt and assign Beginner.
4. The screen then reads `/users/{userId}` from Firestore.
5. It displays the saved username, email, profile picture, skill level, level, and XP values.
6. Missing progress values use local display defaults: level `1`, XP `0`, and XP needed for the next level `100`.

Tapping the main profile picture opens a larger square view. A network picture can be zoomed from 1x to 4x. If there is no valid image, the app shows a person icon.

### Editing the profile

The edit icon and **Edit Profile** account row open the same bottom sheet.

1. The current username is editable.
2. The email is shown as read-only and cannot be changed.
3. The user may tap the avatar and select one image from the device gallery.
4. The selected image is resized to a maximum width of 1024 pixels and encoded at image quality 80 by the image picker.
5. The user taps **Save Changes**.
6. The username is trimmed and checked.
7. A confirmation dialog asks whether to save.
8. If a new image was selected, it is uploaded first.
9. The user document is then updated.
10. The sheet closes and the Profile screen updates its in-memory username and image URL.

Cancelling the bottom sheet or save confirmation leaves Firebase unchanged.

### Assessment entry

The Assessment tile changes according to the saved attempt:

- no attempt: **Start Assessment**;
- active attempt: **Resume Assessment**;
- completed attempt: **View Assessment Results**;
- expired attempt: **Assessment Expired**; or
- failed status load: **Retry Assessment Status**.

Starting the assessment creates its fixed `current` document. An active attempt can be resumed at its saved section for up to 72 hours. A completed or expired result is permanent in the current assessment logic.

When the user returns from the assessment, the Profile screen reloads the attempt and user document so a new skill level can be displayed.

### Theme preference

Changing **Dark Mode** immediately changes the Profile screen's local colors, then saves `dark` or `light` to the user document.

### Logging out

1. The user taps **Log Out**.
2. A confirmation dialog appears.
3. Cancelling keeps the session active.
4. Confirming signs out through Firebase Authentication.
5. The app opens the Login screen and removes all older routes from the navigation stack.

## 3. Temporary local information

The Profile screen temporarily holds:

- whether dark mode is active;
- username, email, and profile-image URL loaded from Firestore;
- skill level, level, current XP, and XP target;
- the loaded assessment attempt;
- whether the assessment is loading; and
- whether assessment loading failed.

The Edit Profile sheet temporarily holds:

- the username currently being typed; and
- the locally selected image file before it is uploaded.

Closing or cancelling the editor discards those unsaved changes.

The larger profile-picture dialog and loading dialogs contain no permanent data.

## 4. When information is saved permanently

### Username and profile picture

Profile changes are saved only after the user taps **Save Changes**, confirms the dialog, and the Firebase operations succeed.

If an image is selected, the file upload happens before the user-document update. Therefore, if the upload succeeds but the later Firestore update fails, `profile.jpg` may already have been replaced even though the screen reports that the profile save failed.

There is no autosave and no current option for removing a profile picture.

### Theme

The theme is saved whenever the user changes the Dark Mode switch.

The visual change happens before the Firestore request finishes. The current method does not catch a failed theme write or restore the previous switch value.

### Assessment information

Assessment progress is saved by the assessment feature when an attempt starts or a section is submitted. Loading Profile can also save expiration-related changes when an unfinished attempt has passed its 72-hour deadline.

## 5. Firebase paths used

| Information | Path |
| --- | --- |
| User profile and preference fields | `/users/{userId}` |
| Current assessment attempt | `/users/{userId}/assessment/current` |
| Profile picture file | `profilePictures/{userId}/profile.jpg` |

The profile picture's Firebase Storage download URL is stored in `profileImageUrl` inside the user document.

## 6. Created and updated fields

### User document fields read by Profile

The screen reads:

- `username`;
- `email`;
- `profileImageUrl`;
- `skillLevel`;
- `level`;
- `experiencePoints`;
- `experienceToNextLevel`; and
- indirectly, `theme`, which is passed into the screen by the surrounding app.

The Profile folder does not create the original account or its initial user document.

### Editing the profile

Every successful profile edit updates:

- `username`; and
- `updatedAt`, using a Firestore server timestamp.

When a new image was selected, it also updates:

- `profileImageUrl`.

The image URL receives a changing `v` query value based on the current time. This helps the app request the newly overwritten picture instead of displaying a cached older copy.

The email is never updated by this editor.

### Changing the theme

The theme switch updates:

- `theme`, with either `dark` or `light`; and
- `updatedAt`, using a Firestore server timestamp.

The write uses merge mode, so it preserves other user fields. If the user document were missing, this operation could create a document containing those theme fields.

### Assessment-related updates visible in Profile

The assessment feature can update `skillLevel` in the user document only after a valid completed result, or to `beginner` after expiration. It also updates `updatedAt`.

The assessment itself uses `/users/{userId}/assessment/current`. Profile does not calculate or directly edit the assessment score fields.

## 7. Client-side validation

### Username

- Spaces at the beginning and end are removed.
- The result cannot be empty.

The current Profile code does not set a maximum username length, require uniqueness, or restrict characters.

### Email

Email is read-only in the editor. This folder performs no email validation because it does not allow an email change.

### Profile picture

- The picker accepts an item from the gallery.
- It requests a maximum width of 1024 pixels and quality 80.
- The selected file is rejected when it is larger than 5 MB.

The client does not explicitly check the selected file's MIME type. Firebase Storage Rules perform that check during upload.

There is a small boundary difference: the app rejects files **larger than** 5 MB, but Storage Rules require the upload to be **smaller than** 5 MB. A file exactly 5 MB can pass the app check and still be rejected by Storage.

### Saved profile values

The Profile screen uses defaults when progress fields are missing:

- `level`: `1`;
- `experiencePoints`: `0`; and
- `experienceToNextLevel`: `100`.

It expects username, email, and skill level to be strings when present. There is no friendly validation recovery if the user document contains incompatible field types.

## 8. Firestore and Storage Rules protection

### User document

Firestore Rules require a signed-in user whose ID matches `{userId}` to create, read, update, or delete that user document.

A user-document creation cannot assign a non-null `skillLevel`.

Ordinary updates, including username, image URL, and theme changes, are allowed for the owner. The current Rules do not restrict their formats, lengths, or allowed top-level field names.

`skillLevel` has stronger protection. An update that changes it must change only:

- `skillLevel`; and
- `updatedAt`.

The new level must exactly match the final level in a completed `/assessment/current` document, or it must be `beginner` for a permanently expired attempt. `updatedAt` must equal Firestore's request time.

### Assessment document

The assessment Rules allow only the owner to access the fixed `current` attempt and validate its lifecycle, section order, submitted data, scoring fields, and server timestamps. Assessment documents cannot be deleted from the client.

### Profile picture

Storage Rules require authentication to read any profile picture.

Creating or replacing a picture additionally requires:

- the signed-in user's ID to match the `{userId}` folder;
- a file smaller than 5 MB; and
- a content type beginning with `image/`.

Only that owner can delete the file. The current Profile UI does not provide a delete-picture action.

## 9. How levels and progress are displayed

The Profile folder does not award XP or calculate a new player level. It displays the values already stored in the user document.

If `skillLevel` is empty, the displayed rank is `Beginner`. Otherwise, the first letter is capitalized for display.

The XP progress bar uses:

```text
progress = experiencePoints / experienceToNextLevel
```

The result is limited to the range `0` through `1`. If `experienceToNextLevel` is zero or negative, progress is shown as zero.

Remaining XP uses:

```text
remaining XP = experienceToNextLevel - experiencePoints
```

That result is limited between zero and the XP target.

For example, `40` XP out of `100` displays a 40% progress bar and **60 XP needed**.

Assessment scoring and final skill-level calculation happen in the Assessment feature. Profile only loads and displays the resulting `skillLevel`.

## 10. Resume, expiration, failure, and retry behavior

### Resume and expiration

- An Edit Profile form cannot be resumed after it is cancelled or closed.
- Theme changes are not stored as a separate unfinished operation.
- An in-progress assessment resumes from its saved section.
- The assessment has a 72-hour window based on Firestore server time.
- When an unfinished attempt expires, it becomes permanently expired and the user receives Beginner.
- A completed or expired assessment has no retry in the current assessment design.

### Profile loading failure

If loading the assessment status fails, Profile still tries to load the user document. The Assessment tile becomes **Retry Assessment Status**, and tapping it calls the full profile-loading method again.

The direct user-document read is not wrapped in a local error handler. The current Profile screen has no dedicated retry panel for that read.

### Editing failure

A failed profile save closes the non-dismissible saving dialog, keeps the edit sheet open, and shows **Unable to save profile changes. Please try again.** The user can tap Save Changes again.

There is no automatic retry queue.

### Image display failure

If a network profile image cannot be displayed, the UI falls back to the person icon. It does not automatically repair or remove the saved URL.

## 11. What happens after actions complete

After a successful profile edit, the edit sheet closes and returns the new username and image URL to Profile. The visible header updates immediately from those returned values.

After returning from Assessment, Profile reloads both assessment status and user fields.

After changing the theme, the Profile screen changes appearance immediately and the preference is written to Firestore.

After logout, Firebase Authentication ends the session, the Login screen opens, and previous routes are removed so the user cannot navigate back into the signed-in screens.

## 12. Simple example

Suppose Ana changes her username from **Ana** to **Ana Keys** and selects a new 2 MB photo.

1. The new text and local photo preview exist only in the edit sheet.
2. Ana taps **Save Changes** and confirms.
3. The app uploads the image to `profilePictures/ana123/profile.jpg`, replacing the previous file at that path.
4. It obtains the download URL and adds a new `v` query value.
5. It updates `/users/ana123` with `username`, `profileImageUrl`, and `updatedAt`.
6. The edit sheet closes and the Profile screen displays **Ana Keys** and the new picture.
7. Her email, skill level, level, and XP fields remain unchanged.
