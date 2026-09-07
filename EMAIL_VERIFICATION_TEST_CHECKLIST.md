# SoundSight Email Verification Manual Test Checklist

Use a different test email when a test needs a new registration. At the end of
each section, compare all three places:

- The screen and message shown by SoundSight.
- Firebase Authentication.
- Firestore `users/{uid}`.

## Required final states

- **Incomplete or cancelled registration:** no Firebase Authentication account,
  no Firestore user document, and the app starts on Login. The next registration
  starts with an empty form when Register is selected.
- **Verified registration:** the Authentication account has **Email verified**,
  exactly one matching Firestore user document exists, the app signs the user
  out, and the Login screen is shown.
- **Successful login:** only a verified Authentication account with a matching
  Firestore user document can enter the app.

## Before testing

- [ ] Use a real inbox that you can open, including its Spam folder.
- [ ] Enable Email/Password in Firebase Authentication.
- [x] Deploy the current `firestore.rules` and `storage.rules`; editing the local
  files alone does not change Firebase.
- [ ] Decide on unique test emails for successful, cancelled, and error tests.
- [ ] Fully stop and restart the app for app-close tests. Do not use hot reload.
- [ ] Keep Firebase Authentication and the Firestore `users` collection open so
  each expected database result can be checked.
- [ ] Use the latest full app build and wait for any temporary Firebase
  `too-many-requests` block to end before restarting the tests.

## A. Registration form

- [ ] **A1 — Empty fields:** Tap Create Account with empty fields. Required-field
  messages appear and no Firebase account or Firestore document is created.
- [ ] **A2 — Invalid email:** Enter an invalid email. The email validation message
  appears and Firebase is not contacted.
- [ ] **A3 — Short password:** Use fewer than 8 characters. The length message
  appears and nothing is created.
- [ ] **A4 — Missing uppercase letter:** The capital-letter message appears and
  nothing is created.
- [ ] **A5 — Missing number:** The number message appears and nothing is created.
- [ ] **A6 — Missing special character:** The special-character message appears
  and nothing is created.
- [ ] **A7 — Passwords do not match:** The matching-password message appears and
  nothing is created.
- [ ] **A8 — Agreement unchecked:** Valid fields still show the Agreement
  Required dialog. Nothing is created.
- [ ] **A8a — Terms and Privacy:** Terms and Privacy Policy are separately
  clickable, open their styled scrollable dialogs, and do not automatically
  check the agreement checkbox.
- [ ] **A9 — Cancel confirmation:** With valid fields and agreement checked, tap
  Create Account and then Cancel. The form remains filled and nothing is
  created.

## B. Starting registration

- [ ] **B1 — Normal startup:** Fully reopen the app. Login is always the first
  screen, its fields are empty, and no internal cleanup dialog is shown.
- [ ] **B2 — Successful start:** Select Register and confirm a valid new
  registration. A loading dialog appears, followed by Check Your Email, then
  the newly designed verification screen.
- [ ] **B3 — Provisional Firebase state:** Before opening the email,
  Authentication contains one unverified account. No matching Firestore
  `users/{uid}` document exists.
- [ ] **B4 — Initial email delivery and cooldown:** One verification email
  arrives at the correct address in Inbox or Spam. The verification screen
  immediately displays a live `Resend in 30s` countdown.
- [ ] **B5 — Duplicate completed email:** Register using an existing verified
  account with a matching Firestore document. The app explains that the email
  already has an account and does not alter the existing account or document.
- [ ] **B6 — Registration without internet:** Start with the device offline. A
  connection error appears, the loading dialog closes, and no Auth account or
  Firestore document is created.
- [ ] **B7 — Verification-send failure:** If this can be reproduced using a test
  Firebase limit or connection interruption, the app explains that the email
  could not be sent. The provisional Auth account is deleted and no user
  document exists. This test is optional because repeatedly forcing email-send
  failures can temporarily block requests from the device.

## C. Verification screen before verification

- [ ] **C1 — Correct email shown:** The redesigned screen displays the email
  entered during registration and the initial resend countdown continues.
- [ ] **C2 — Check too early:** Tap Check Verification before using the email
  link. The app says the address is not verified, stays on the screen, and does
  not create a Firestore document.
- [ ] **C3 — Resend success:** After the initial countdown, tap Resend
  Verification Email. A success message appears and another email arrives.
- [ ] **C4 — Resend cooldown:** Immediately try to resend again. The control is
  disabled for about 30 seconds, displays the remaining time, and Firebase is
  not called again.
- [ ] **C5 — Resend after cooldown:** After about 30 seconds, the resend control
  becomes available and can send another email.
- [ ] **C6 — Resend without internet:** Go offline before resending. A connection
  error appears, the app stays on the screen, and the resend control becomes
  available again.
- [ ] **C7 — Firebase rate limit message:** If Firebase naturally returns
  `too-many-requests`, the app displays a friendly wait-before-retrying message
  instead of the raw Firebase error. Do not intentionally exhaust the quota.
- [ ] **C8 — Invalid or expired link:** Open an invalid or expired verification
  link. Firebase does not mark the account verified. Check Verification keeps the
  app on this screen and no user document is created.

## D. Successful verification

- [ ] **D1 — Open valid link:** The Firebase page reports success. Authentication
  changes Email verified from false to true. Firestore still has no user document
  until the app checks the status.
- [ ] **D2 — Complete inside the app:** Return to SoundSight and tap Check
  Verification. The Email Verified dialog appears.
- [ ] **D3 — Firestore document:** Exactly one `users/{uid}` document is created
  with the correct `uid`, trimmed username, email, `piano_player` role, light
  theme, active status, null initial skill/notation/profile image, and server
  timestamps.
- [ ] **D4 — Go to Login:** Tap Go to Login. The dialog closes, Firebase signs the
  user out, and Login is the only remaining screen in the navigation stack.
- [ ] **D5 — Repeated button taps:** Tap Check Verification rapidly after
  verification. Only one document, one completion dialog, and one navigation to
  Login should occur.

## E. Cancelling or closing registration

- [ ] **E1 — Back from verification:** Press the device Back button before
  verification. The provisional Auth account is deleted, no user document
  exists, and registration restarts with empty fields. Leave the verification
  screen open for several minutes before pressing Back so that reauthentication
  cleanup is also exercised.
- [ ] **E2 — Close while unverified:** Fully close the app on the verification
  screen, then reopen it. The provisional Auth account is removed, no user
  document exists, and Login opens. Selecting Register opens an empty form.
- [ ] **E3 — Close after opening the email link:** Verify using the link but close
  the app before tapping Check Verification. Reopening treats it as unfinished:
  the Auth account is removed, no user document exists, and Login opens.
- [ ] **E4 — Cleanup while offline:** Close the app during registration, disable
  internet, and reopen it. Login opens normally without an internal cleanup
  dialog and access is not granted. After restoring connectivity, starting a
  new registration with the same email and password silently deletes the old
  unverified Auth account before creating a fresh one.
- [ ] **E5 — Old link after cancellation:** After an incomplete account is
  deleted, open its old email link. It must not create a user document or make
  the deleted account usable.

## F. Login access control

- [ ] **F1 — Completed account:** Log in with a verified Auth account that has a
  matching user document. Login succeeds and existing assessment routing still
  works.
- [ ] **F2 — Wrong password:** A login error appears, the loading dialog closes,
  and the app stays on Login.
- [ ] **F3 — Unknown email:** A login error appears, the loading dialog closes,
  and the app stays on Login.
- [ ] **F4 — Login without internet:** A clear connection error appears and the
  app stays on Login.
- [ ] **F5 — Unverified Auth account:** Use a provisional unverified account. The
  app blocks access, deletes the Auth account, confirms that registration was
  incomplete, and opens an empty Register screen. No user document exists.
- [ ] **F6 — Verified Auth account without user document:** The app blocks access,
  deletes the incomplete Auth account, shows the incomplete-registration error,
  and opens Register.
- [ ] **F7 — Firestore unavailable after valid sign-in:** Authentication may
  succeed, but a Firestore connection error appears and the app does not open
  assessment or Home.
- [ ] **F8 — Assessment not started:** A valid completed account opens the
  assessment entry screen.
- [ ] **F9 — Assessment in progress:** A valid completed account opens the
  assessment entry screen with its resumable attempt.
- [ ] **F10 — Assessment completed:** A valid completed account opens Home.
- [ ] **F11 — Assessment expired:** A valid completed account opens Home using the
  existing expired-assessment behavior.

## G. Firebase security checks

- [ ] **G1 — Signed out Firestore access:** Reads and writes are denied.
- [ ] **G2 — Unverified Firestore access:** An authenticated but unverified user
  cannot read or write any protected Firestore data, including `users`.
- [ ] **G3 — Verified own profile:** A verified user can create and read only the
  allowed profile and app data for that UID.
- [ ] **G4 — Another user's profile:** A verified user cannot read, update, or
  delete another user's private document.
- [ ] **G5 — Unverified Storage access:** An authenticated but unverified user
  cannot read or write protected Firebase Storage files.
- [ ] **G6 — Verified Storage access:** A verified user retains the existing
  allowed Storage behavior for their own files.

## H. Final regression pass

- [ ] Login is always the first screen after fully opening the app.
- [ ] No technical unfinished-registration dialog appears on normal Login.
- [ ] Register link from Login opens the organized Register screen.
- [ ] Login link from Register opens the organized Login screen.
- [ ] Terms and Privacy Policy open their matching styled dialogs.
- [ ] The verification screen and completion dialog match the auth design.
- [ ] Password visibility buttons still work on both screens.
- [ ] Logging out from Home returns to the organized Login screen.
- [ ] Drawer logout returns to the organized Login screen.
- [ ] No loading dialog remains stuck after any tested error.
- [ ] No test leaves an unexpected Auth account or orphaned Firestore user
  document.
- [ ] No unverified account reaches Assessment, Home, Firestore data, or Storage.
