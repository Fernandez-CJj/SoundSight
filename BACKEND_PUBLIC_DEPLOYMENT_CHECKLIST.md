# Backend Public Deployment Checklist

This checklist covers the work needed before phones on different networks use
SoundSight's Python backend. Firebase already hosts the
app's authentication, database, and file storage; this checklist concerns the
FastAPI conversion and composition service.

## 1. Secure music sheet conversion

- [x] Make `POST /music-sheets/{sheetId}/recognize` require a valid Firebase ID
      token, using the same backend authentication dependency as the composition
      routes.
- [x] Use the verified token's user ID to load the sheet. Do not use a
      client-provided `ownerId` as proof of ownership.
- [x] Send the signed-in user's Firebase ID token from the Flutter OMR service.
      Update the request body and callers if `ownerId` is removed from the API.
- [x] Before downloading any source file, verify that its Storage path is an
      allowed original file under `musicSheets/{verifiedUserId}/{sheetId}/`.
      Reject paths for another user, another sheet, generated files, or an
      unexpected file name; do not download first and validate later.
- [x] Keep the sheet document's `ownerId` check, and verify its source file list
      matches the sheet type and page count. Do not rely on client-written
      Firestore fields alone to authorize the backend's Admin SDK reads.
- [x] Review Firestore rules for sheet `files` metadata so clients cannot save
      arbitrary Storage paths where a rule can reasonably enforce this.
- [x] Reject unauthenticated, expired-token, unverified-email, other-user, and
      invalid-path requests without changing sheet status or uploading output.

The app and backend changes are in the workspace. Deploying the updated
Firestore rules and checking the complete flow against Firebase remain in the
release verification section below.

## 2. Prepare the backend for public traffic

- [ ] Decide on a host: a temporary tunnel for external-network testing, or a
      cloud host for release. Record the chosen host, region, and expected cost.
- [ ] Install/package Python, Audiveris, MuseScore, Java, and other required
      tools on that host. Replace hard-coded Windows executable paths if the
      host runs Linux.
- [ ] Give the backend a server-side Firebase identity with only the Firestore
      and Storage permissions it needs. Never put service credentials in the
      Flutter app or commit them to the repository.
- [ ] Expose the API through a stable HTTPS address and check `/health` plus an
      actual conversion and composition generation on the deployed host.
- [ ] Set resource limits and controls for costly conversions: input size/page
      limits, concurrent jobs, timeouts, and logging of failures.
- [ ] Resolve the long-running OMR flow before release: the client currently
      waits up to 15 minutes while Audiveris may run up to 30 minutes. Prefer a
      job/status flow so a dropped phone connection does not leave the user
      guessing whether conversion finished.

## 3. Point the app at the deployed API

- [ ] Replace the three `http://192.168.0.104:8000` constants with one shared,
      build-configurable backend URL for OMR, generation, and publishing.
- [ ] Use the public HTTPS URL in release builds. Keep a separate local URL for
      development.
- [ ] Remove the Android release app's broad cleartext HTTP allowance once
      local development traffic has a debug-only configuration.
- [ ] Update backend and app reference documents to match the deployed URL,
      authentication behavior, and conversion status flow.

## 4. Verify before release

- [ ] Deploy the updated `firestore.rules` to the intended Firebase project.
- [ ] Confirm the deployed rules permit a normal sheet upload and rename, and
      reject a client-written source path outside the owner's sheet folder.
- [ ] Confirm a user can upload and convert their own PDF and image sheets.
- [ ] Confirm one user cannot read another user's sheet directly through
      Firestore or Storage, and cannot trigger conversion of it through the API.
- [ ] Confirm a user cannot put another user's Storage path in their own sheet
      document and have the backend convert it.
- [ ] Confirm generation, publish, and unpublish still work with Firebase ID
      tokens after the URL change.
- [ ] Test on a phone using mobile data while the backend is on another
      network; test with a second account and a slow or interrupted connection.
- [ ] Check backend logs, Firebase usage, and hosting spend after the external
      test, then set a budget alert before inviting users.

## Current code locations

- Backend routes and authentication: `backend/main.py`,
  `backend/core/auth_service.py`
- Sheet lookup and file download: `backend/omr/music_sheet_service.py`,
  `backend/omr/omr_source_service.py`
- Flutter API calls: `lib/screens/music_sheet/services/music_sheet_omr_service.dart`,
  `lib/screens/composition/services/composition_generation_service.dart`,
  `lib/screens/composition/services/composition_publish_service.dart`
- Firebase access rules: `firestore.rules`, `storage.rules`
