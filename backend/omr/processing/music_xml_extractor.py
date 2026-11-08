import os
import zipfile
from xml.etree import ElementTree


MUSIC_XML_CONTAINER_PATH = (
    "META-INF/container.xml"
)


def extractMusicXml(
    compressedMusicXmlPath,
):
    if not os.path.exists(
        compressedMusicXmlPath
    ):
        raise FileNotFoundError(
            "The compressed MusicXML file was not found."
        )

    try:
        with zipfile.ZipFile(
            compressedMusicXmlPath,
            "r",
        ) as archive:
            try:
                containerBytes = archive.read(
                    MUSIC_XML_CONTAINER_PATH
                )
            except KeyError as error:
                raise ValueError(
                    "The compressed MusicXML file is missing "
                    "META-INF/container.xml."
                ) from error

            try:
                containerRoot = ElementTree.fromstring(
                    containerBytes
                )
            except ElementTree.ParseError as error:
                raise ValueError(
                    "The MusicXML container file could not be read."
                ) from error

            rootFilePath = findRootFilePath(
                containerRoot
            )

            if rootFilePath is None:
                raise ValueError(
                    "The compressed MusicXML file does not "
                    "declare a root score file."
                )

            validateRootFilePath(
                rootFilePath
            )

            try:
                musicXmlBytes = archive.read(
                    rootFilePath
                )
            except KeyError as error:
                raise ValueError(
                    "The compressed MusicXML file does not "
                    "contain its declared score file."
                ) from error
    except zipfile.BadZipFile as error:
        raise ValueError(
            "The compressed MusicXML file could not be read."
        ) from error

    if len(musicXmlBytes.strip()) == 0:
        raise ValueError(
            "The compressed MusicXML file contains an empty "
            "score file."
        )

    musicXmlPath = (
        os.path.splitext(
            compressedMusicXmlPath
        )[0]
        + ".musicxml"
    )

    with open(
        musicXmlPath,
        "wb",
    ) as musicXmlFile:
        musicXmlFile.write(
            musicXmlBytes
        )

    return musicXmlPath


def findRootFilePath(
    containerRoot,
):
    for element in containerRoot.iter():
        if element.tag.split("}")[-1] != "rootfile":
            continue

        rootFilePath = element.attrib.get(
            "full-path",
            "",
        ).strip()

        if rootFilePath != "":
            return rootFilePath

    return None


def validateRootFilePath(
    rootFilePath,
):
    normalizedPath = rootFilePath.replace(
        "\\",
        "/",
    )

    pathParts = normalizedPath.split("/")

    if (
        normalizedPath.startswith("/")
        or any(
            pathPart in ["", ".", ".."]
            for pathPart in pathParts
        )
    ):
        raise ValueError(
            "The compressed MusicXML file declares an invalid "
            "root score path."
        )
