import os
import subprocess
import sys
import tempfile
import types
import unittest
from types import SimpleNamespace
from unittest.mock import MagicMock
from unittest.mock import patch


fakeFirebaseService = types.ModuleType(
    "core.firebase_service"
)
fakeFirebaseService.getStorageBucket = (
    lambda: None
)
fakeFirebaseService.getDatabase = lambda: None
sys.modules.setdefault(
    "core.firebase_service",
    fakeFirebaseService,
)

from core import musescore_service
from omr import omr_conversion_service
from omr import omr_storage_service


class MuseScoreExportTests(unittest.TestCase):
    def setUp(self):
        self.temporaryDirectory = (
            tempfile.TemporaryDirectory()
        )
        self.musicXmlPath = os.path.join(
            self.temporaryDirectory.name,
            "recognized.mxl",
        )

        with open(
            self.musicXmlPath,
            "wb",
        ) as musicXmlFile:
            musicXmlFile.write(b"musicxml")

    def tearDown(self):
        self.temporaryDirectory.cleanup()

    def createSuccessfulRun(self, content):
        def successfulRun(command, **_):
            with open(command[2], "wb") as outputFile:
                outputFile.write(content)

            return SimpleNamespace(returncode=0)

        return successfulRun

    @patch.object(
        musescore_service,
        "isMuseScoreInstalled",
        return_value=True,
    )
    @patch.object(
        musescore_service.subprocess,
        "run",
    )
    def test_exports_non_empty_pdf(
        self,
        runMock,
        _,
    ):
        runMock.side_effect = self.createSuccessfulRun(
            b"pdf"
        )

        pdfPath = musescore_service.exportPdf(
            self.musicXmlPath
        )

        self.assertTrue(os.path.exists(pdfPath))
        self.assertGreater(os.path.getsize(pdfPath), 0)

    @patch.object(
        musescore_service,
        "isMuseScoreInstalled",
        return_value=True,
    )
    @patch.object(
        musescore_service.subprocess,
        "run",
    )
    def test_exports_non_empty_midi(
        self,
        runMock,
        _,
    ):
        runMock.side_effect = self.createSuccessfulRun(
            b"midi"
        )

        midiPath = musescore_service.exportMidi(
            self.musicXmlPath,
            self.temporaryDirectory.name,
        )

        self.assertTrue(os.path.exists(midiPath))
        self.assertGreater(os.path.getsize(midiPath), 0)

    @patch.object(
        musescore_service,
        "isMuseScoreInstalled",
        return_value=True,
    )
    @patch.object(
        musescore_service.subprocess,
        "run",
    )
    def test_rejects_midi_timeout(
        self,
        runMock,
        _,
    ):
        runMock.side_effect = subprocess.TimeoutExpired(
            cmd="MuseScore",
            timeout=600,
        )

        with self.assertRaises(RuntimeError):
            musescore_service.exportMidi(
                self.musicXmlPath,
                self.temporaryDirectory.name,
            )

    @patch.object(
        musescore_service,
        "isMuseScoreInstalled",
        return_value=True,
    )
    @patch.object(
        musescore_service.subprocess,
        "run",
    )
    def test_rejects_missing_midi_output(
        self,
        runMock,
        _,
    ):
        runMock.return_value = SimpleNamespace(
            returncode=0
        )

        with self.assertRaises(RuntimeError):
            musescore_service.exportMidi(
                self.musicXmlPath,
                self.temporaryDirectory.name,
            )

    @patch.object(
        musescore_service,
        "isMuseScoreInstalled",
        return_value=True,
    )
    @patch.object(
        musescore_service.subprocess,
        "run",
    )
    def test_rejects_empty_pdf_output(
        self,
        runMock,
        _,
    ):
        runMock.side_effect = self.createSuccessfulRun(
            b""
        )

        with self.assertRaises(RuntimeError):
            musescore_service.exportPdf(
                self.musicXmlPath
            )


class OmrStorageTests(unittest.TestCase):
    def setUp(self):
        self.temporaryDirectory = (
            tempfile.TemporaryDirectory()
        )
        self.localPaths = {}

        for fileName in [
            "recognized.mxl",
            "recognized.mid",
            "recognized.pdf",
            "preview.mp3",
        ]:
            filePath = os.path.join(
                self.temporaryDirectory.name,
                fileName,
            )

            with open(filePath, "wb") as outputFile:
                outputFile.write(b"generated")

            self.localPaths[fileName] = filePath

        self.storagePaths = {
            "musicXmlStoragePath": (
                "musicSheets/userA/sheetA/recognized.mxl"
            ),
            "midiStoragePath": (
                "musicSheets/userA/sheetA/recognized.mid"
            ),
            "recognizedPdfStoragePath": (
                "musicSheets/userA/sheetA/recognized.pdf"
            ),
            "previewAudioStoragePath": (
                "musicSheets/userA/sheetA/preview.mp3"
            ),
        }

    def tearDown(self):
        self.temporaryDirectory.cleanup()

    def createBucket(self):
        bucket = MagicMock()
        blobs = {
            storagePath: MagicMock()
            for storagePath in self.storagePaths.values()
        }
        bucket.blob.side_effect = (
            lambda storagePath: blobs[storagePath]
        )
        return bucket, blobs

    def uploadFiles(self):
        return omr_storage_service.uploadOmrFiles(
            self.localPaths["recognized.mxl"],
            self.localPaths["recognized.mid"],
            self.localPaths["recognized.pdf"],
            self.localPaths["preview.mp3"],
            "userA",
            "sheetA",
        )

    def test_uploads_all_generated_files(self):
        bucket, blobs = self.createBucket()

        with patch.object(
            omr_storage_service,
            "getStorageBucket",
            return_value=bucket,
        ):
            result = self.uploadFiles()

        self.assertEqual(result, self.storagePaths)
        blobs[
            self.storagePaths["midiStoragePath"]
        ].upload_from_filename.assert_called_once_with(
            self.localPaths["recognized.mid"],
            content_type="audio/midi",
        )
        blobs[
            self.storagePaths[
                "recognizedPdfStoragePath"
            ]
        ].upload_from_filename.assert_called_once_with(
            self.localPaths["recognized.pdf"],
            content_type="application/pdf",
        )

    def test_rolls_back_uploaded_files(self):
        bucket, blobs = self.createBucket()
        pdfBlob = blobs[
            self.storagePaths[
                "recognizedPdfStoragePath"
            ]
        ]
        pdfBlob.upload_from_filename.side_effect = (
            RuntimeError("upload failed")
        )

        with patch.object(
            omr_storage_service,
            "getStorageBucket",
            return_value=bucket,
        ):
            with self.assertRaises(RuntimeError):
                self.uploadFiles()

        blobs[
            self.storagePaths["musicXmlStoragePath"]
        ].delete.assert_called_once_with()
        blobs[
            self.storagePaths["midiStoragePath"]
        ].delete.assert_called_once_with()
        pdfBlob.delete.assert_not_called()


class OmrConversionTests(unittest.TestCase):
    def setUp(self):
        self.storagePaths = {
            "musicXmlStoragePath": "recognized.mxl",
            "midiStoragePath": "recognized.mid",
            "recognizedPdfStoragePath": "recognized.pdf",
            "previewAudioStoragePath": "preview.mp3",
        }

    def createConversionPatches(self):
        return {
            "getMusicSheet": patch.object(
                omr_conversion_service,
                "getMusicSheet",
                return_value={"title": "Test Sheet"},
            ),
            "setOmrProcessing": patch.object(
                omr_conversion_service,
                "setOmrProcessing",
            ),
            "setOmrCompleted": patch.object(
                omr_conversion_service,
                "setOmrCompleted",
            ),
            "setOmrFailed": patch.object(
                omr_conversion_service,
                "setOmrFailed",
            ),
            "createOmrJobFolders": patch.object(
                omr_conversion_service,
                "createOmrJobFolders",
                return_value={
                    "jobFolder": "job",
                    "inputFolder": "input",
                    "outputFolder": "output",
                },
            ),
            "downloadMusicSheetFiles": patch.object(
                omr_conversion_service,
                "downloadMusicSheetFiles",
                return_value=["source.pdf"],
            ),
            "prepareAudiverisInput": patch.object(
                omr_conversion_service,
                "prepareAudiverisInput",
                return_value="source.pdf",
            ),
            "convertToMusicXml": patch.object(
                omr_conversion_service,
                "convertToMusicXml",
                return_value="recognized.mxl",
            ),
            "validateMusicXml": patch.object(
                omr_conversion_service,
                "validateMusicXml",
                return_value={
                    "partCount": 1,
                    "noteCount": 4,
                },
            ),
            "exportPdf": patch.object(
                omr_conversion_service,
                "exportPdf",
                return_value="recognized.pdf",
            ),
            "exportMidi": patch.object(
                omr_conversion_service,
                "exportMidi",
                return_value="recognized.mid",
            ),
            "exportMp3": patch.object(
                omr_conversion_service,
                "exportMp3",
                return_value="preview.mp3",
            ),
            "uploadOmrFiles": patch.object(
                omr_conversion_service,
                "uploadOmrFiles",
                return_value=self.storagePaths,
            ),
            "deleteOmrJobFolder": patch.object(
                omr_conversion_service,
                "deleteOmrJobFolder",
            ),
        }

    def startPatches(self, patches):
        mocks = {
            name: patcher.start()
            for name, patcher in patches.items()
        }
        self.addCleanup(
            lambda: [
                patcher.stop()
                for patcher in patches.values()
            ]
        )
        return mocks

    def test_returns_and_saves_all_generated_paths(self):
        mocks = self.startPatches(
            self.createConversionPatches()
        )

        result = omr_conversion_service.convertMusicSheet(
            "sheetA",
            "userA",
        )

        self.assertEqual(
            result["midiStoragePath"],
            "recognized.mid",
        )
        self.assertEqual(
            result["recognizedPdfStoragePath"],
            "recognized.pdf",
        )
        mocks["uploadOmrFiles"].assert_called_once_with(
            "recognized.mxl",
            "recognized.mid",
            "recognized.pdf",
            "preview.mp3",
            "userA",
            "sheetA",
        )
        mocks["setOmrCompleted"].assert_called_once()
        mocks["setOmrFailed"].assert_not_called()

    def test_midi_failure_marks_recognition_failed(self):
        patches = self.createConversionPatches()
        patches["exportMidi"] = patch.object(
            omr_conversion_service,
            "exportMidi",
            side_effect=RuntimeError("MIDI failed"),
        )
        mocks = self.startPatches(patches)

        with self.assertRaises(RuntimeError):
            omr_conversion_service.convertMusicSheet(
                "sheetA",
                "userA",
            )

        mocks["uploadOmrFiles"].assert_not_called()
        mocks["setOmrFailed"].assert_called_once()
        mocks["deleteOmrJobFolder"].assert_called_once_with(
            "job"
        )


if __name__ == "__main__":
    unittest.main()
