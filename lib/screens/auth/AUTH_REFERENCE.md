# Authentication Feature Reference

This document describes the Authentication feature as it currently works.

## 1. Purpose

Authentication lets a person:

- register with a username, email address, and password;
- verify the email address through Firebase;
- create a permanent SoundSight profile only after verification;
- log in to an existing completed account; and
- continue to either the assessment flow or Home.

The feature also removes or rejects incomplete registrations instead of
resuming them after the app is closed.

## 2. Complete user flow

### App startup

1. The app initializes Firebase.
2. It checks whether Firebase still has a signed-in user from an earlier app
   session.
3. An unverified user is treated as an unfinished registration.
4. A verified user without a `/users/{userId}` document is also treated as an
   unfinished registration.
5. The app tries to delete an unfinished Firebase Authentication account.
6. If deletion fails, the app signs that user out.
7. The first visible screen is always Login.

The app does not automatically open Home just because Firebase remembers a
completed signed-in user. The current startup route is always Login.

### Registration

1. The user opens Register from Login.
2. The user enters a username, email address, password, and matching password.
3. The user may open the Terms and Privacy Policy dialogs.
4. The user must check the agreement box.
5. Tapping **Create Account** first validates the form.
6. A confirmation dialog asks whether the account should be created.
7. After confirmation, Firebase Authentication creates a provisional account.
8. The app asks Firebase to send an email-verification link.
9. A **Check Your Email** dialog appears.
10. The app opens the Email Verification screen.

At this point, an Authentication record exists in Firebase, but the permanent
SoundSight profile document does not exist yet.

### Email verification

1. The user opens the newest email sent by Firebase.
2. The user taps the verification link.
3. The user returns to SoundSight.
4. The user taps **Check Verification**.
5. The app reloads the Firebase user to obtain the newest verification status.
6. If verified, the app refreshes the Firebase ID token.
7. The app creates `/users/{userId}` with the initial profile fields.
8. A completion dialog tells the user to log in.
9. The app signs the user out and opens Login.

If Firebase still reports the email as unverified, the app keeps the user on
the verification screen and asks them to open the newest email and try again.

### Login

1. The user enters an email address and password.
2. Firebase Authentication checks the credentials.
3. The app reloads the user and checks `emailVerified`.
4. An unverified account is deleted and the user is sent to Register.
5. A verified account without `/users/{userId}` is also deleted and the user is
   sent to Register.
6. For a completed account, the app loads the current assessment record.
7. A completed or expired assessment opens Home.
8. No assessment record opens the assessment entry screen for a new attempt.
9. An active assessment opens the assessment entry screen so it can offer its
   existing resume behavior.

There is currently no Forgot Password action in Login.

## 3. Temporary local information

### Login screen memory

- the entered email address;
- the entered password; and
- whether the password is hidden or visible.

### Register screen memory

- username;
- email address;
- password;
- confirmation password;
- whether the password is hidden or visible; and
- whether the Terms and Privacy Policy box is checked.

### Email Verification screen memory

- the username passed from Register;
- the password passed from Register, used only to authenticate account
  deletion when registration is cancelled;
- the 30-second resend countdown;
- the resend timer; and
- whether checking, resending, or cancelling is currently in progress.

These screen values are not saved to Firestore, local preferences, or a local
file. Closing the app loses the form and countdown state. The password is never
written to Firestore by this feature.

Firebase Authentication can remember its own signed-in session. The startup
cleanup uses that session only to find and remove an unfinished registration.

## 4. When information is saved permanently

### Provisional Firebase Authentication account

Firebase Authentication creates an account before the email is verified. It
contains the Firebase-generated UID, email address, Firebase-managed password,
and an initially false email-verification status.

This provisional account is intended to be removed when registration is
cancelled, the app restarts before registration is completed, or the user tries
to log in while still unverified.

### Permanent SoundSight profile

The `/users/{userId}` document is created only after all of these happen:

1. Firebase reports `emailVerified == true`;
2. the app refreshes the user's ID token; and
3. the user taps **Check Verification** successfully.

Reading the email or merely opening its link does not create the Firestore
profile until the app performs this check.

Terms and Privacy Policy acceptance is required locally, but the current code
does not save an acceptance field or timestamp.

## 5. Firebase paths used

| Information | Firebase location |
| --- | --- |
| Email, password, UID, and verification status | Firebase Authentication user |
| Permanent SoundSight profile | `/users/{userId}` |
| Assessment state checked after login | `/users/{userId}/assessment/current` |

Authentication does not upload or download Firebase Storage files.

## 6. Created and updated fields

### Authentication account

Firebase Authentication manages:

- `uid`;
- `email`;
- the password; and
- `emailVerified`.

Firebase changes `emailVerified` after the verification link succeeds. The app
only reloads the account and reads that value; it does not set the value itself.

### `/users/{userId}` created after verification

| Field | Initial value |
| --- | --- |
| `uid` | Firebase Authentication UID |
| `username` | trimmed username entered during registration |
| `profileImageUrl` | `null` |
| `email` | authenticated Firebase email |
| `role` | `piano_player` |
| `theme` | `light` |
| `skillLevel` | `null` |
| `preferredNotation` | `null` |
| `accountStatus` | `active` |
| `createdAt` | Firestore server timestamp |
| `updatedAt` | Firestore server timestamp |

The verification screen uses a normal `set`, not a merge. The expected flow is
that the document does not exist yet. If a document did already exist at the
same path, this write would replace its existing fields.

Login does not directly update these profile fields. It asks the Assessment
service to load the current assessment, and that separate service may refresh
assessment timing or finalize an expired assessment.

## 7. Client-side validation

### Login validation

- email is required;
- email must have a valid email format;
- password is required; and
- password must contain at least 6 characters.

Firebase then performs the real credential check.

### Registration validation

- username cannot be empty;
- email is required and must have a valid format;
- password must contain at least 8 characters;
- password must contain a capital letter;
- password must contain a number;
- password must contain a supported special character;
- confirmation password must match; and
- the agreement checkbox must be checked.

Firebase independently checks whether the email can be used and whether its
Authentication requirements are satisfied.

### Verification validation

The app does not trust a local button press as proof. It reloads the Firebase
user, checks Firebase's `emailVerified` value, and refreshes the ID token before
creating the Firestore profile.

## 8. Firestore Rules protection

The current local Firestore Rules define a verified user as someone who:

- is signed in; and
- has `email_verified == true` in the Firebase ID token.

For `/users/{userId}`:

- the signed-in UID must match the document ID;
- an unverified user cannot create, read, update, or delete the profile;
- profile creation permits `skillLevel` only when it is missing or `null`; and
- later `skillLevel` changes are restricted by the assessment rules.

The rules protect ownership and the initial skill-level state. They do not
currently validate every registration field, such as username, email, role,
theme, or account status, during profile creation.

Storage Rules also require a verified account for protected app files, but the
Authentication screens do not access Storage themselves.

## 9. Status and routing decisions

Authentication does not calculate XP or a skill level.

After a valid login, routing uses the assessment status:

- `completed` opens Home;
- `expired` opens Home because the Assessment service has already handled the
  expired result;
- `inProgress` opens the assessment entry screen with the saved attempt; and
- no attempt opens the assessment entry screen without an existing attempt.

## 10. Cancel, restart, failure, and retry behavior

### No verification skip

There is no way to skip email verification and create the Firestore profile.

### Resending verification email

- the resend button starts with a 30-second countdown;
- it is disabled during the countdown;
- a successful resend starts another 30-second countdown;
- checking, resending, and cancelling disable the other actions while busy;
  and
- Firebase rate limits can still require a longer wait than the visual timer.

The timer is local and is not preserved after closing the app.

### Cancelling registration

The system Back action and **Cancel Registration** use the same behavior:

1. the app reauthenticates the current user with the registration email and
   temporarily held password;
2. it deletes the Firebase Authentication account; and
3. it returns to a fresh Register screen.

If deletion fails, the user stays on the verification screen and receives a
friendly error message.

### Closing the app during registration

The app does not resume the Register or Email Verification screen. On the next
launch, startup cleanup tries to delete:

- an unverified Firebase Authentication account; or
- a verified Authentication account that still has no `/users/{userId}`
  profile.

The visible startup screen remains Login. The user must open Register and begin
again.

If automatic deletion fails, the app signs the provisional user out. A leftover
unverified account may still exist in Firebase Authentication.

### Registering again with a leftover account

If Firebase says the email is already in use, registration tries to sign into
that account using the newly entered password. When the password matches and
the account is unverified, the app deletes the leftover account and creates a
fresh one.

If the password does not match, or the existing account is already verified,
the app reports that the email is already in use instead of taking over the
account.

### Verification or network failure

- failure to send the first verification email causes the provisional account
  to be deleted before an error is shown;
- failure while checking verification keeps the user on the verification
  screen so they can retry;
- failed resends keep the current registration and show an error;
- invalid or disabled sessions ask the user to register again; and
- Firebase rate-limit errors ask the user to wait before retrying.

The code does not define its own expiration time for a verification link. Link
validity is handled by Firebase.

## 11. What happens after completion

After successful verification and profile creation:

1. the app shows **Email Verified**;
2. the app signs the user out;
3. all earlier routes are removed;
4. Login opens; and
5. the user must log in with the newly created credentials.

The first successful login normally opens the assessment entry screen because
a newly created profile does not yet have an assessment attempt.

## 12. Simple example

Ana registers with the username `Ana`, a valid email, and a valid password.
Firebase first creates a provisional Authentication account and sends the
verification email. There is still no `/users/{Ana's UID}` document.

Ana taps the email link, returns to SoundSight, and taps **Check Verification**.
Firebase reports that the email is verified, so SoundSight creates the user
document with `skillLevel: null`, signs Ana out, and opens Login. After Ana logs
in, the app sends her to the assessment entry screen.

If Ana closes the app before finishing verification, the verification screen is
not restored. On the next launch, SoundSight attempts to delete the unfinished
Authentication account and shows Login, so Ana must register again.
