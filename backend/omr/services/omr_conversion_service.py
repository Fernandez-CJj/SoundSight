from core.integrations.musescore_service import exportMp3
from core.integrations.musescore_service import exportMidi
from core.integrations.musescore_service import exportPdf
from omr.processing.audiveris_service import convertToMusicXml
from omr.repositories.music_sheet_repository import getMusicSheet
from omr.processing.music_xml_extractor import extractMusicXml
from omr.processing.music_xml_piano_normalizer import normalizeMusicXmlForPiano
from omr.processing.music_xml_validator import validateMusicXml
from omr.processing.omr_source_service import createOmrJobFolders
from omr.processing.omr_source_service import deleteOmrJobFolder
from omr.processing.omr_source_service import downloadMusicSheetFiles
from omr.processing.omr_source_service import prepareAudiverisInput
from omr.repositories.omr_status_repository import setOmrCompleted
from omr.repositories.omr_status_repository import setOmrFailed
from omr.repositories.omr_status_repository import setOmrProcessing
from omr.repositories.omr_storage_repository import uploadOmrFiles


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
            sheetId,
            ownerId,
        )

        jobFolders = createOmrJobFolders()

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

        compressedMusicXmlPath = convertToMusicXml(
            audiverisInputPath,
            outputFolder,
        )

        musicXmlPath = extractMusicXml(
            compressedMusicXmlPath
        )

        musicXmlPath = normalizeMusicXmlForPiano(
            musicXmlPath
        )

        validationResult = validateMusicXml(
            musicXmlPath
        )

        pdfPath = exportPdf(
            musicXmlPath
        )

        midiPath = exportMidi(
            musicXmlPath,
            outputFolder,
        )

        mp3Path = exportMp3(
            musicXmlPath,
            outputFolder,
        )

        storagePaths = uploadOmrFiles(
            musicXmlPath,
            midiPath,
            pdfPath,
            mp3Path,
            ownerId,
            sheetId,
        )

        setOmrCompleted(
            sheetId,
            ownerId,
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
            "midiStoragePath": (
                storagePaths[
                    "midiStoragePath"
                ]
            ),
            "recognizedPdfStoragePath": (
                storagePaths[
                    "recognizedPdfStoragePath"
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
            ownerId,
            error,
        )

        raise
    finally:
        if jobFolder is not None:
            deleteOmrJobFolder(
                jobFolder
            )
