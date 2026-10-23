import tempfile

from composition.file_exporter import saveMusicXml
from composition.file_exporter import normalizeManualMusicXmlForMuseScore
from composition.performance_midi_writer import saveManualMidi
from composition.performance_midi_writer import savePerformanceMidi
from composition.score_builder import create_basic_score
from composition.storage_service import uploadCompositionFiles
from core.musescore_service import exportMp3
from core.musescore_service import exportPdf
from core.musescore_service import trimMp3ToDuration


def generateCompositionFiles(
    composition,
    authorName,
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
        )

        return storagePaths
