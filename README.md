# soundsight

A new Flutter project.

## Code organization

App features live under `lib/screens/`, with subfolders for screens, widgets,
models, services, and other responsibilities as needed.

The Python backend groups code by feature: `composition/`, `omr/`, `audio/`,
and `jobs/`. Within each feature, `models/` holds data schemas, `repositories/`
handles persistence, `services/` coordinates workflows, and `processing/`
contains conversion and music-processing code where needed. Shared Firebase
and MuseScore integrations live in `backend/core/integrations/`.

`backend/main.py` registers the API routers. The existing launchers still use
`uvicorn main:app` and `python -m jobs.worker` from `backend/`. Audio transcription
keeps its separate interpreter in `backend/transkun_venv/` and its scripts in
`backend/audio/workers/`.

The [backend teaching checklist](backend/README.md) lists every project-owned
backend file and the code checkpoints for our walkthroughs.

## Reading backend activity

`Start Backend.cmd` opens an **API Requests** window and a **Processing Worker**
window. The API shows the requested action, HTTP response, job ID where
available, and request duration. Match `job=...` between the windows to follow a
task through processing and saving.

- `202 Accepted`: the job was received. Check its state to see whether it is
  waiting, processing, or already finished after an earlier submission.
- `200 OK`: the request succeeded. A successful progress check can still report
  a running job.
- `4xx`: the request, account, permissions, or queue limits need attention.
- `5xx`: the backend or processing worker could not handle the request.
- Worker **Completed and saved**: the result has been committed for the app.

Successful health checks and repeated unchanged job states stay out of the
console. They are still written to `backend/data/logs/api.log`. Worker activity
and full error tracebacks are in `backend/data/logs/worker.log`; failed conversion
attempts also have individual logs under `backend/data/`. The API and worker logs
rotate at 5 MB each, keeping three backups. Set `SOUNDSIGHT_LOG_DIR` to choose a
different log folder. Restart both backend windows after changing backend code.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
