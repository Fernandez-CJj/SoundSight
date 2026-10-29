"""Authenticated MP3-to-MIDI conversion using the isolated Transkun worker."""

from datetime import datetime, timedelta, timezone
import json
import logging
import os
from pathlib import Path
import subprocess
import tempfile
import uuid
import wave

from firebase_admin import firestore
from google.cloud.exceptions import NotFound
import imageio_ffmpeg

from core.firebase_service import getDatabase, getStorageBucket
from core.musescore_service import exportMusicXml, exportPdf


MAX_SOURCE_BYTES = 95_000_000
MAX_DURATION_MS = 5 * 60 * 1000
PROCESSING_LEASE = timedelta(minutes=40)
WORKER_TIMEOUT_SECONDS = 13 * 60
ENGINE = "transkun-v2-timing-correction"


class TranscriptionConflict(RuntimeError):
    pass


class TranscriptionUnavailable(RuntimeError):
    pass


def _worker_python():
    configured = os.environ.get("SOUNDSIGHT_TRANSKUN_PYTHON")
    if configured:
        path = Path(configured).expanduser()
    else:
        scripts = "Scripts/python.exe" if os.name == "nt" else "bin/python"
        path = Path(__file__).resolve().parents[1] / "transkun_venv" / scripts
    if not path.is_file():
        raise TranscriptionUnavailable(
            "The Python 3.11 Transkun environment is not installed."
        )
    return path


def _sheet_reference(owner_id, sheet_id):
    return (
        getDatabase().collection("users").document(owner_id)
        .collection("musicSheets").document(sheet_id)
    )


def _validate_source(sheet, owner_id, sheet_id):
    if sheet.get("ownerId") != owner_id:
        raise PermissionError("This music sheet belongs to another user.")
    if sheet.get("type") != "audio":
        raise ValueError("Only saved MP3 music sheets can be converted.")
    files = sheet.get("files")
    expected_path = f"musicSheets/{owner_id}/{sheet_id}/source.mp3"
    if not isinstance(files, list) or len(files) != 1 or not isinstance(files[0], dict):
        raise ValueError("The saved MP3 source is invalid.")
    source = files[0]
    if source.get("storagePath") != expected_path or source.get("contentType") != "audio/mpeg":
        raise ValueError("The saved MP3 source is invalid.")
    size = source.get("sizeBytes")
    duration = sheet.get("durationMs")
    if (type(size) is not int or not 0 < size <= MAX_SOURCE_BYTES or
            type(duration) is not int or not 0 < duration <= MAX_DURATION_MS):
        raise ValueError("The saved MP3 exceeds the supported size or duration.")
    return expected_path


def _started_at(value):
    if not isinstance(value, datetime):
        return None
    return value if value.tzinfo else value.replace(tzinfo=timezone.utc)


@firestore.transactional
def _claim(transaction, reference, owner_id, sheet_id, attempt_id):
    snapshot = reference.get(transaction=transaction)
    if not snapshot.exists:
        raise FileNotFoundError("The saved music sheet was not found.")
    sheet = snapshot.to_dict() or {}
    source_path = _validate_source(sheet, owner_id, sheet_id)

    status = sheet.get("transcriptionStatus")
    if status == "processing":
        started = _started_at(sheet.get("transcriptionStartedAt"))
        if started is None or datetime.now(timezone.utc) - started < PROCESSING_LEASE:
            raise TranscriptionConflict("This MP3 is already being converted.")

    folder = f"musicSheets/{owner_id}/{sheet_id}/"
    previous_paths = {}
    if status in ("completed", "processing"):
        for field, extension in (
            ("midiStoragePath", ".mid"),
            ("musicXmlStoragePath", ".musicxml"),
            ("recognizedPdfStoragePath", ".pdf"),
        ):
            path = sheet.get(field)
            if (isinstance(path, str) and
                    path.startswith(folder + "recognized") and
                    path.endswith(extension)):
                previous_paths[field] = path

    update = {
        "transcriptionStatus": "processing",
        "transcriptionAttemptId": attempt_id,
        "transcriptionError": None,
        "transcriptionStartedAt": firestore.SERVER_TIMESTAMP,
        "transcriptionFailedAt": firestore.DELETE_FIELD,
    }
    if "midiStoragePath" not in previous_paths:
        update.update({
            "transcriptionEngine": ENGINE,
            "transcriptionNoteCount": firestore.DELETE_FIELD,
            "transcriptionProcessedAt": firestore.DELETE_FIELD,
        })
    transaction.update(reference, update)
    return source_path, previous_paths


@firestore.transactional
def _finish(transaction, reference, attempt_id, storage_paths, source_path, note_count):
    snapshot = reference.get(transaction=transaction)
    sheet = snapshot.to_dict() if snapshot.exists else None
    if (sheet is None or sheet.get("transcriptionStatus") != "processing" or
            sheet.get("transcriptionAttemptId") != attempt_id):
        raise TranscriptionConflict("This conversion attempt is no longer active.")
    transaction.update(reference, {
        "transcriptionStatus": "completed",
        "transcriptionEngine": ENGINE,
        "transcriptionError": None,
        "transcriptionNoteCount": note_count,
        **storage_paths,
        "previewAudioStoragePath": source_path,
        "transcriptionProcessedAt": firestore.SERVER_TIMESTAMP,
        "transcriptionFailedAt": firestore.DELETE_FIELD,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    })


@firestore.transactional
def _fail(transaction, reference, attempt_id, message, previous_paths):
    snapshot = reference.get(transaction=transaction)
    sheet = snapshot.to_dict() if snapshot.exists else None
    if (sheet is None or sheet.get("transcriptionStatus") != "processing" or
            sheet.get("transcriptionAttemptId") != attempt_id):
        return
    if "midiStoragePath" in previous_paths:
        transaction.update(reference, {
            "transcriptionStatus": "completed",
            "transcriptionError": None,
            "transcriptionAttemptId": firestore.DELETE_FIELD,
            "transcriptionStartedAt": firestore.DELETE_FIELD,
            "transcriptionFailedAt": firestore.DELETE_FIELD,
        })
    else:
        transaction.update(reference, {
            "transcriptionStatus": "failed",
            "transcriptionError": message,
            "transcriptionFailedAt": firestore.SERVER_TIMESTAMP,
            "updatedAt": firestore.SERVER_TIMESTAMP,
        })


def _decode_mp3(source, wav_path):
    command = [
        imageio_ffmpeg.get_ffmpeg_exe(), "-hide_banner", "-loglevel", "error",
        "-y", "-i", str(source), "-t", "301", "-ac", "1", "-ar", "44100",
        "-c:a", "pcm_s16le", str(wav_path),
    ]
    result = subprocess.run(
        command, capture_output=True, text=True, timeout=120, check=False,
    )
    if result.returncode != 0:
        raise ValueError("The saved MP3 could not be decoded.")
    try:
        with wave.open(str(wav_path), "rb") as audio:
            if audio.getnframes() == 0 or audio.getnframes() > audio.getframerate() * 300:
                raise ValueError("The MP3 must contain audio no longer than five minutes.")
    except (OSError, wave.Error) as error:
        raise ValueError("The saved MP3 could not be decoded.") from error


def _run_worker(python_path, wav_path, midi_path):
    worker_path = Path(__file__).with_name("transkun_worker.py")
    result = subprocess.run(
        [str(python_path), str(worker_path), str(wav_path), str(midi_path)],
        capture_output=True, text=True, timeout=WORKER_TIMEOUT_SECONDS,
        check=False,
    )
    if result.returncode != 0:
        logging.error("Transkun worker failed: %s", result.stderr[-3000:])
        raise RuntimeError("Transkun could not convert this MP3.")
    try:
        data = json.loads(result.stdout.strip().splitlines()[-1])
        note_count = data["noteCount"]
    except (IndexError, KeyError, TypeError, ValueError) as error:
        raise RuntimeError("Transkun returned an invalid result.") from error
    if type(note_count) is not int or note_count <= 0 or not midi_path.is_file():
        raise ValueError("No piano notes were found in this recording.")
    return note_count


def transcribe_audio(sheet_id, owner_id):
    python_path = _worker_python()
    reference = _sheet_reference(owner_id, sheet_id)
    attempt_id = uuid.uuid4().hex
    source_path, previous_paths = _claim(
        getDatabase().transaction(), reference, owner_id, sheet_id, attempt_id,
    )
    suffix = f"-{attempt_id}" if "midiStoragePath" in previous_paths else ""
    folder = f"musicSheets/{owner_id}/{sheet_id}"
    storage_paths = {
        "midiStoragePath": f"{folder}/recognized{suffix}.mid",
        "musicXmlStoragePath": f"{folder}/recognized{suffix}.musicxml",
        "recognizedPdfStoragePath": f"{folder}/recognized{suffix}.pdf",
    }
    blobs = {
        field: getStorageBucket().blob(path)
        for field, path in storage_paths.items()
    }
    uploaded_fields = []

    try:
        source_blob = getStorageBucket().blob(source_path)
        if not source_blob.exists():
            raise FileNotFoundError("The saved MP3 was not found in Firebase Storage.")
        source_blob.reload()
        if not source_blob.size or source_blob.size > MAX_SOURCE_BYTES:
            raise ValueError("The saved MP3 exceeds the supported file size.")

        with tempfile.TemporaryDirectory(prefix="soundsight-transkun-") as job:
            job_dir = Path(job)
            source_file = job_dir / "source.mp3"
            wav_file = job_dir / "source.wav"
            midi_file = job_dir / "recognized.mid"
            source_blob.download_to_filename(str(source_file))
            if not 0 < source_file.stat().st_size <= MAX_SOURCE_BYTES:
                raise ValueError("The saved MP3 exceeds the supported file size.")
            _decode_mp3(source_file, wav_file)
            note_count = _run_worker(python_path, wav_file, midi_file)
            music_xml_file = exportMusicXml(str(midi_file))
            pdf_file = exportPdf(music_xml_file)
            for field, local_path, content_type in (
                ("midiStoragePath", midi_file, "audio/midi"),
                ("musicXmlStoragePath", music_xml_file,
                 "application/vnd.recordare.musicxml+xml"),
                ("recognizedPdfStoragePath", pdf_file, "application/pdf"),
            ):
                blobs[field].upload_from_filename(
                    str(local_path), content_type=content_type,
                )
                uploaded_fields.append(field)

        _finish(
            getDatabase().transaction(), reference, attempt_id,
            storage_paths, source_path, note_count,
        )
        for old_path in previous_paths.values():
            if old_path in storage_paths.values():
                continue
            try:
                getStorageBucket().blob(old_path).delete()
            except NotFound:
                pass
            except Exception:
                logging.exception("Could not remove a previous score file")
        return {
            "sheetId": sheet_id,
            "transcriptionStatus": "completed",
            **storage_paths,
            "previewAudioStoragePath": source_path,
            "noteCount": note_count,
        }
    except Exception as error:
        if uploaded_fields:
            try:
                snapshot = reference.get()
                current = snapshot.to_dict() if snapshot.exists else {}
                for field in uploaded_fields:
                    if current.get(field) == storage_paths[field]:
                        continue
                    try:
                        blobs[field].delete()
                    except NotFound:
                        pass
            except Exception:
                logging.exception("Could not remove incomplete score files")
        message = str(error) if isinstance(error, (ValueError, FileNotFoundError)) else (
            "The MP3 could not be converted. Please try again."
        )
        try:
            _fail(
                getDatabase().transaction(), reference, attempt_id,
                message, previous_paths,
            )
        except Exception:
            logging.exception("Could not save the audio transcription failure")
        raise
