# SoundSight Admin

Web-only Flutter app for viewing users and published compositions and managing the music library.

## Firebase setup

The app uses the same Firebase project as the SoundSight mobile app. Enable Email/Password sign-in in Firebase Authentication. Create each admin account in Firebase Authentication, copy its UID, then create `admins/{uid}` in Firestore with the Boolean field `enabled: true`. Email verification is not required for admin access. The Firestore and Storage rules use the admin document to authorize operations. There is no self-registration page.

Music library metadata is stored in `available_pieces`. The four files for each piece are stored under `pieces/{pieceId}/` in Firebase Storage.

## Run

From this directory, run `flutter pub get` and `flutter run -d chrome`. The mobile app is a separate Flutter package with its own dependencies.
