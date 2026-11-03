# Android background processing

SoundSight now accepts work quickly and processes one heavy task at a time on
this Windows PC. Sheet recognition, audio transcription, and composition file
generation share one FIFO queue. Publishing is handled separately.

For users outside your home Wi-Fi and an APK that follows changing tunnel
addresses, follow [QUICK_TUNNEL_SETUP.md](QUICK_TUNNEL_SETUP.md). The app uses the
Firebase address by default; an explicit build-time URL overrides it.

## Start the two processes

### Double-click startup on this PC

Double-click **Start Backend.cmd** in the project root. It opens two PowerShell
windows for the worker and API using the existing `backend/venv`; there is no
need to activate it or type commands. Keep both windows open while hosting.
To stop, press Ctrl+C in each window. Stop any previously running API and worker
before using the launcher.

The launcher uses `%USERPROFILE%\SoundSightKeys\soundsight-service-account.json`
(on CJ's PC, `C:\Users\CJ\SoundSightKeys\soundsight-service-account.json`).
It stores no credentials in the project. The API listens on `0.0.0.0:8000` for
same-network phone access. Continue using the PC's LAN URL in the app.

Open `http://127.0.0.1:8000/health` and wait for `workerAvailable: true` before
converting. The windows opening alone does not confirm Firebase/worker readiness.
The launcher starts services only; it reuses installed tools and dependencies.

### Manual startup (alternative)

Use the existing Firebase service-account JSON outside the repository. Both
processes need the same credentials, local database, and Windows user access to
MuseScore, Audiveris and the Transkun environment. From the project root, run
these in separate PowerShell terminals:

```powershell
.\backend\start-worker.ps1 -FirebaseCredentials 'C:\private\service-account.json'
```

```powershell
.\backend\start-backend.ps1 -FirebaseCredentials 'C:\private\service-account.json'
```

The API binds to `127.0.0.1:8000` for a local HTTPS tunnel. For a phone on the
same Wi-Fi without a tunnel, pass `-BindAddress '0.0.0.0'` to the backend script
and use the PC's LAN address in the Android build. Public hosting is separate.

`GET /health` reports `workerAvailable`, `waiting`, `processing`,
`awaitingSync`, capacity 20, and concurrency 1. A worker heartbeat expires after
30 seconds. No worker or startup reconciliation still in progress means new
submissions receive 503, while publishing remains available.

Do not use `--reload` for hosting. The worker uses a local OS file lock to prevent
a second worker from processing the same database. A Windows Job Object kills
the entire render process tree if the worker exits unexpectedly.

## Queue behavior

- At most 20 waiting jobs, one running job, and two unfinished jobs per user.
- Each item can have one unfinished job. Queued tasks can be cancelled; running
  tasks cannot. Item edits, renames, deletion, and source replacement are blocked
  by the app and Firebase rules while a task is active.
- A save writes composition data to Firebase first. Rejected generation does not
  erase it: the user can retry submitting generation later.
- An interrupted active job retains its reservation and retries once on worker
  restart, before the waiting list. Normal failures/timeouts require Retry.
- Execution deadlines: OMR 65 minutes, audio 40 minutes, composition 35 minutes.
  They exclude queue waiting time. Overrides, in seconds, are
  `SOUNDSIGHT_OMR_TIMEOUT`, `SOUNDSIGHT_AUDIO_TIMEOUT`, and
  `SOUNDSIGHT_COMPOSITION_TIMEOUT` in the worker environment.
- Accepted work, status synchronization, notification delivery, and file cleanup
  are durable. Firebase/network outages are retried. Old working outputs stay
  intact on failed reconversions; successful replacements clean up unused files.
- A locked item may remain locked while Firebase is unreachable. Let the worker
  reconcile after reconnection; do not manually clear an active lock while a
  rendering process is running.

## Android notifications

The existing Firebase project and Android app configuration are reused. Enable
the Firebase Cloud Messaging HTTP v1 API for the project if needed, and ensure
the service account can send FCM messages. Do not place its JSON in the APK.

The app requests Android notification permission after the first accepted job,
registers its device token with the backend, and refreshes it on sign-in, token
changes, and app resume. Sign-out removes the registration and revokes the token.
Push registration failures do not prevent conversion.

The PC sends success/failure notifications through Firebase Admin. The channel
is `processing_results`. Foreground and missed-result alerts use Firebase job
records, including if permission is denied. Taps open the correct item after
sign-in; a different account cannot open the original user's item.

Push delivery is best effort. An Android force-stop prevents delivery until the
app is reopened. Retries reuse the same notification tag, but exactly-once push
delivery is not guaranteed. Result records remain available independently.

## Upgrade / Firebase rules

The API and Android app must be upgraded together: previous app versions receive
426 for conversion/generation rather than starting synchronous processing.

1. Let old synchronous requests finish and stop the previous backend.
2. Back up existing Firebase data and the local queue, if present.
3. Deploy the reviewed `firestore.rules` and `storage.rules` to your Firebase
   project. The new rules permit owner-only job reads/acknowledgement and enforce
   active item locks. Local emulator tests never deploy these rules.
4. Start the worker and API; verify `/health` and `workerAvailable: true`.
5. Install the updated Android APK. Test all three task types on a real device,
   including leaving the app, cancelling a queued job, a failed conversion,
   notification taps, and a worker restart.

For Firebase address discovery, build without a fixed URL:

```powershell
flutter build apk --release
```

To deliberately build with a fixed backend URL instead:

```powershell
flutter build apk --release --dart-define=SOUNDSIGHT_BACKEND_URL=https://YOUR-HOST
```

## Verify on an Android phone

App testing is performed on a connected Android phone. Run the API and worker,
install or run the updated app, and check conversion, queued cancellation,
navigation away during processing, and completion notifications.

Use `flutter analyze` and an Android APK build with the project's IDE SDK for
static and build checks.

## Startup, logs, backups

The default database, WAL files, process lock, and per-attempt logs are in ignored
`backend/data/`. Per-attempt temporary files are contained in `backend/data/work`
and are cleaned after the final result is saved. On startup and every minute,
the worker removes logs for successful/cancelled jobs and temporary folders for
finished jobs. Failed-job logs are kept for seven days after the job finishes,
then removed. All attempts' logs are removed if an interrupted job later succeeds.
Active jobs, unfinished result updates, unknown files, queue/database files, lock
files, the tunnel log, and the public address file are not removed. Cleanup uses
the local queue, so Firebase outages do not prevent cleanup of already finished
jobs. Files still open on Windows are retried on the next cleanup pass.

Set `SOUNDSIGHT_JOBS_DB` to the same absolute local path for both
processes to relocate it. Do not put SQLite on a network drive or sync it live.

For Windows Task Scheduler, create separate API and worker tasks under the same
Windows account, invoke the scripts with credential-path arguments, configure
restart on failure, and remove the task time limit. Test MuseScore exports after
an unattended reboot. Disable PC sleep while hosting.

For a consistent backup, stop the API and worker, copy the whole `backend/data`
directory, then restart both. Keep the service-account file separate and private.
Deleting/replacing the database loses the durable queue; do not do it to clear
errors. Worker logs identify job ID, type and attempt; individual subprocess
logs are named `{jobId}-{attempt}.log`.
