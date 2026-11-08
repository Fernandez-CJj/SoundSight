"""Process a queued sheet-recognition job and return artifacts for commit."""


def process(job, suffix):
    from omr.repositories.music_sheet_repository import getMusicSheet
    from omr.processing.omr_source_service import (createOmrJobFolders, deleteOmrJobFolder,
                                        downloadMusicSheetFiles, prepareAudiverisInput)
    from omr.processing.audiveris_service import convertToMusicXml
    from omr.processing.music_xml_extractor import extractMusicXml
    from omr.processing.music_xml_piano_normalizer import normalizeMusicXmlForPiano
    from omr.processing.music_xml_validator import validateMusicXml
    from omr.repositories.omr_storage_repository import uploadOmrFiles
    from core.integrations.musescore_service import exportPdf, exportMidi, exportMp3
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
