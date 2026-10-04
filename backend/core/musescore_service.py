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

    pdfPath = os.path.splitext(
        musicXmlPath
    )[0] + ".pdf"

    try:
        result = subprocess.run(
            [
                MUSESCORE_PATH,
                "-o",
                pdfPath,
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
            "MuseScore could not generate the PDF."
        )

    if not os.path.exists(
        pdfPath
    ):
        raise RuntimeError(
            "MuseScore did not create the PDF file."
        )

    if os.path.getsize(
        pdfPath
    ) == 0:
        raise RuntimeError(
            "MuseScore created an empty PDF file."
        )

    return pdfPath


def exportMidi(
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

    midiPath = os.path.join(
        outputFolder,
        musicXmlName + ".mid",
    )

    try:
        result = subprocess.run(
            [
                MUSESCORE_PATH,
                "-o",
                midiPath,
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
            "MuseScore could not generate the MIDI file."
        )

    if not os.path.exists(
        midiPath
    ):
        raise RuntimeError(
            "MuseScore did not create the MIDI file."
        )

    if os.path.getsize(
        midiPath
    ) == 0:
        raise RuntimeError(
            "MuseScore created an empty MIDI file."
        )

    return midiPath


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
