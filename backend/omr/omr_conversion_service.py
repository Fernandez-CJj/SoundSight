from core.musescore_service import exportMp3
from omr.audiveris_service import convertToMusicXml
from omr.music_sheet_service import getMusicSheet
from omr.music_xml_validator import validateMusicXml
from omr.omr_source_service import createOmrJobFolders
from omr.omr_source_service import deleteOmrJobFolder
from omr.omr_source_service import downloadMusicSheetFiles
from omr.omr_source_service import prepareAudiverisInput
from omr.omr_status_service import setOmrCompleted
from omr.omr_status_service import setOmrFailed
from omr.omr_status_service import setOmrProcessing
from omr.omr_storage_service import uploadOmrFiles


def convertMusicSheet(
    sheetId,
    ownerId,
):
    sheetData = getMusicSheet(
        sheetId,
        ownerId,
    )

    jobFolder = None

    try:
        setOmrProcessing(
            sheetId
        )

        jobFolders = createOmrJobFolders(
            sheetId
        )

        jobFolder = jobFolders[
            "jobFolder"
        ]

        inputFolder = jobFolders[
            "inputFolder"
        ]

        outputFolder = jobFolders[
            "outputFolder"
        ]

        downloadedPaths = downloadMusicSheetFiles(
            sheetData,
            inputFolder,
        )

        audiverisInputPath = prepareAudiverisInput(
            sheetData,
            downloadedPaths,
            inputFolder,
        )

        musicXmlPath = convertToMusicXml(
            audiverisInputPath,
            outputFolder,
        )

        validationResult = validateMusicXml(
            musicXmlPath
        )

        mp3Path = exportMp3(
            musicXmlPath,
            outputFolder,
        )

        storagePaths = uploadOmrFiles(
            musicXmlPath,
            mp3Path,
            ownerId,
            sheetId,
        )

        setOmrCompleted(
            sheetId,
            storagePaths,
            validationResult,
        )

        return {
            "message": (
                "Music sheet converted successfully."
            ),
            "sheetId": sheetId,
            "title": sheetData.get(
                "title",
                "Untitled Sheet",
            ),
            "omrStatus": "completed",
            "partCount": validationResult[
                "partCount"
            ],
            "noteCount": validationResult[
                "noteCount"
            ],
            "musicXmlStoragePath": (
                storagePaths[
                    "musicXmlStoragePath"
                ]
            ),
            "previewAudioStoragePath": (
                storagePaths[
                    "previewAudioStoragePath"
                ]
            ),
        }
    except Exception as error:
        setOmrFailed(
            sheetId,
            error,
        )

        raise
    finally:
        if jobFolder is not None:
            deleteOmrJobFolder(
                jobFolder
            )
