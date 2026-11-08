import os
import subprocess

import imageio_ffmpeg


MUSESCORE_PATH = (
    r"C:\Program Files\MuseScore 4\bin\MuseScore4.exe"
)


def isMuseScoreInstalled():
    return os.path.exists(
        MUSESCORE_PATH
    )


def exportMusicXml(midiPath):
    if not isMuseScoreInstalled():
        raise FileNotFoundError("MuseScore is not installed.")
    if not os.path.isfile(midiPath):
        raise FileNotFoundError("The MIDI file was not found.")

    musicXmlPath = os.path.splitext(midiPath)[0] + ".musicxml"
    try:
        result = subprocess.run(
            [MUSESCORE_PATH, "-o", musicXmlPath, midiPath],
            capture_output=True,
            text=True,
            timeout=600,
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError("MuseScore took longer than 10 minutes.") from error

    if result.returncode != 0 or not os.path.isfile(musicXmlPath):
        raise RuntimeError("MuseScore could not generate the MusicXML file.")
    if os.path.getsize(musicXmlPath) == 0:
        raise RuntimeError("MuseScore created an empty MusicXML file.")
    return musicXmlPath


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
    sourceScorePath,
    outputFolder,
):
    if not isMuseScoreInstalled():
        raise FileNotFoundError(
            "MuseScore is not installed."
        )

    if not os.path.exists(
        sourceScorePath
    ):
        raise FileNotFoundError(
            "The source score file was not found."
        )

    os.makedirs(
        outputFolder,
        exist_ok=True,
    )

    sourceFileName = os.path.basename(
        sourceScorePath
    )

    sourceName = os.path.splitext(
        sourceFileName
    )[0]

    mp3Path = os.path.join(
        outputFolder,
        sourceName + ".mp3",
    )

    try:
        result = subprocess.run(
            [
                MUSESCORE_PATH,
                "-o",
                mp3Path,
                sourceScorePath,
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


def trimMp3ToDuration(
    mp3Path,
    durationSeconds,
    fadeDurationSeconds=0.005,
):
    if not os.path.exists(mp3Path):
        raise FileNotFoundError(
            "The MP3 file to trim was not found."
        )
    if durationSeconds <= 0:
        raise ValueError(
            "The MP3 duration must be greater than zero."
        )

    fadeDuration = min(
        fadeDurationSeconds,
        durationSeconds,
    )
    fadeStart = max(
        0.0,
        durationSeconds - fadeDuration,
    )
    trimmedPath = os.path.splitext(mp3Path)[0] + ".trimmed.mp3"
    audioFilter = (
        f"atrim=start=0:end={durationSeconds:.6f},"
        f"afade=t=out:st={fadeStart:.6f}:d={fadeDuration:.6f},"
        "asetpts=PTS-STARTPTS"
    )

    try:
        result = subprocess.run(
            [
                imageio_ffmpeg.get_ffmpeg_exe(),
                "-y",
                "-i",
                mp3Path,
                "-af",
                audioFilter,
                "-t",
                f"{durationSeconds:.6f}",
                "-codec:a",
                "libmp3lame",
                "-q:a",
                "2",
                trimmedPath,
            ],
            capture_output=True,
            text=True,
            timeout=600,
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(
            "Trimming the recorded MP3 took longer than 10 minutes."
        ) from error

    try:
        if result.returncode != 0:
            raise RuntimeError(
                "The recorded MP3 could not be matched to the MIDI ending."
            )
        if (
            not os.path.exists(trimmedPath)
            or os.path.getsize(trimmedPath) == 0
        ):
            raise RuntimeError(
                "Trimming produced an empty recorded MP3 file."
            )
        os.replace(trimmedPath, mp3Path)
    finally:
        if os.path.exists(trimmedPath):
            os.remove(trimmedPath)

    return mp3Path
