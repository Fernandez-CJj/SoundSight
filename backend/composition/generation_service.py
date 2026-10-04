import tempfile

from composition.file_exporter import saveMidi
from composition.file_exporter import saveMusicXml
from composition.score_builder import create_basic_score
from composition.storage_service import uploadCompositionFiles
from core.musescore_service import exportMp3
from core.musescore_service import exportPdf


def generateCompositionFiles(
    composition,
    authorName,
):
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

        midiPath = saveMidi(
            score,
            composition.id,
            outputFolder,
        )

        pdfPath = exportPdf(
            musicXmlPath
        )

        mp3Path = exportMp3(
            musicXmlPath,
            outputFolder,
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