import tempfile

from composition.processing.file_exporter import saveMusicXml
from composition.processing.file_exporter import normalizeManualMusicXmlForMuseScore
from composition.processing.performance_midi_writer import saveManualMidi
from composition.processing.performance_midi_writer import savePerformanceMidi
from composition.processing.score_builder import create_basic_score
from composition.repositories.composition_storage_repository import uploadCompositionFiles
from core.integrations.musescore_service import exportMp3
from core.integrations.musescore_service import exportPdf
from core.integrations.musescore_service import trimMp3ToDuration


def generateCompositionFiles(
    composition,
    authorName,
    fileSuffix="",
):
    usesPerformanceRecording = (
        composition.creationMethod == "recording"
        and composition.recordingSchemaVersion == 1
    )
    score = create_basic_score(
        composition,
        authorName,
    )

    with tempfile.TemporaryDirectory(
        prefix="soundsight-composition-"
    ) as outputFolder:
        musicXmlPath = saveMusicXml(
            score,
            composition.id,
            outputFolder,
        )

        if not usesPerformanceRecording:
            normalizeManualMusicXmlForMuseScore(
                musicXmlPath
            )

        pdfPath = exportPdf(
            musicXmlPath
        )

        if usesPerformanceRecording:
            midiExport = savePerformanceMidi(
                composition,
                outputFolder,
            )
        else:
            midiExport = saveManualMidi(
                composition,
                outputFolder,
            )

        midiPath = midiExport.midiPath
        mp3Path = exportMp3(
            midiPath,
            outputFolder,
        )
        trimMp3ToDuration(
            mp3Path,
            midiExport.durationSeconds,
        )

        storagePaths = uploadCompositionFiles(
            pdfPath,
            musicXmlPath,
            midiPath,
            mp3Path,
            composition.ownerId,
            composition.id,
            fileSuffix,
        )

        return storagePaths
