"""Process a queued audio transcription and return artifacts for commit."""
import tempfile
from pathlib import Path


def process(job, suffix):
    from audio.services.transcription_service import (_worker_python, _validate_source, _sheet_reference,
                                            _decode_mp3, _run_worker, MAX_SOURCE_BYTES, ENGINE)
    from core.integrations.firebase_service import getStorageBucket
    from core.integrations.musescore_service import exportMusicXml, exportPdf
    data = _sheet_reference(job["owner"], job["target"]).get().to_dict() or {}
    source_path = _validate_source(data, job["owner"], job["target"])
    paths = {}
    with tempfile.TemporaryDirectory(prefix="soundsight-transkun-") as folder:
        folder = Path(folder)
        source, wav, midi = folder / "source.mp3", folder / "source.wav", folder / "recognized.mid"
        blob = getStorageBucket().blob(source_path)
        blob.download_to_filename(str(source), if_generation_match=int(job["snapshot"]["sourceGenerations"][source_path]), timeout=120)
        if not 0 < source.stat().st_size <= MAX_SOURCE_BYTES:
            raise ValueError("The saved MP3 exceeds the supported size.")
        _decode_mp3(source, wav)
        count = _run_worker(_worker_python(), wav, midi)
        xml = exportMusicXml(str(midi))
        pdf = exportPdf(xml)
        base = f"musicSheets/{job['owner']}/{job['target']}/recognized{suffix}"
        for field, file, ext, content in (
            ("midiStoragePath", midi, "mid", "audio/midi"),
            ("musicXmlStoragePath", xml, "musicxml", "application/vnd.recordare.musicxml+xml"),
            ("recognizedPdfStoragePath", pdf, "pdf", "application/pdf"),
        ):
            path = f"{base}.{ext}"
            getStorageBucket().blob(path).upload_from_filename(str(file), content_type=content, timeout=120)
            paths[field] = path
    return {"fields": {**paths, "previewAudioStoragePath": source_path,
                       "transcriptionEngine": ENGINE, "transcriptionError": None,
                       "transcriptionNoteCount": count}, "paths": list(paths.values())}
