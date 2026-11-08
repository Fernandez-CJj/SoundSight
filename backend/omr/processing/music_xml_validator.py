import os

from music21 import converter


def validateMusicXml(
    musicXmlPath,
):
    if not os.path.exists(
        musicXmlPath
    ):
        raise FileNotFoundError(
            "The MusicXML file was not found."
        )

    try:
        score = converter.parse(
            musicXmlPath
        )
    except Exception as error:
        raise ValueError(
            "The MusicXML file could not be read."
        ) from error

    noteCount = 0

    for musicalObject in score.recurse().notes:
        if musicalObject.isChord:
            noteCount = (
                noteCount
                + len(musicalObject.pitches)
            )
        else:
            noteCount = noteCount + 1

    if noteCount == 0:
        raise ValueError(
            "The MusicXML file does not contain any notes."
        )

    return {
        "partCount": len(score.parts),
        "noteCount": noteCount,
    }
