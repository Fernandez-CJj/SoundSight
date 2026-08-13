# SoundSight backend

## Main files

- `main.py` contains the FastAPI routes.
- `requirements.txt` contains the Python packages used by the backend.

## Folders

- `composition/` creates, publishes, and removes composed music sheets.
- `omr/` converts uploaded music sheets with Audiveris.
- `core/` contains shared Firebase and MuseScore services.
- `generated_files/` contains files generated from user compositions.
- `omr_jobs/` is created temporarily while Audiveris processes a music sheet.
- `venv/` contains the local Python environment.

Run Uvicorn from the `backend` folder so the package imports resolve correctly.
