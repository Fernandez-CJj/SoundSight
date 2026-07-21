import os
import subprocess


MUSESCORE_PATH = (
    r"C:\Program Files\MuseScore 4\bin\MuseScore4.exe"
)


def isMuseScoreInstalled():
    return os.path.exists(
        MUSESCORE_PATH
    )


def exportPdf(musicXmlPath):
    pdfPath = os.path.splitext(
        musicXmlPath
    )[0] + ".pdf"

    result = subprocess.run(
        [
            MUSESCORE_PATH,
            "-o",
            pdfPath,
            musicXmlPath,
        ]
    )

    if result.returncode != 0:
        raise RuntimeError(
            "MuseScore could not generate the PDF."
        )

    return pdfPath