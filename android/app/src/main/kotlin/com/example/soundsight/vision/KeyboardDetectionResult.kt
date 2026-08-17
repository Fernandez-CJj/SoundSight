package com.example.soundsight.vision

// Lists the keyboard-detection conditions that native Android code can report
// to Flutter while the calibration camera is scanning.
enum class KeyboardDetectionStatus {
    NOT_STARTED,
    SEARCHING,
    KEYBOARD_DETECTED,
    TOO_FEW_KEYS_VISIBLE,
    UNCERTAIN,
    FAILED
}

// Identifies the exact computer-vision check responsible for the current
// detection result. This provides more detail than the general status.
enum class KeyboardDetectionReason {
    NONE,
    OPEN_CV_NOT_READY,
    NO_KEYBOARD_CONTOUR,
    INVALID_KEYBOARD_REGION,
    TOO_FEW_BLACK_KEYS,
    TOO_FEW_WHITE_KEY_BOUNDARIES,
    TOO_FEW_KEY_FEATURES,
    INCONSISTENT_WHITE_KEY_SPACING,
    INCONSISTENT_BLACK_KEY_PATTERN,
    LOW_CONFIDENCE,
    STABILIZING,
    TRACKING_UNRELIABLE,
    PROCESSING_FAILED
}

// Stores the complete computer-vision result produced from one camera frame.
// A region is present only when enough keyboard evidence has been validated.
class KeyboardDetectionResult(
    val status: KeyboardDetectionStatus,
    val keyboardRegion: KeyboardRegion?,
    val blackKeyCandidates: List<BlackKeyCandidate>,
    val whiteKeyBoundaryPositions: List<Double>,
    val timestamp: Long,
    val confidence: Double,
    val diagnosticReason: KeyboardDetectionReason =
        KeyboardDetectionReason.NONE
) {
    // Converts the complete native detection result into maps, lists, strings,
    // and numbers that Flutter's platform channel can transfer to Dart.
    fun createFlutterData(): Map<String, Any?> {
        val detectionData = HashMap<String, Any?>()

        detectionData["status"] = status.name
        detectionData["diagnosticReason"] =
            diagnosticReason.name

        if (keyboardRegion == null) {
            detectionData["keyboardRegion"] = null
        } else {
            detectionData["keyboardRegion"] =
                keyboardRegion.createFlutterData()
        }

        val blackKeyDataList =
            ArrayList<Map<String, Any>>()

        for (blackKeyCandidate in blackKeyCandidates) {
            val blackKeyData =
                blackKeyCandidate.createFlutterData()

            blackKeyDataList.add(blackKeyData)
        }

        detectionData["blackKeyCandidates"] =
            blackKeyDataList

        detectionData["whiteKeyBoundaryPositions"] =
            whiteKeyBoundaryPositions

        detectionData["timestamp"] = timestamp
        detectionData["confidence"] = confidence

        return detectionData
    }
}