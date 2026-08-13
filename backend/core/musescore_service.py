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


def exportMp3(
    musicXmlPath,
    outputFolder,
):
    if not isMuseScoreInstalled():
        raise FileNotFoundError(
            "MuseScore is not installed."
        )

    if not os.path.exists(
        musicXmlPath
    ):
        raise FileNotFoundError(
            "The MusicXML file was not found."
        )

    os.makedirs(
        outputFolder,
        exist_ok=True,
    )

    musicXmlFileName = os.path.basename(
        musicXmlPath
    )

    musicXmlName = os.path.splitext(
        musicXmlFileName
    )[0]

    mp3Path = os.path.join(
        outputFolder,
        musicXmlName + ".mp3",
    )

    try:
        result = subprocess.run(
            [
                MUSESCORE_PATH,
                "-o",
                mp3Path,
                musicXmlPath,
            ],
            capture_output=True,
            text=True,
            timeout=600,
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(
            "MuseScore took longer than 10 minutes."
        ) from error

    if result.returncode != 0:
        raise RuntimeError(
            "MuseScore could not generate the audio preview."
        )

    if not os.path.exists(
        mp3Path
    ):
        raise RuntimeError(
            "MuseScore did not create the MP3 file."
        )

    if os.path.getsize(
        mp3Path
    ) == 0:
        raise RuntimeError(
            "MuseScore created an empty MP3 file."
        )

    return mp3Path
