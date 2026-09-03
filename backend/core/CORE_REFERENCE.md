# Core Services Reference

## Purpose

The `core` folder provides shared services used by both composition publishing and music-sheet recognition:

- one Firebase Admin connection;
- MuseScore PDF and MP3 export.

These files are support services and do not expose HTTP routes by themselves.

## Firebase connection

`firebase_service.py` initializes one Firebase Admin app when the module is loaded.

It uses this Storage bucket:

- `soundsight-b1d16.firebasestorage.app`.

It creates shared Firestore and Storage objects. Other backend files obtain them through `getDatabase()` and `getStorageBucket()`.

## Firebase credentials

No credential file path is provided in the source code. Firebase Admin therefore uses Application Default Credentials from the computer or server environment.

If valid credentials are unavailable, Firebase operations cannot start successfully.

## MuseScore location

MuseScore is expected at this exact Windows path:

- `C:\Program Files\MuseScore 4\bin\MuseScore4.exe`.

The backend does not search the system PATH for MuseScore.

## PDF export flow

1. A caller provides a local MusicXML path.
2. The output path is created by replacing the extension with `.pdf`.
3. MuseScore runs with `-o`, the PDF path, and the MusicXML path.
4. A nonzero MuseScore exit code produces a runtime error.
5. The PDF path is returned to the caller.

The PDF function does not set a timeout and does not directly verify that the output file exists. The composition Storage service performs an existence check before uploading it.

## MP3 export flow

1. The service verifies that MuseScore exists.
2. It verifies that the MusicXML input exists.
3. It creates the requested output folder.
4. It creates an MP3 name from the MusicXML file name.
5. MuseScore runs with a maximum duration of 10 minutes.
6. The service requires a successful exit code, an existing MP3 file, and a non-empty MP3 file.
7. The MP3 path is returned to the caller.

## Temporary and permanent information

The core services do not store screen state.

MuseScore reads and writes local files supplied by its callers. Whether those files are temporary depends on the calling feature:

- OMR files are removed with their job folder;
- composition files under `backend/generated_files` remain on disk.

Firebase data and files written through the shared Admin objects are permanent until another operation deletes or replaces them.

## Validation

MuseScore MP3 export checks installation, input existence, timeout, exit code, output existence, and output size.

MuseScore PDF export only checks the process exit code directly.

The Firebase service does not validate document fields. Validation belongs to the composition and OMR services that use it.

## Firebase Rules

Firebase Admin bypasses Firestore Rules and Storage Rules. Rules still protect Flutter client access, but they do not restrict these shared backend objects.

## Failure behavior

MuseScore PDF failure raises `RuntimeError`.

MP3 export can raise:

- `FileNotFoundError` when MuseScore or MusicXML is missing;
- `RuntimeError` for timeout, process failure, missing output, or empty output.

The calling route decides how these errors are shown to the Flutter app.
