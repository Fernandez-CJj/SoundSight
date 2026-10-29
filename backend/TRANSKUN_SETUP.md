# MP3-to-MIDI worker setup on Windows

The FastAPI backend remains in its existing Python 3.14 `backend/venv`.
Transkun runs as a separate Python 3.11 process. Uploading and previewing MP3s
does not require that process; converting a saved MP3 does.

The worker environment is `backend/transkun_venv`. Keep this directory:
the backend launches its Python executable for each conversion. On a new
machine, run these commands from the SoundSight project root:

```powershell
$py311 = "$env:LOCALAPPDATA\Programs\Python\Python311\python.exe"
& $py311 -m venv backend\transkun_venv
& backend\transkun_venv\Scripts\python.exe -m pip install --upgrade pip
& backend\transkun_venv\Scripts\python.exe -m pip install -r backend\transkun_inference_requirements.txt
& backend\transkun_venv\Scripts\python.exe -m pip install transkun==2.0.1 --no-deps
```

The `--no-deps` installation avoids `ncls`, an optional training dependency
that needs a C++ build toolchain on Windows. The packages listed above are the
dependencies used by the tested inference path. `setuptools<81` keeps
`pkg_resources` available for Transkun 2.0.1.

If the 3.11 environment is stored somewhere else, set
`SOUNDSIGHT_TRANSKUN_PYTHON` in the terminal that starts FastAPI to the
absolute path of that environment's `python.exe`.

Start the backend from `backend` with its existing environment and Firebase
service-account credentials:

```powershell
cd backend
.\venv\Scripts\Activate.ps1
$env:GOOGLE_APPLICATION_CREDENTIALS = 'C:\path\to\your-service-account.json'
python -m uvicorn main:app --host 0.0.0.0 --port 8000
```

The app calls the authenticated
`POST /music-sheets/{sheetId}/transcribe-audio` route. The backend checks
ownership and the saved `source.mp3`, converts a temporary WAV with Transkun,
applies the conservative timing correction, and uploads the first result to
`musicSheets/{uid}/{sheetId}/recognized.mid`. Reconversion uploads to a new
`recognized-{attemptId}.mid` path, switches the sheet document to that path,
then removes the previous MIDI. Firestore stores the status, note count, and
current MIDI Storage path. Failed attempts keep the original MP3 and can be
retried. If reconversion fails, the previous MIDI remains current. A processing
attempt can be retried after its 20-minute lease expires if the backend stops
unexpectedly.

The timing correction was selected from a small set of supplied and synthetic
piano clips. It skips uncertain rhythms and short articulation. It does not
guarantee the same accuracy on an unseen recording. No Firebase rules change
is required for the backend's Admin SDK upload.

## Test from the Android app

1. Restart FastAPI after changing backend code. Check that the backend terminal
   shows `Uvicorn running on http://0.0.0.0:8000`.
2. Run `ipconfig` on the PC. Use the IPv4 address of the adapter with your
   Wi-Fi/router default gateway. The app's current default URL is
   `http://192.168.0.104:8000`; if the address changes, launch Flutter with
   `--dart-define=SOUNDSIGHT_BACKEND_URL=http://NEW_IP:8000`.
3. On the Android phone, open `http://192.168.0.104:8000/health` in a browser
   (substitute the current PC IPv4 if needed). A JSON response with
   `"status":"ok"` confirms the phone can reach FastAPI.
4. Sign in with a verified account. Save a solo-piano MP3 in the app, then
   open it and tap **Convert recording**. Confirm the dialog. A completed
   recording offers **Convert Again**.
5. Keep the backend terminal open. The app should show processing, then
   **Recording converted**. The backend should log a `POST .../transcribe-audio`
   request with `200 OK`.
6. In Firebase Storage, find the path in `midiStoragePath` in the sheet document
   at `users/{uid}/musicSheets/{sheetId}`. The first result uses
   `musicSheets/{uid}/{sheetId}/recognized.mid`; reconversion uses a versioned
   name. Confirm `transcriptionStatus: completed` and a positive
   `transcriptionNoteCount`.
   Download the MIDI and open it in MuseScore to listen and inspect timing.
7. If the first conversion fails, confirm that the original MP3 still plays
   and the card offers **Retry**. The Firestore status should be `failed` with
   a `transcriptionError`. If reconversion fails, the prior MIDI remains
   current and the card still offers **Convert Again**. A request that never
   reached FastAPI may leave the card in its initial state; after reconnecting,
   tap Convert again.

The MP3 preview and upload do not need FastAPI. Conversion does.
