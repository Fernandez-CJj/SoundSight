import os
import subprocess


AUDIVERIS_FOLDER = (
    r"C:\Program Files\Audiveris"
)

AUDIVERIS_PATH = os.path.join(
    AUDIVERIS_FOLDER,
    "Audiveris.exe",
)

AUDIVERIS_JAVA_PATH = os.path.join(
    AUDIVERIS_FOLDER,
    "runtime",
    "bin",
    "java.exe",
)

AUDIVERIS_APP_FOLDER = os.path.join(
    AUDIVERIS_FOLDER,
    "app",
)


def isAudiverisInstalled():
    return (
        os.path.exists(AUDIVERIS_PATH)
        and os.path.exists(AUDIVERIS_JAVA_PATH)
        and os.path.exists(AUDIVERIS_APP_FOLDER)
    )


def convertToMusicXml(
    inputPath,
    outputFolder,
):
    if not isAudiverisInstalled():
        raise FileNotFoundError(
            "Audiveris is not installed."
        )

    if not os.path.exists(inputPath):
        raise FileNotFoundError(
            "The input music sheet was not found."
        )

    os.makedirs(
        outputFolder,
        exist_ok=True,
    )

    classPath = os.path.join(
        AUDIVERIS_APP_FOLDER,
        "*",
    )

    command = [
        AUDIVERIS_JAVA_PATH,
        "-Djpackage.app-version=5.11.0",
        "--add-exports=java.desktop/sun.awt.image=ALL-UNNAMED",
        "--enable-native-access=ALL-UNNAMED",
        "-Dsun.java2d.uiScale.enabled=true",
        "-Dfile.encoding=UTF-8",
        "-Xms512m",
        "-Xmx8G",
        "-cp",
        classPath,
        "Audiveris",
        "-batch",
        "-constant",
        (
            "org.audiveris.omr.sheet.grid.LinesRetriever."
            "minStaffLength=10.0"
        ),
        "-transcribe",
        "-export",
        "-save",
        "-output",
        outputFolder,
        "--",
        inputPath,
    ]

    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=1800,
        )
    except subprocess.TimeoutExpired as error:
        raise RuntimeError(
            "Audiveris took longer than 30 minutes."
        ) from error

    if result.returncode != 0:
        raise RuntimeError(
            "Audiveris could not process the music sheet."
        )

    musicXmlPath = findMusicXml(
        outputFolder
    )

    if musicXmlPath is None:
        raise RuntimeError(
            "Audiveris did not create a MusicXML file."
        )

    return musicXmlPath


def findMusicXml(
    outputFolder,
):
    for currentFolder, _, fileNames in os.walk(
        outputFolder
    ):
        for fileName in fileNames:
            if fileName.lower().endswith(
                ".mxl"
            ):
                return os.path.join(
                    currentFolder,
                    fileName,
                )

    return None
