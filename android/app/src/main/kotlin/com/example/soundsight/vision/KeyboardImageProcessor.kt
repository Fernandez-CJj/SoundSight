package com.example.soundsight.vision

import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import org.opencv.core.CvType
import org.opencv.core.Mat
import org.opencv.core.Size
import org.opencv.imgproc.Imgproc
import org.opencv.core.MatOfPoint
import org.opencv.core.MatOfPoint2f
import org.opencv.core.Point
import kotlin.math.sqrt
import kotlin.math.abs
import android.util.Log
import org.opencv.core.Scalar

// Owns one background thread for keyboard image processing.
// Using one worker prevents OpenCV from slowing the camera-rendering thread.
class KeyboardImageProcessor(
    private val openCvManager: OpenCvManager
) {
    private val processingExecutor: ExecutorService =
        Executors.newSingleThreadExecutor()

    // Sends one copied camera image to the background worker.
    // The result explains whether a keyboard was detected in that image.
    // The completion callback always runs so another frame can be accepted.
    fun processCameraImage(
        cameraImageData: CameraImageData,
        onKeyboardDetectionResult: (KeyboardDetectionResult) -> Unit,
        onProcessingFinished: () -> Unit
    ) {
        processingExecutor.execute {
            var keyboardDetectionResult =
                KeyboardDetectionResult(
                    status = KeyboardDetectionStatus.FAILED,
                    keyboardRegion = null,
                    blackKeyCandidates = emptyList(),
                    whiteKeyBoundaryPositions = emptyList(),
                    timestamp = cameraImageData.timestamp,
                    confidence = 0.0,
                    diagnosticReason =
                        KeyboardDetectionReason.OPEN_CV_NOT_READY
                )

            try {
                if (openCvManager.isOpenCvLoaded()) {
                    val processedDetectionResult =
                        prepareGrayscaleImage(cameraImageData)

                    if (processedDetectionResult == null) {
                        keyboardDetectionResult =
                            KeyboardDetectionResult(
                                status =
                                    KeyboardDetectionStatus.SEARCHING,
                                keyboardRegion = null,
                                blackKeyCandidates = emptyList(),
                                whiteKeyBoundaryPositions = emptyList(),
                                timestamp = cameraImageData.timestamp,
                                confidence = 0.0,
                                diagnosticReason =
                                    KeyboardDetectionReason.NO_KEYBOARD_CONTOUR
                            )
                    } else {
                        keyboardDetectionResult =
                            processedDetectionResult
                    }
                }
            } catch (processingError: Exception) {
                Log.e(
                    "KeyboardImageProcessor",
                    "Keyboard image processing failed.",
                    processingError
                )

                keyboardDetectionResult =
                    KeyboardDetectionResult(
                        status = KeyboardDetectionStatus.FAILED,
                        keyboardRegion = null,
                        blackKeyCandidates = emptyList(),
                        whiteKeyBoundaryPositions = emptyList(),
                        timestamp = cameraImageData.timestamp,
                        confidence = 0.0,
                        diagnosticReason =
                            KeyboardDetectionReason.PROCESSING_FAILED
                    )
            }

            try {
                onKeyboardDetectionResult(
                    keyboardDetectionResult
                )
            } finally {
                onProcessingFinished()
            }
        }
    }

    // Converts SoundSight's grayscale pixels into OpenCV images, searches for a
    // visible keyboard region, and checks that region for piano-key evidence.
    private fun prepareGrayscaleImage(
        cameraImageData: CameraImageData
    ): KeyboardDetectionResult? {
        val grayscaleImage =
            Mat(
                cameraImageData.height,
                cameraImageData.width,
                CvType.CV_8UC1
            )

        // Stores a smoother version of the grayscale image with small camera noise
        // reduced before edge detection.
        val blurredImage = Mat()

        // Stores only the strong brightness changes that may represent keyboard,
        // piano-key, and surrounding-object boundaries.
        val edgeImage = Mat()

        // Stores key edges after nearby horizontal gaps have been connected.
        // This helps a partial keyboard form one larger candidate outline.
        val connectedEdgeImage = Mat()

        // Creates a wide, short processing shape. Its width connects neighboring
        // piano-key edges, while its small height limits unnecessary vertical joining.
        val horizontalConnectionWidth =
            maxOf(
                3,
                cameraImageData.width / 12
            )

        val edgeConnectionKernel =
            Imgproc.getStructuringElement(
                Imgproc.MORPH_RECT,
                Size(
                    horizontalConnectionWidth.toDouble(),
                    3.0
                )
            )

        // Stores the connected outlines found in the edge image.
        val detectedContours = ArrayList<MatOfPoint>()

        // Stores information about how the detected contours are related.
        // Only external contours are currently requested, but OpenCV still requires
        // this output Mat when findContours is called.
        val contourHierarchy = Mat()


        try {
            grayscaleImage.put(
                0,
                0,
                cameraImageData.grayscalePixels
            )
            // Reduces small pixel changes so they are less likely to become false edges.
            Imgproc.GaussianBlur(
                grayscaleImage,
                blurredImage,
                Size(5.0, 5.0),
                0.0
            )

            // Finds strong brightness changes that may form the keyboard outline.
            Imgproc.Canny(
                blurredImage,
                edgeImage,
                50.0,
                150.0
            )

            // Connects nearby horizontal gaps between piano-key edges without changing
            // the original grayscale camera image.
            Imgproc.morphologyEx(
                edgeImage,
                connectedEdgeImage,
                Imgproc.MORPH_CLOSE,
                edgeConnectionKernel
            )

            // Finds the outer connected outlines in the edge image.
            // The results may include the keyboard and unrelated surrounding objects.
            Imgproc.findContours(
                connectedEdgeImage,
                detectedContours,
                contourHierarchy,
                Imgproc.RETR_EXTERNAL,
                Imgproc.CHAIN_APPROX_SIMPLE
            )

            // Selects the eligible contour with the strongest combination of size and
            // vertical position. Lower outlines receive a small keyboard-area bonus.
            val bestKeyboardContour =
                findBestKeyboardContour(
                    detectedContours,
                    cameraImageData.width,
                    cameraImageData.height
                )

            // Stops region detection when no contour passes the initial size and shape
            // requirements. The finally block still releases all OpenCV memory.
            if (bestKeyboardContour == null) {
                return null
            }

            // Places a four-corner rotated rectangle around the possible visible
            // keyboard section, including sections clipped by the camera frame.
            val detectedCornerPoints =
                findFourContourPoints(
                    bestKeyboardContour,
                    cameraImageData.width,
                    cameraImageData.height
                )

            if (detectedCornerPoints == null) {
                return createUnreliableKeyboardDetectionResult(
                    status =
                        KeyboardDetectionStatus.UNCERTAIN,
                    blackKeyCandidates =
                        emptyList(),
                    whiteKeyBoundaryPositions =
                        emptyList(),
                    timestamp =
                        cameraImageData.timestamp,
                    confidence = 0.0,
                    diagnosticReason =
                        KeyboardDetectionReason.INVALID_KEYBOARD_REGION
                )
            }

            // Places the four detected points into a predictable clockwise order.
            val orderedCornerPoints =
                orderKeyboardCorners(
                    detectedCornerPoints
                )

            if (orderedCornerPoints == null) {
                return createUnreliableKeyboardDetectionResult(
                    status =
                        KeyboardDetectionStatus.UNCERTAIN,
                    blackKeyCandidates =
                        emptyList(),
                    whiteKeyBoundaryPositions =
                        emptyList(),
                    timestamp =
                        cameraImageData.timestamp,
                    confidence = 0.0,
                    diagnosticReason =
                        KeyboardDetectionReason.INVALID_KEYBOARD_REGION
                )
            }

            // Confirms that the corrected corner points remain inside the image and that
            // different corner positions were not assigned to the same point.
            val cornerPointsAreValid =
                areKeyboardCornerPointsValid(
                    orderedCornerPoints,
                    cameraImageData.width,
                    cameraImageData.height
                )

            if (cornerPointsAreValid == false) {
                return createUnreliableKeyboardDetectionResult(
                    status =
                        KeyboardDetectionStatus.UNCERTAIN,
                    blackKeyCandidates =
                        emptyList(),
                    whiteKeyBoundaryPositions =
                        emptyList(),
                    timestamp =
                        cameraImageData.timestamp,
                    confidence = 0.0,
                    diagnosticReason =
                        KeyboardDetectionReason.INVALID_KEYBOARD_REGION
                )
            }

            // Checks whether the visible section contains enough image area and horizontal
            // space for white-key and black-key detection in the next step.
            val visibleRegionIsUsable =
                isVisibleKeyboardRegionUsable(
                    orderedCornerPoints,
                    cameraImageData.width,
                    cameraImageData.height
                )

            if (visibleRegionIsUsable == false) {
                return createUnreliableKeyboardDetectionResult(
                    status =
                        KeyboardDetectionStatus.UNCERTAIN,
                    blackKeyCandidates =
                        emptyList(),
                    whiteKeyBoundaryPositions =
                        emptyList(),
                    timestamp =
                        cameraImageData.timestamp,
                    confidence = 0.0,
                    diagnosticReason =
                        KeyboardDetectionReason.INVALID_KEYBOARD_REGION
                )
            }

            // Combines the visible region corners with information from the source
            // camera image. Confidence remains zero until piano-key patterns are checked.
            val keyboardRegion =
                KeyboardRegion(
                    topLeft = orderedCornerPoints[0],
                    topRight = orderedCornerPoints[1],
                    bottomRight = orderedCornerPoints[2],
                    bottomLeft = orderedCornerPoints[3],
                    imageWidth = cameraImageData.width,
                    imageHeight = cameraImageData.height,
                    timestamp = cameraImageData.timestamp,
                    confidence = 0.0
                )

            // Holds a straightened copy of only the possible visible keyboard section.
            val straightKeyboardImage = Mat()

            // Holds a black-and-white processing image in which locally dark areas
            // become white so possible black keys can be found as connected shapes.
            val darkAreaMask = Mat()

            // Stores every connected dark-area outline found in the straightened image.
            // These contours remain unconfirmed until black-key shape filtering passes.
            val possibleBlackKeyContours =
                ArrayList<MatOfPoint>()

            try {
                val straightImageCreated =
                    straightenKeyboardRegion(
                        grayscaleImage,
                        keyboardRegion,
                        straightKeyboardImage
                    )

                if (straightImageCreated == false) {
                    return createUnreliableKeyboardDetectionResult(
                        status =
                            KeyboardDetectionStatus.UNCERTAIN,
                        blackKeyCandidates =
                            emptyList(),
                        whiteKeyBoundaryPositions =
                            emptyList(),
                        timestamp =
                            keyboardRegion.timestamp,
                        confidence = 0.0,
                        diagnosticReason =
                            KeyboardDetectionReason.INVALID_KEYBOARD_REGION
                    )
                }

                val darkAreaMaskCreated =
                    createDarkAreaMask(
                        straightKeyboardImage,
                        darkAreaMask
                    )

                if (darkAreaMaskCreated == false) {
                    return createUnreliableKeyboardDetectionResult(
                        status =
                            KeyboardDetectionStatus.UNCERTAIN,
                        blackKeyCandidates =
                            emptyList(),
                        whiteKeyBoundaryPositions =
                            emptyList(),
                        timestamp =
                            keyboardRegion.timestamp,
                        confidence = 0.0,
                        diagnosticReason =
                            KeyboardDetectionReason.INVALID_KEYBOARD_REGION
                    )
                }

                val blackKeyContoursFound =
                    findPossibleBlackKeyContours(
                        darkAreaMask,
                        possibleBlackKeyContours
                    )

                if (blackKeyContoursFound == false) {
                    return createUnreliableKeyboardDetectionResult(
                        status =
                            KeyboardDetectionStatus.TOO_FEW_KEYS_VISIBLE,
                        blackKeyCandidates =
                            emptyList(),
                        whiteKeyBoundaryPositions =
                            emptyList(),
                        timestamp =
                            keyboardRegion.timestamp,
                        confidence = 0.0,
                        diagnosticReason =
                            KeyboardDetectionReason.TOO_FEW_BLACK_KEYS
                    )
                }

                val blackKeyCandidates =
                    createBlackKeyCandidates(
                        possibleBlackKeyContours
                    )

                if (blackKeyCandidates.isEmpty()) {
                    return createUnreliableKeyboardDetectionResult(
                        status =
                            KeyboardDetectionStatus.TOO_FEW_KEYS_VISIBLE,
                        blackKeyCandidates =
                            blackKeyCandidates,
                        whiteKeyBoundaryPositions =
                            emptyList(),
                        timestamp =
                            keyboardRegion.timestamp,
                        confidence = 0.0,
                        diagnosticReason =
                            KeyboardDetectionReason.TOO_FEW_BLACK_KEYS
                    )
                }

                val filteredBlackKeyCandidates =
                    filterBlackKeyCandidates(
                        blackKeyCandidates,
                        straightKeyboardImage.cols(),
                        straightKeyboardImage.rows()
                    )

                if (filteredBlackKeyCandidates.isEmpty()) {
                    return createUnreliableKeyboardDetectionResult(
                        status =
                            KeyboardDetectionStatus.TOO_FEW_KEYS_VISIBLE,
                        blackKeyCandidates =
                            filteredBlackKeyCandidates,
                        whiteKeyBoundaryPositions =
                            emptyList(),
                        timestamp =
                            keyboardRegion.timestamp,
                        confidence = 0.0,
                        diagnosticReason =
                            KeyboardDetectionReason.TOO_FEW_BLACK_KEYS
                    )
                }

                val sortedBlackKeyCandidates =
                    sortBlackKeyCandidatesLeftToRight(
                        filteredBlackKeyCandidates
                    )

                val possibleWhiteKeyBoundaryPositions =
                    findPossibleWhiteKeyBoundaryPositions(
                        straightKeyboardImage
                    )

                if (possibleWhiteKeyBoundaryPositions.isEmpty()) {
                    return createUnreliableKeyboardDetectionResult(
                        status =
                            KeyboardDetectionStatus.TOO_FEW_KEYS_VISIBLE,
                        blackKeyCandidates =
                            sortedBlackKeyCandidates,
                        whiteKeyBoundaryPositions =
                            possibleWhiteKeyBoundaryPositions,
                        timestamp =
                            keyboardRegion.timestamp,
                        confidence = 0.0,
                        diagnosticReason =
                            KeyboardDetectionReason.TOO_FEW_WHITE_KEY_BOUNDARIES
                    )
                }

                val whiteKeyBoundaryPositions =
                    mergeNearbyWhiteKeyBoundaryPositions(
                        possibleWhiteKeyBoundaryPositions,
                        straightKeyboardImage.cols()
                    )

                if (whiteKeyBoundaryPositions.isEmpty()) {
                    return createUnreliableKeyboardDetectionResult(
                        status =
                            KeyboardDetectionStatus.TOO_FEW_KEYS_VISIBLE,
                        blackKeyCandidates =
                            sortedBlackKeyCandidates,
                        whiteKeyBoundaryPositions =
                            whiteKeyBoundaryPositions,
                        timestamp =
                            keyboardRegion.timestamp,
                        confidence = 0.0,
                        diagnosticReason =
                            KeyboardDetectionReason.TOO_FEW_WHITE_KEY_BOUNDARIES
                    )
                }

                val enoughVisibleKeyboardEvidence =
                    hasEnoughVisibleKeyboardEvidence(
                        sortedBlackKeyCandidates,
                        whiteKeyBoundaryPositions
                    )

                if (enoughVisibleKeyboardEvidence == false) {
                    return createUnreliableKeyboardDetectionResult(
                        status =
                            KeyboardDetectionStatus.TOO_FEW_KEYS_VISIBLE,
                        blackKeyCandidates =
                            sortedBlackKeyCandidates,
                        whiteKeyBoundaryPositions =
                            whiteKeyBoundaryPositions,
                        timestamp =
                            keyboardRegion.timestamp,
                        confidence = 0.0,
                        diagnosticReason =
                            KeyboardDetectionReason.TOO_FEW_KEY_FEATURES
                    )
                }

                val whiteKeySpacingIsConsistent =
                    hasConsistentWhiteKeySpacing(
                        whiteKeyBoundaryPositions
                    )

                if (whiteKeySpacingIsConsistent == false) {
                    return createUnreliableKeyboardDetectionResult(
                        status =
                            KeyboardDetectionStatus.UNCERTAIN,
                        blackKeyCandidates =
                            sortedBlackKeyCandidates,
                        whiteKeyBoundaryPositions =
                            whiteKeyBoundaryPositions,
                        timestamp =
                            keyboardRegion.timestamp,
                        confidence = 0.0,
                        diagnosticReason =
                            KeyboardDetectionReason.INCONSISTENT_WHITE_KEY_SPACING
                    )
                }

                val whiteKeySpacingQuality =
                    calculateWhiteKeySpacingQuality(
                        whiteKeyBoundaryPositions
                    )

                if (whiteKeySpacingQuality <= 0.0) {
                    return createUnreliableKeyboardDetectionResult(
                        status =
                            KeyboardDetectionStatus.UNCERTAIN,
                        blackKeyCandidates =
                            sortedBlackKeyCandidates,
                        whiteKeyBoundaryPositions =
                            whiteKeyBoundaryPositions,
                        timestamp =
                            keyboardRegion.timestamp,
                        confidence = 0.0,
                        diagnosticReason =
                            KeyboardDetectionReason.INCONSISTENT_WHITE_KEY_SPACING
                    )
                }

                val blackKeySpacingLooksLikePiano =
                    hasPianoLikeBlackKeySpacing(
                        sortedBlackKeyCandidates,
                        whiteKeyBoundaryPositions
                    )

                if (blackKeySpacingLooksLikePiano == false) {
                    return createUnreliableKeyboardDetectionResult(
                        status =
                            KeyboardDetectionStatus.UNCERTAIN,
                        blackKeyCandidates =
                            sortedBlackKeyCandidates,
                        whiteKeyBoundaryPositions =
                            whiteKeyBoundaryPositions,
                        timestamp =
                            keyboardRegion.timestamp,
                        confidence = 0.0,
                        diagnosticReason =
                            KeyboardDetectionReason.INCONSISTENT_BLACK_KEY_PATTERN
                    )
                }

                val blackKeyPatternQuality =
                    calculateBlackKeyPatternQuality(
                        sortedBlackKeyCandidates,
                        whiteKeyBoundaryPositions
                    )

                if (blackKeyPatternQuality <= 0.0) {
                    return createUnreliableKeyboardDetectionResult(
                        status =
                            KeyboardDetectionStatus.UNCERTAIN,
                        blackKeyCandidates =
                            sortedBlackKeyCandidates,
                        whiteKeyBoundaryPositions =
                            whiteKeyBoundaryPositions,
                        timestamp =
                            keyboardRegion.timestamp,
                        confidence = 0.0,
                        diagnosticReason =
                            KeyboardDetectionReason.INCONSISTENT_BLACK_KEY_PATTERN
                    )
                }


                val detectionConfidence =
                    calculateKeyboardDetectionConfidence(
                        sortedBlackKeyCandidates,
                        whiteKeyBoundaryPositions,
                        whiteKeySpacingQuality,
                        blackKeyPatternQuality
                    )

                val validatedKeyboardRegion =
                    KeyboardRegion(
                        topLeft = keyboardRegion.topLeft,
                        topRight = keyboardRegion.topRight,
                        bottomRight = keyboardRegion.bottomRight,
                        bottomLeft = keyboardRegion.bottomLeft,
                        imageWidth = keyboardRegion.imageWidth,
                        imageHeight = keyboardRegion.imageHeight,
                        timestamp = keyboardRegion.timestamp,
                        confidence = detectionConfidence
                    )

                val minimumReliableDetectionConfidence = 0.70

                var detectionStatus =
                    KeyboardDetectionStatus.UNCERTAIN

                var reliableKeyboardRegion: KeyboardRegion? = null

                // Low confidence is the default reason until the current frame
                // passes the minimum confidence requirement below.
                var diagnosticReason =
                    KeyboardDetectionReason.LOW_CONFIDENCE

                if (
                    detectionConfidence >=
                    minimumReliableDetectionConfidence
                ) {
                    detectionStatus =
                        KeyboardDetectionStatus.KEYBOARD_DETECTED

                    reliableKeyboardRegion =
                        validatedKeyboardRegion

                    // A successful frame has no failure reason.
                    diagnosticReason =
                        KeyboardDetectionReason.NONE
                }

                val keyboardDetectionResult =
                    KeyboardDetectionResult(
                        status = detectionStatus,
                        keyboardRegion = reliableKeyboardRegion,
                        blackKeyCandidates = sortedBlackKeyCandidates,
                        whiteKeyBoundaryPositions = whiteKeyBoundaryPositions,
                        timestamp = keyboardRegion.timestamp,
                        confidence = detectionConfidence,
                        diagnosticReason = diagnosticReason
                    )

                return keyboardDetectionResult
            } finally {
                for (
                possibleBlackKeyContour in
                possibleBlackKeyContours
                ) {
                    possibleBlackKeyContour.release()
                }

                darkAreaMask.release()
                straightKeyboardImage.release()
            }
        } finally {
            for (detectedContour in detectedContours) {
                detectedContour.release()
            }

            contourHierarchy.release()
            edgeConnectionKernel.release()
            connectedEdgeImage.release()
            edgeImage.release()
            blurredImage.release()
            grayscaleImage.release()
        }
    }

    // Creates a safe detection result that contains any useful evidence found by
    // OpenCV but never includes a keyboard region for overlays.
    private fun createUnreliableKeyboardDetectionResult(
        status: KeyboardDetectionStatus,
        blackKeyCandidates: List<BlackKeyCandidate>,
        whiteKeyBoundaryPositions: List<Double>,
        timestamp: Long,
        confidence: Double,
        diagnosticReason: KeyboardDetectionReason =
            KeyboardDetectionReason.NONE
    ): KeyboardDetectionResult {
        val keyboardDetectionResult =
            KeyboardDetectionResult(
                status = status,
                keyboardRegion = null,
                blackKeyCandidates = blackKeyCandidates,
                whiteKeyBoundaryPositions = whiteKeyBoundaryPositions,
                timestamp = timestamp,
                confidence = confidence,
                diagnosticReason = diagnosticReason
            )

        return keyboardDetectionResult
    }

    // Searches the detected outlines for a large visible area that could contain
    // part of a piano keyboard. This does not require the whole piano to be visible.
    private fun findBestKeyboardContour(
        detectedContours: List<MatOfPoint>,
        imageWidth: Int,
        imageHeight: Int
    ): MatOfPoint? {
        val completeImageArea =
            imageWidth.toDouble() *
                    imageHeight.toDouble()

        // Allows a partial keyboard section to remain a candidate while rejecting
        // extremely small outlines that cannot provide useful key details.
        val minimumVisibleRegionArea =
            completeImageArea * 0.03

        // A visible keyboard section should normally be at least as wide as it is
        // tall. Piano-key pattern checks will provide stronger validation later.
        val minimumVisibleRegionWidthToHeightRatio =
            1.0

        var bestContour: MatOfPoint? = null

        // Stores the highest candidate score found so far. The score considers both
        // the outline's size and its vertical position in the camera image.
        var bestContourScore = 0.0

        for (detectedContour in detectedContours) {
            val contourArea =
                Imgproc.contourArea(detectedContour)

            val contourRectangle =
                Imgproc.boundingRect(detectedContour)

            if (
                contourRectangle.width <= 0 ||
                contourRectangle.height <= 0
            ) {
                continue
            }

            val widthToHeightRatio =
                contourRectangle.width.toDouble() /
                        contourRectangle.height.toDouble()

            val contourIsLargeEnough =
                contourArea >= minimumVisibleRegionArea

            val contourCanContainVisibleKeys =
                widthToHeightRatio >=
                        minimumVisibleRegionWidthToHeightRatio

            // Finds the lowest vertical position reached by this outline.
            val contourBottom =
                contourRectangle.y + contourRectangle.height

            // Converts the bottom position into a value between approximately 0.0 and 1.0.
            val bottomPositionRatio =
                contourBottom.toDouble() / imageHeight.toDouble()

            // Gives outlines near the bottom of the image a bonus of up to 25%.
            val keyboardAreaBonus =
                1.0 + (bottomPositionRatio * 0.25)

            // Combines the outline's area and position into one comparison score.
            val contourScore =
                contourArea * keyboardAreaBonus


            if (
                contourIsLargeEnough &&
                contourCanContainVisibleKeys &&
                contourScore > bestContourScore
            ) {
                bestContour = detectedContour
                bestContourScore = contourScore
            }
        }

        return bestContour
    }

    // Places a four-corner rotated rectangle around the possible visible keyboard
    // area. This still works when the camera only sees part of the keyboard.
    private fun findFourContourPoints(
        keyboardContour: MatOfPoint,
        imageWidth: Int,
        imageHeight: Int
    ): List<ImagePoint>? {

        // A visible region needs at least three contour points before OpenCV can
        // calculate a rectangle around it.
        if (keyboardContour.total() < 3L) {
            return null
        }

        // Stops corner correction if the camera supplied an invalid image size.
        if (imageWidth <= 0 || imageHeight <= 0) {
            return null
        }

        // Pixel coordinates start at zero, so the final valid coordinate is one
        // less than the complete image width or height.
        val maximumHorizontalPosition =
            (imageWidth - 1).toDouble()

        val maximumVerticalPosition =
            (imageHeight - 1).toDouble()

        val decimalContour = MatOfPoint2f()

        try {
            keyboardContour.convertTo(
                decimalContour,
                CvType.CV_32FC2
            )

            val keyboardRectangle =
                Imgproc.minAreaRect(
                    decimalContour
                )

            val rectanglePoints =
                arrayOf(
                    Point(),
                    Point(),
                    Point(),
                    Point()
                )

            keyboardRectangle.points(
                rectanglePoints
            )

            val imagePoints =
                ArrayList<ImagePoint>()

            for (rectanglePoint in rectanglePoints) {
                // Begins with the coordinate calculated by OpenCV.
                var safeHorizontalPosition =
                    rectanglePoint.x

                var safeVerticalPosition =
                    rectanglePoint.y

                // Moves a corner at the left of the image onto the left image boundary.
                if (safeHorizontalPosition < 0.0) {
                    safeHorizontalPosition = 0.0
                } else if (
                    safeHorizontalPosition >
                    maximumHorizontalPosition
                ) {
                    // Moves a corner beyond the right side onto the right image boundary.
                    safeHorizontalPosition =
                        maximumHorizontalPosition
                }

                // Moves a corner above the image onto the top image boundary.
                if (safeVerticalPosition < 0.0) {
                    safeVerticalPosition = 0.0
                } else if (
                    safeVerticalPosition >
                    maximumVerticalPosition
                ) {
                    // Moves a corner below the image onto the bottom image boundary.
                    safeVerticalPosition =
                        maximumVerticalPosition
                }

                // Stores the corrected corner as an image point.
                val imagePoint =
                    ImagePoint(
                        x = safeHorizontalPosition,
                        y = safeVerticalPosition
                    )

                imagePoints.add(imagePoint)
            }

            return imagePoints
        } finally {
            decimalContour.release()
        }
    }

    // Arranges four unordered points into a consistent clockwise corner order.
    private fun orderKeyboardCorners(
        detectedPoints: List<ImagePoint>
    ): List<ImagePoint>? {
        if (detectedPoints.size != 4) {
            return null
        }

        val firstPoint = detectedPoints[0]

        var topLeft = firstPoint
        var topRight = firstPoint
        var bottomRight = firstPoint
        var bottomLeft = firstPoint

        var smallestCoordinateSum =
            firstPoint.x + firstPoint.y

        var largestCoordinateSum =
            firstPoint.x + firstPoint.y

        var smallestCoordinateDifference =
            firstPoint.x - firstPoint.y

        var largestCoordinateDifference =
            firstPoint.x - firstPoint.y

        for (detectedPoint in detectedPoints) {
            val coordinateSum =
                detectedPoint.x + detectedPoint.y

            val coordinateDifference =
                detectedPoint.x - detectedPoint.y

            if (coordinateSum < smallestCoordinateSum) {
                smallestCoordinateSum = coordinateSum
                topLeft = detectedPoint
            }

            if (coordinateSum > largestCoordinateSum) {
                largestCoordinateSum = coordinateSum
                bottomRight = detectedPoint
            }

            if (coordinateDifference > largestCoordinateDifference) {
                largestCoordinateDifference = coordinateDifference
                topRight = detectedPoint
            }

            if (coordinateDifference < smallestCoordinateDifference) {
                smallestCoordinateDifference = coordinateDifference
                bottomLeft = detectedPoint
            }
        }

        return listOf(
            topLeft,
            topRight,
            bottomRight,
            bottomLeft
        )
    }

    // Checks that every keyboard corner is inside the camera image and that
    // different corner positions were not assigned to the same point.
    private fun areKeyboardCornerPointsValid(
        orderedCornerPoints: List<ImagePoint>,
        imageWidth: Int,
        imageHeight: Int
    ): Boolean {
        if (orderedCornerPoints.size != 4) {
            return false
        }

        for (cornerPoint in orderedCornerPoints) {
            val horizontalPositionIsValid =
                cornerPoint.x >= 0.0 &&
                        cornerPoint.x < imageWidth.toDouble()

            val verticalPositionIsValid =
                cornerPoint.y >= 0.0 &&
                        cornerPoint.y < imageHeight.toDouble()

            if (
                horizontalPositionIsValid == false ||
                verticalPositionIsValid == false
            ) {
                return false
            }
        }

        for (
        firstPointIndex in
        orderedCornerPoints.indices
        ) {
            val firstPoint =
                orderedCornerPoints[firstPointIndex]

            for (
            secondPointIndex in
            firstPointIndex + 1 until orderedCornerPoints.size
            ) {
                val secondPoint =
                    orderedCornerPoints[secondPointIndex]

                val horizontalPositionsMatch =
                    firstPoint.x == secondPoint.x

                val verticalPositionsMatch =
                    firstPoint.y == secondPoint.y

                if (
                    horizontalPositionsMatch &&
                    verticalPositionsMatch
                ) {
                    return false
                }
            }
        }

        return true
    }

    // Checks whether a partial keyboard candidate is large and wide enough for
    // later key detection without requiring the complete piano to be visible.
    private fun isVisibleKeyboardRegionUsable(
        orderedCornerPoints: List<ImagePoint>,
        imageWidth: Int,
        imageHeight: Int
    ): Boolean {
        val topLeft = orderedCornerPoints[0]
        val topRight = orderedCornerPoints[1]
        val bottomRight = orderedCornerPoints[2]
        val bottomLeft = orderedCornerPoints[3]

        val topWidth =
            calculateDistanceBetweenPoints(
                topLeft,
                topRight
            )

        val bottomWidth =
            calculateDistanceBetweenPoints(
                bottomLeft,
                bottomRight
            )

        val leftHeight =
            calculateDistanceBetweenPoints(
                topLeft,
                bottomLeft
            )

        val rightHeight =
            calculateDistanceBetweenPoints(
                topRight,
                bottomRight
            )

        if (
            topWidth <= 0.0 ||
            bottomWidth <= 0.0 ||
            leftHeight <= 0.0 ||
            rightHeight <= 0.0
        ) {
            return false
        }

        val averageWidth =
            (topWidth + bottomWidth) / 2.0

        val averageHeight =
            (leftHeight + rightHeight) / 2.0

        val widthToHeightRatio =
            averageWidth / averageHeight

        if (widthToHeightRatio < 1.0) {
            return false
        }

        val visibleRegionArea =
            averageWidth * averageHeight

        val completeImageArea =
            imageWidth.toDouble() *
                    imageHeight.toDouble()

        val minimumVisibleRegionArea =
            completeImageArea * 0.03

        if (visibleRegionArea < minimumVisibleRegionArea) {
            return false
        }

        return true
    }

    // Measures the straight-line pixel distance between two image points.
    private fun calculateDistanceBetweenPoints(
        firstPoint: ImagePoint,
        secondPoint: ImagePoint
    ): Double {
        val horizontalDistance =
            secondPoint.x - firstPoint.x

        val verticalDistance =
            secondPoint.y - firstPoint.y

        val squaredDistance =
            (horizontalDistance * horizontalDistance) +
                    (verticalDistance * verticalDistance)

        return sqrt(squaredDistance)
    }

    // Calculates the output size needed when the tilted keyboard region is
    // straightened into a separate image for piano-key detection.
    private fun calculateStraightKeyboardImageSize(
        keyboardRegion: KeyboardRegion
    ): Size? {
        val topWidth =
            calculateDistanceBetweenPoints(
                keyboardRegion.topLeft,
                keyboardRegion.topRight
            )

        val bottomWidth =
            calculateDistanceBetweenPoints(
                keyboardRegion.bottomLeft,
                keyboardRegion.bottomRight
            )

        val leftHeight =
            calculateDistanceBetweenPoints(
                keyboardRegion.topLeft,
                keyboardRegion.bottomLeft
            )

        val rightHeight =
            calculateDistanceBetweenPoints(
                keyboardRegion.topRight,
                keyboardRegion.bottomRight
            )

        val straightImageWidth =
            maxOf(
                topWidth,
                bottomWidth
            )

        val straightImageHeight =
            maxOf(
                leftHeight,
                rightHeight
            )

        if (
            straightImageWidth < 2.0 ||
            straightImageHeight < 2.0
        ) {
            return null
        }

        return Size(
            straightImageWidth,
            straightImageHeight
        )
    }

    // Copies the tilted visible keyboard region into a separate straight image.
    // The caller owns the output Mat and must release it after key detection finishes.
    private fun straightenKeyboardRegion(
        grayscaleImage: Mat,
        keyboardRegion: KeyboardRegion,
        straightKeyboardImage: Mat
    ): Boolean {
        val straightImageSize =
            calculateStraightKeyboardImageSize(
                keyboardRegion
            )

        if (straightImageSize == null) {
            return false
        }

        val sourcePoints =
            MatOfPoint2f(
                Point(
                    keyboardRegion.topLeft.x,
                    keyboardRegion.topLeft.y
                ),
                Point(
                    keyboardRegion.topRight.x,
                    keyboardRegion.topRight.y
                ),
                Point(
                    keyboardRegion.bottomRight.x,
                    keyboardRegion.bottomRight.y
                ),
                Point(
                    keyboardRegion.bottomLeft.x,
                    keyboardRegion.bottomLeft.y
                )
            )

        val destinationPoints =
            MatOfPoint2f(
                Point(
                    0.0,
                    0.0
                ),
                Point(
                    straightImageSize.width - 1.0,
                    0.0
                ),
                Point(
                    straightImageSize.width - 1.0,
                    straightImageSize.height - 1.0
                ),
                Point(
                    0.0,
                    straightImageSize.height - 1.0
                )
            )

        try {
            val perspectiveTransformation =
                Imgproc.getPerspectiveTransform(
                    sourcePoints,
                    destinationPoints
                )

            try {
                Imgproc.warpPerspective(
                    grayscaleImage,
                    straightKeyboardImage,
                    perspectiveTransformation,
                    straightImageSize
                )

                return straightKeyboardImage.empty() == false
            } finally {
                perspectiveTransformation.release()
            }
        } finally {
            destinationPoints.release()
            sourcePoints.release()
        }
    }

    // Creates a two-color mask in which locally dark image areas become white.
    // These white mask areas will later be checked as possible black piano keys.
    private fun createDarkAreaMask(
        straightKeyboardImage: Mat,
        darkAreaMask: Mat
    ): Boolean {
        if (straightKeyboardImage.empty()) {
            return false
        }

        val thresholdBlockSize = 31

        if (
            straightKeyboardImage.cols() < thresholdBlockSize ||
            straightKeyboardImage.rows() < thresholdBlockSize
        ) {
            return false
        }

        val smoothedKeyboardImage = Mat()

        try {
            Imgproc.GaussianBlur(
                straightKeyboardImage,
                smoothedKeyboardImage,
                Size(5.0, 5.0),
                0.0
            )

            Imgproc.adaptiveThreshold(
                smoothedKeyboardImage,
                darkAreaMask,
                255.0,
                Imgproc.ADAPTIVE_THRESH_GAUSSIAN_C,
                Imgproc.THRESH_BINARY_INV,
                thresholdBlockSize,
                7.0
            )

            // Stores the complete width of the black-and-white mask.
            val imageWidth =
                darkAreaMask.cols()

            // Stores the complete height of the black-and-white mask.
            val imageHeight =
                darkAreaMask.rows()

            // Represents the upper 30% of the mask where the dark piano panel may appear.
            val topPanelPercentage = 0.30

            // Converts the 30% value into an actual number of image rows.
            val topPanelRegionHeight =
                (
                        imageHeight.toDouble() *
                                topPanelPercentage
                        ).toInt()

            // Confirms that the calculated upper region is inside the image.
            if (
                topPanelRegionHeight > 0 &&
                topPanelRegionHeight < imageHeight
            ) {
                // Creates a temporary OpenCV view of the upper mask region.
                val topPanelRegion =
                    darkAreaMask.submat(
                        0,
                        topPanelRegionHeight,
                        0,
                        imageWidth
                    )

                try {
                    // Pixel value zero represents black in this two-color mask.
                    val blackMaskValue =
                        Scalar(0.0)

                    // Changes every pixel in the selected upper region to black.
                    topPanelRegion.setTo(
                        blackMaskValue
                    )
                } finally {
                    // Releases the temporary view after the original mask has been changed.
                    topPanelRegion.release()
                }
            }

            // Calculates the upper part of the straightened keyboard image that may contain
            // the dark horizontal piano panel connected to the tops of the black keys.
            val topPanelRegionHeight =
                (
                        darkAreaMask.rows().toDouble() *
                                0.30
                        ).toInt()

            // Confirms that the region has a usable height before creating an OpenCV view.
            if (
                topPanelRegionHeight > 0 &&
                topPanelRegionHeight < darkAreaMask.rows()
            ) {
                // Creates a temporary view of only the upper 30% of the existing mask.
                // Changing this view also changes the matching pixels in darkAreaMask.
                val topPanelRegion =
                    darkAreaMask.submat(
                        0,
                        topPanelRegionHeight,
                        0,
                        darkAreaMask.cols()
                    )

                try {
                    // Changes the upper mask area to black so it cannot connect several
                    // physical black keys into one large horizontal contour.
                    topPanelRegion.setTo(
                        Scalar(0.0)
                    )
                } finally {
                    // Releases the temporary OpenCV view after the original mask is updated.
                    topPanelRegion.release()
                }
            }

            return darkAreaMask.empty() == false
        } finally {
            smoothedKeyboardImage.release()
        }
    }

    // Finds connected white shapes inside the dark-area mask.
    // Each returned contour is only a possible black key until filtering passes.
    private fun findPossibleBlackKeyContours(
        darkAreaMask: Mat,
        possibleBlackKeyContours: MutableList<MatOfPoint>
    ): Boolean {
        if (darkAreaMask.empty()) {
            return false
        }

        val contourHierarchy = Mat()

        try {
            Imgproc.findContours(
                darkAreaMask,
                possibleBlackKeyContours,
                contourHierarchy,
                Imgproc.RETR_EXTERNAL,
                Imgproc.CHAIN_APPROX_SIMPLE
            )

            return possibleBlackKeyContours.isNotEmpty()
        } finally {
            contourHierarchy.release()
        }
    }

    // Converts one connected dark-area contour into basic position and size
    // information. Invalid or empty contours return null.
    private fun createBlackKeyCandidate(
        possibleBlackKeyContour: MatOfPoint
    ): BlackKeyCandidate? {
        val contourRectangle =
            Imgproc.boundingRect(
                possibleBlackKeyContour
            )

        if (
            contourRectangle.width <= 0 ||
            contourRectangle.height <= 0
        ) {
            return null
        }

        val contourArea =
            Imgproc.contourArea(
                possibleBlackKeyContour
            )

        if (contourArea <= 0.0) {
            return null
        }

        return BlackKeyCandidate(
            left = contourRectangle.x,
            top = contourRectangle.y,
            width = contourRectangle.width,
            height = contourRectangle.height,
            contourArea = contourArea
        )
    }

    // Converts every usable dark-area contour into a basic black-key candidate.
    // Invalid contours are skipped instead of being added to the result.
    private fun createBlackKeyCandidates(
        possibleBlackKeyContours: List<MatOfPoint>
    ): List<BlackKeyCandidate> {
        val blackKeyCandidates =
            ArrayList<BlackKeyCandidate>()

        for (
        possibleBlackKeyContour in
        possibleBlackKeyContours
        ) {
            val blackKeyCandidate =
                createBlackKeyCandidate(
                    possibleBlackKeyContour
                )

            if (blackKeyCandidate != null) {
                blackKeyCandidates.add(
                    blackKeyCandidate
                )
            }
        }

        return blackKeyCandidates
    }

    // Keeps candidates whose position and proportions can reasonably represent
    // black keys inside the straightened visible keyboard section.
    private fun filterBlackKeyCandidates(
        blackKeyCandidates: List<BlackKeyCandidate>,
        imageWidth: Int,
        imageHeight: Int
    ): List<BlackKeyCandidate> {
        val filteredBlackKeyCandidates =
            ArrayList<BlackKeyCandidate>()

        if (imageWidth <= 0 || imageHeight <= 0) {
            return filteredBlackKeyCandidates
        }

        val minimumCandidateWidth =
            imageHeight.toDouble() * 0.02

        val maximumCandidateWidth =
            imageHeight.toDouble() * 0.30

        val minimumCandidateHeight =
            imageHeight.toDouble() * 0.15

        val maximumCandidateHeight =
            imageHeight.toDouble() * 0.85

        val maximumCandidateTop =
            imageHeight.toDouble() * 0.50

        for (blackKeyCandidate in blackKeyCandidates) {
            val candidateRight =
                blackKeyCandidate.left +
                        blackKeyCandidate.width

            val candidateBottom =
                blackKeyCandidate.top +
                        blackKeyCandidate.height

            val candidateIsInsideImage =
                blackKeyCandidate.left >= 0 &&
                        blackKeyCandidate.top >= 0 &&
                        candidateRight <= imageWidth &&
                        candidateBottom <= imageHeight

            if (candidateIsInsideImage == false) {
                continue
            }

            val heightToWidthRatio =
                blackKeyCandidate.height.toDouble() /
                        blackKeyCandidate.width.toDouble()

            val candidateRectangleArea =
                blackKeyCandidate.width.toDouble() *
                        blackKeyCandidate.height.toDouble()

            val filledAreaRatio =
                blackKeyCandidate.contourArea /
                        candidateRectangleArea

            val candidateWidthIsValid =
                blackKeyCandidate.width >= minimumCandidateWidth &&
                        blackKeyCandidate.width <= maximumCandidateWidth

            val candidateHeightIsValid =
                blackKeyCandidate.height >= minimumCandidateHeight &&
                        blackKeyCandidate.height <= maximumCandidateHeight

            val candidateShapeIsValid =
                heightToWidthRatio >= 1.20 &&
                        heightToWidthRatio <= 10.0

            val candidateAreaIsFilled =
                filledAreaRatio >= 0.40

            val candidatePositionIsValid =
                blackKeyCandidate.top <= maximumCandidateTop

            if (
                candidateWidthIsValid &&
                candidateHeightIsValid &&
                candidateShapeIsValid &&
                candidateAreaIsFilled &&
                candidatePositionIsValid
            ) {
                filteredBlackKeyCandidates.add(
                    blackKeyCandidate
                )
            }
        }

        return filteredBlackKeyCandidates
    }

    // Creates a new list in which possible black keys are arranged from the
    // left side of the straightened keyboard image to the right side.
    private fun sortBlackKeyCandidatesLeftToRight(
        blackKeyCandidates: List<BlackKeyCandidate>
    ): List<BlackKeyCandidate> {
        val sortedBlackKeyCandidates =
            ArrayList<BlackKeyCandidate>()

        for (blackKeyCandidate in blackKeyCandidates) {
            var insertionIndex = 0

            while (
                insertionIndex < sortedBlackKeyCandidates.size &&
                sortedBlackKeyCandidates[insertionIndex].left <=
                blackKeyCandidate.left
            ) {
                insertionIndex++
            }

            sortedBlackKeyCandidates.add(
                insertionIndex,
                blackKeyCandidate
            )
        }

        return sortedBlackKeyCandidates
    }

    // Searches the lower part of the straightened keyboard image for mostly
    // vertical lines that may separate neighboring white piano keys.
    private fun findPossibleWhiteKeyBoundaryPositions(
        straightKeyboardImage: Mat
    ): List<Double> {
        val boundaryPositions =
            ArrayList<Double>()

        if (straightKeyboardImage.empty()) {
            return boundaryPositions
        }

        val imageWidth =
            straightKeyboardImage.cols()

        val imageHeight =
            straightKeyboardImage.rows()

        val lowerRegionStart =
            (imageHeight.toDouble() * 0.55).toInt()

        if (
            imageWidth <= 0 ||
            lowerRegionStart < 0 ||
            lowerRegionStart >= imageHeight
        ) {
            return boundaryPositions
        }

        val lowerKeyboardImage =
            straightKeyboardImage.submat(
                lowerRegionStart,
                imageHeight,
                0,
                imageWidth
            )

        val smoothedLowerImage = Mat()
        val lowerEdgeImage = Mat()
        val detectedLines = Mat()

        try {
            Imgproc.GaussianBlur(
                lowerKeyboardImage,
                smoothedLowerImage,
                Size(5.0, 5.0),
                0.0
            )

            Imgproc.Canny(
                smoothedLowerImage,
                lowerEdgeImage,
                40.0,
                120.0
            )

            val minimumLineLength =
                lowerKeyboardImage.rows().toDouble() *
                        0.50

            val maximumLineGap =
                lowerKeyboardImage.rows().toDouble() *
                        0.15

            Imgproc.HoughLinesP(
                lowerEdgeImage,
                detectedLines,
                1.0,
                Math.PI / 180.0,
                20,
                minimumLineLength,
                maximumLineGap
            )

            for (
            lineIndex in
            0 until detectedLines.rows()
            ) {
                val lineValues =
                    detectedLines.get(
                        lineIndex,
                        0
                    )

                if (
                    lineValues == null ||
                    lineValues.size < 4
                ) {
                    continue
                }

                val startX = lineValues[0]
                val startY = lineValues[1]
                val endX = lineValues[2]
                val endY = lineValues[3]

                val horizontalDistance =
                    abs(endX - startX)

                val verticalDistance =
                    abs(endY - startY)

                if (verticalDistance <= 0.0) {
                    continue
                }

                val lineIsMostlyVertical =
                    horizontalDistance <=
                            verticalDistance * 0.20

                if (lineIsMostlyVertical == false) {
                    continue
                }

                val boundaryCenterX =
                    (startX + endX) / 2.0

                boundaryPositions.add(
                    boundaryCenterX
                )
            }

            return boundaryPositions
        } finally {
            detectedLines.release()
            lowerEdgeImage.release()
            smoothedLowerImage.release()
            lowerKeyboardImage.release()
        }
    }

    // Sorts possible white-key boundary positions from left to right and combines
    // nearby detections that probably belong to the same physical key boundary.
    private fun mergeNearbyWhiteKeyBoundaryPositions(
        possibleBoundaryPositions: List<Double>,
        imageWidth: Int
    ): List<Double> {
        val sortedBoundaryPositions =
            ArrayList<Double>()

        if (imageWidth <= 0) {
            return sortedBoundaryPositions
        }

        for (
        possibleBoundaryPosition in
        possibleBoundaryPositions
        ) {
            if (
                possibleBoundaryPosition < 0.0 ||
                possibleBoundaryPosition >= imageWidth.toDouble()
            ) {
                continue
            }

            var insertionIndex = 0

            while (
                insertionIndex < sortedBoundaryPositions.size &&
                sortedBoundaryPositions[insertionIndex] <=
                possibleBoundaryPosition
            ) {
                insertionIndex++
            }

            sortedBoundaryPositions.add(
                insertionIndex,
                possibleBoundaryPosition
            )
        }

        val mergedBoundaryPositions =
            ArrayList<Double>()

        if (sortedBoundaryPositions.isEmpty()) {
            return mergedBoundaryPositions
        }

        val mergeDistance =
            maxOf(
                3.0,
                imageWidth.toDouble() * 0.01
            )

        var currentGroupTotal =
            sortedBoundaryPositions[0]

        var currentGroupCount = 1

        for (
        positionIndex in
        1 until sortedBoundaryPositions.size
        ) {
            val currentPosition =
                sortedBoundaryPositions[positionIndex]

            val currentGroupAverage =
                currentGroupTotal /
                        currentGroupCount.toDouble()

            val distanceFromCurrentGroup =
                abs(
                    currentPosition -
                            currentGroupAverage
                )

            if (distanceFromCurrentGroup <= mergeDistance) {
                currentGroupTotal += currentPosition
                currentGroupCount++
            } else {
                mergedBoundaryPositions.add(
                    currentGroupAverage
                )

                currentGroupTotal = currentPosition
                currentGroupCount = 1
            }
        }

        val finalGroupAverage =
            currentGroupTotal /
                    currentGroupCount.toDouble()

        mergedBoundaryPositions.add(
            finalGroupAverage
        )

        return mergedBoundaryPositions
    }

    // Checks whether the current camera view contains enough possible black keys
    // and white-key boundaries to begin reliable piano-pattern validation.
    private fun hasEnoughVisibleKeyboardEvidence(
        blackKeyCandidates: List<BlackKeyCandidate>,
        whiteKeyBoundaryPositions: List<Double>
    ): Boolean {
        val minimumBlackKeyCount = 4
        val minimumWhiteKeyBoundaryCount = 6

        val enoughBlackKeys =
            blackKeyCandidates.size >=
                    minimumBlackKeyCount

        val enoughWhiteKeyBoundaries =
            whiteKeyBoundaryPositions.size >=
                    minimumWhiteKeyBoundaryCount

        return enoughBlackKeys &&
                enoughWhiteKeyBoundaries
    }

    // Checks whether neighboring white-key boundary positions have similar
// distances, allowing moderate variation from perspective and detection noise.
    private fun hasConsistentWhiteKeySpacing(
        whiteKeyBoundaryPositions: List<Double>
    ): Boolean {
        if (whiteKeyBoundaryPositions.size < 2) {
            return false
        }

        val boundaryDistances =
            ArrayList<Double>()

        var totalBoundaryDistance = 0.0

        for (
        positionIndex in
        1 until whiteKeyBoundaryPositions.size
        ) {
            val previousPosition =
                whiteKeyBoundaryPositions[positionIndex - 1]

            val currentPosition =
                whiteKeyBoundaryPositions[positionIndex]

            val boundaryDistance =
                currentPosition - previousPosition

            if (boundaryDistance <= 0.0) {
                return false
            }

            boundaryDistances.add(
                boundaryDistance
            )

            totalBoundaryDistance +=
                boundaryDistance
        }

        val averageBoundaryDistance =
            totalBoundaryDistance /
                    boundaryDistances.size.toDouble()

        val minimumAllowedDistance =
            averageBoundaryDistance * 0.55

        val maximumAllowedDistance =
            averageBoundaryDistance * 1.45

        for (boundaryDistance in boundaryDistances) {
            if (
                boundaryDistance < minimumAllowedDistance ||
                boundaryDistance > maximumAllowedDistance
            ) {
                return false
            }
        }

        return true
    }

    // Measures how closely the detected white-key gaps match their average.
    // A result near 1.0 means the spacing is highly consistent.
    private fun calculateWhiteKeySpacingQuality(
        whiteKeyBoundaryPositions: List<Double>
    ): Double {
        if (whiteKeyBoundaryPositions.size < 2) {
            return 0.0
        }

        val boundaryDistances =
            ArrayList<Double>()

        var totalBoundaryDistance = 0.0

        for (
        positionIndex in
        1 until whiteKeyBoundaryPositions.size
        ) {
            val previousPosition =
                whiteKeyBoundaryPositions[positionIndex - 1]

            val currentPosition =
                whiteKeyBoundaryPositions[positionIndex]

            val boundaryDistance =
                currentPosition - previousPosition

            if (boundaryDistance <= 0.0) {
                return 0.0
            }

            boundaryDistances.add(
                boundaryDistance
            )

            totalBoundaryDistance +=
                boundaryDistance
        }

        val averageBoundaryDistance =
            totalBoundaryDistance /
                    boundaryDistances.size.toDouble()

        if (averageBoundaryDistance <= 0.0) {
            return 0.0
        }

        var totalPercentageDifference = 0.0

        for (boundaryDistance in boundaryDistances) {
            val distanceDifference =
                abs(
                    boundaryDistance -
                            averageBoundaryDistance
                )

            val percentageDifference =
                distanceDifference /
                        averageBoundaryDistance

            totalPercentageDifference +=
                percentageDifference
        }

        val averagePercentageDifference =
            totalPercentageDifference /
                    boundaryDistances.size.toDouble()

        val maximumAcceptedDifference = 0.45

        val spacingQuality =
            1.0 -
                    (
                            averagePercentageDifference /
                                    maximumAcceptedDifference
                            )

        if (spacingQuality < 0.0) {
            return 0.0
        }

        if (spacingQuality > 1.0) {
            return 1.0
        }

        return spacingQuality
    }

    // Checks whether black-key center spacing contains the small and large gaps
    // expected from repeating groups of two and three piano black keys.
    private fun hasPianoLikeBlackKeySpacing(
        sortedBlackKeyCandidates: List<BlackKeyCandidate>,
        whiteKeyBoundaryPositions: List<Double>
    ): Boolean {
        if (
            sortedBlackKeyCandidates.size < 2 ||
            whiteKeyBoundaryPositions.size < 2
        ) {
            return false
        }

        var totalWhiteKeySpacing = 0.0

        for (
        boundaryIndex in
        1 until whiteKeyBoundaryPositions.size
        ) {
            val previousBoundary =
                whiteKeyBoundaryPositions[boundaryIndex - 1]

            val currentBoundary =
                whiteKeyBoundaryPositions[boundaryIndex]

            val whiteKeySpacing =
                currentBoundary - previousBoundary

            if (whiteKeySpacing <= 0.0) {
                return false
            }

            totalWhiteKeySpacing +=
                whiteKeySpacing
        }

        val numberOfWhiteKeySpaces =
            whiteKeyBoundaryPositions.size - 1

        val averageWhiteKeySpacing =
            totalWhiteKeySpacing /
                    numberOfWhiteKeySpaces.toDouble()

        if (averageWhiteKeySpacing <= 0.0) {
            return false
        }

        var smallGapFound = false
        var largeGapFound = false

        var consecutiveSmallGapCount = 0
        var previousGapWasLarge = false

        for (
        candidateIndex in
        1 until sortedBlackKeyCandidates.size
        ) {
            val previousCandidate =
                sortedBlackKeyCandidates[candidateIndex - 1]

            val currentCandidate =
                sortedBlackKeyCandidates[candidateIndex]

            val previousCandidateCenter =
                previousCandidate.left.toDouble() +
                        (previousCandidate.width.toDouble() / 2.0)

            val currentCandidateCenter =
                currentCandidate.left.toDouble() +
                        (currentCandidate.width.toDouble() / 2.0)

            val blackKeyCenterDistance =
                currentCandidateCenter -
                        previousCandidateCenter

            if (blackKeyCenterDistance <= 0.0) {
                return false
            }

            val normalizedBlackKeyDistance =
                blackKeyCenterDistance /
                        averageWhiteKeySpacing

            val gapIsSmall =
                normalizedBlackKeyDistance >= 0.55 &&
                        normalizedBlackKeyDistance <= 1.45

            val gapIsLarge =
                normalizedBlackKeyDistance > 1.45 &&
                        normalizedBlackKeyDistance <= 2.55

            if (gapIsSmall) {
                smallGapFound = true
                consecutiveSmallGapCount++
                previousGapWasLarge = false

                if (consecutiveSmallGapCount > 2) {
                    return false
                }
            } else if (gapIsLarge) {
                largeGapFound = true

                if (previousGapWasLarge) {
                    return false
                }

                consecutiveSmallGapCount = 0
                previousGapWasLarge = true
            } else {
                return false
            }
        }

        return smallGapFound &&
                largeGapFound
    }

    // Measures how closely black-key center distances match the expected gaps
    // of approximately one or two white-key widths.
    private fun calculateBlackKeyPatternQuality(
        sortedBlackKeyCandidates: List<BlackKeyCandidate>,
        whiteKeyBoundaryPositions: List<Double>
    ): Double {
        if (
            sortedBlackKeyCandidates.size < 2 ||
            whiteKeyBoundaryPositions.size < 2
        ) {
            return 0.0
        }

        var totalWhiteKeySpacing = 0.0

        for (
        boundaryIndex in
        1 until whiteKeyBoundaryPositions.size
        ) {
            val previousBoundary =
                whiteKeyBoundaryPositions[boundaryIndex - 1]

            val currentBoundary =
                whiteKeyBoundaryPositions[boundaryIndex]

            val whiteKeySpacing =
                currentBoundary - previousBoundary

            if (whiteKeySpacing <= 0.0) {
                return 0.0
            }

            totalWhiteKeySpacing +=
                whiteKeySpacing
        }

        val numberOfWhiteKeySpaces =
            whiteKeyBoundaryPositions.size - 1

        val averageWhiteKeySpacing =
            totalWhiteKeySpacing /
                    numberOfWhiteKeySpaces.toDouble()

        if (averageWhiteKeySpacing <= 0.0) {
            return 0.0
        }

        var totalPatternDifference = 0.0
        var blackKeyGapCount = 0

        for (
        candidateIndex in
        1 until sortedBlackKeyCandidates.size
        ) {
            val previousCandidate =
                sortedBlackKeyCandidates[candidateIndex - 1]

            val currentCandidate =
                sortedBlackKeyCandidates[candidateIndex]

            val previousCenter =
                previousCandidate.left.toDouble() +
                        (previousCandidate.width.toDouble() / 2.0)

            val currentCenter =
                currentCandidate.left.toDouble() +
                        (currentCandidate.width.toDouble() / 2.0)

            val centerDistance =
                currentCenter - previousCenter

            if (centerDistance <= 0.0) {
                return 0.0
            }

            val normalizedDistance =
                centerDistance /
                        averageWhiteKeySpacing

            val expectedDistance =
                if (normalizedDistance <= 1.45) {
                    1.0
                } else {
                    2.0
                }

            val patternDifference =
                abs(
                    normalizedDistance -
                            expectedDistance
                )

            totalPatternDifference +=
                patternDifference

            blackKeyGapCount++
        }

        if (blackKeyGapCount <= 0) {
            return 0.0
        }

        val averagePatternDifference =
            totalPatternDifference /
                    blackKeyGapCount.toDouble()

        val maximumAcceptedPatternDifference = 0.55

        val patternQuality =
            1.0 -
                    (
                            averagePatternDifference /
                                    maximumAcceptedPatternDifference
                            )

        if (patternQuality < 0.0) {
            return 0.0
        }

        if (patternQuality > 1.0) {
            return 1.0
        }

        return patternQuality
    }

    // Combines visible-key counts with measured white-spacing and black-pattern
// quality. No confidence is added automatically just for passing validation.
    private fun calculateKeyboardDetectionConfidence(
        blackKeyCandidates: List<BlackKeyCandidate>,
        whiteKeyBoundaryPositions: List<Double>,
        whiteKeySpacingQuality: Double,
        blackKeyPatternQuality: Double
    ): Double {
        val maximumUsefulBlackKeyCount = 8
        val maximumUsefulWhiteBoundaryCount = 10

        val countedBlackKeyCount =
            minOf(
                blackKeyCandidates.size,
                maximumUsefulBlackKeyCount
            )

        val countedWhiteBoundaryCount =
            minOf(
                whiteKeyBoundaryPositions.size,
                maximumUsefulWhiteBoundaryCount
            )

        val blackKeyCountEvidence =
            countedBlackKeyCount.toDouble() /
                    maximumUsefulBlackKeyCount.toDouble()

        val whiteBoundaryCountEvidence =
            countedWhiteBoundaryCount.toDouble() /
                    maximumUsefulWhiteBoundaryCount.toDouble()

        val blackKeyCountConfidence =
            blackKeyCountEvidence * 0.15

        val whiteBoundaryCountConfidence =
            whiteBoundaryCountEvidence * 0.15

        val whiteSpacingConfidence =
            whiteKeySpacingQuality * 0.35

        val blackPatternConfidence =
            blackKeyPatternQuality * 0.35

        val detectionConfidence =
            blackKeyCountConfidence +
                    whiteBoundaryCountConfidence +
                    whiteSpacingConfidence +
                    blackPatternConfidence

        if (detectionConfidence < 0.0) {
            return 0.0
        }

        if (detectionConfidence > 1.0) {
            return 1.0
        }

        return detectionConfidence
    }

    // Stops accepting new image-processing tasks.
    // Any camera image already being processed is allowed to finish safely.
    fun close() {
        processingExecutor.shutdown()
    }
}
