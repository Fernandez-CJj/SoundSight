"""Heavy operations. Return fields to commit; never publish item state here."""
import tempfile
from pathlib import Path

from jobs.firebase_bridge import check_sources


def execute(job):
    check_sources(job)
    suffix = f"-{job['id']}-{job['attempts']}"
    owner, target = job["owner"], job["target"]
    if job["kind"] == "composition":
        from composition.private_composition_service import loadOwnedComposition, CURRENT_GENERATED_FILES_VERSION
        from composition.generation_service import generateCompositionFiles
        from composition.public_profile_service import getPublicProfile
        composition = loadOwnedComposition(target, owner)
        paths = generateCompositionFiles(composition, getPublicProfile(owner)["username"], suffix)
        fields = {**paths, "generatedFilesVersion": CURRENT_GENERATED_FILES_VERSION}
        if composition.recordingSchemaVersion == 1:
            fields.update(tempo=composition.tempo, measureCount=composition.measureCount,
                          performanceDurationUs=composition.performanceDurationUs)
        # Timing normalization is part of generation, not an edit by the user.
        return {"fields": fields, "paths": list(paths.values())}
    if job["kind"] == "audio":
        return audio(job, suffix)
    return omr(job, suffix)


def audio(job, suffix):
    from audio.transcription_service import (_worker_python, _validate_source, _sheet_reference,
                                            _decode_mp3, _run_worker, MAX_SOURCE_BYTES, ENGINE)
    from core.firebase_service import getStorageBucket
    from core.musescore_service import exportMusicXml, exportPdf
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


def omr(job, suffix):
    from omr.music_sheet_service import getMusicSheet
    from omr.omr_source_service import (createOmrJobFolders, deleteOmrJobFolder,
                                        downloadMusicSheetFiles, prepareAudiverisInput)
    from omr.audiveris_service import convertToMusicXml
    from omr.music_xml_extractor import extractMusicXml
    from omr.music_xml_piano_normalizer import normalizeMusicXmlForPiano
    from omr.music_xml_validator import validateMusicXml
    from omr.omr_storage_service import uploadOmrFiles
    from core.musescore_service import exportPdf, exportMidi, exportMp3
    data = getMusicSheet(job["target"], job["owner"])
    folders = createOmrJobFolders()
    try:
        sources = downloadMusicSheetFiles(data, folders["inputFolder"], job["snapshot"]["sourceGenerations"])
        source = prepareAudiverisInput(data, sources, folders["inputFolder"])
        xml = normalizeMusicXmlForPiano(extractMusicXml(convertToMusicXml(source, folders["outputFolder"])))
        counts = validateMusicXml(xml)
        pdf = exportPdf(xml)
        midi = exportMidi(xml, folders["outputFolder"])
        mp3 = exportMp3(xml, folders["outputFolder"])
        paths = uploadOmrFiles(xml, midi, pdf, mp3, job["owner"], job["target"], suffix)
        return {"fields": {**paths, "omrPartCount": counts["partCount"],
                           "omrNoteCount": counts["noteCount"], "omrEngine": "audiveris", "omrError": None},
                "paths": list(paths.values())}
    finally:
        deleteOmrJobFolder(folders["jobFolder"])
