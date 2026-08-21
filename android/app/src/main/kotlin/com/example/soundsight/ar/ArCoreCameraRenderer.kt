package com.example.soundsight.ar

import android.app.Activity
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.opengl.GLSurfaceView
import android.os.Build
import com.google.ar.core.Frame
import com.google.ar.core.TrackingFailureReason
import com.google.ar.core.TrackingState
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10
import com.example.soundsight.vision.ArCoreCameraImageReader
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import com.example.soundsight.vision.KeyboardImageProcessor
import com.example.soundsight.vision.OpenCvManager
import com.example.soundsight.vision.KeyboardDetectionResult
import com.example.soundsight.vision.KeyboardDetectionStatus
import com.example.soundsight.vision.ImagePoint
import com.example.soundsight.vision.KeyboardRegion
import kotlin.math.sqrt

// Lists every tracking condition that the native AR view can report to Dart.
// Only TRACKING means that ARCore's camera pose is currently reliable.
enum class ArCoreTrackingStatus {
    INITIALIZING,
    TRACKING,
    PAUSED,
    STOPPED,
    INSUFFICIENT_LIGHT,
    EXCESSIVE_MOTION,
    INSUFFICIENT_FEATURES,
    CAMERA_UNAVAILABLE,
    BAD_STATE,
    INSTALL_REQUIRED,
    PERMISSION_MISSING,
    UNSUPPORTED,
    FAILED
}

// Allows the OpenGL renderer to report tracking changes without depending
// directly on Flutter's platform-channel classes.
interface ArCoreTrackingStatusListener {
    fun onTrackingStatusChanged(
        status: ArCoreTrackingStatus
    )
}

// Allows the OpenGL renderer to deliver completed keyboard-detection results
// without depending directly on Flutter's platform-channel classes.
interface KeyboardDetectionResultListener {
    fun onKeyboardDetectionResultChanged(
        keyboardDetectionResult: KeyboardDetectionResult
    )
}

// Controls the OpenGL frame loop, draws camera frames, and reports whether
// ARCore tracking is reliable enough for future piano overlays.
class ArCoreCameraRenderer(
    private val sessionManager: ArCoreSessionManager,
    private val activity: Activity,
    private val openCvManager: OpenCvManager,
    private val trackingStatusListener: ArCoreTrackingStatusListener,
    private val keyboardDetectionResultListener: KeyboardDetectionResultListener
) : GLSurfaceView.Renderer {
    private val backgroundRenderer: CameraBackgroundRenderer =
        CameraBackgroundRenderer()

    // Owns the reader that copies CPU-readable grayscale images from ARCore frames.
    private val cameraImageReader: ArCoreCameraImageReader =
        ArCoreCameraImageReader()

    // Owns the background worker that prepares accepted camera images for OpenCV.
    private val keyboardImageProcessor: KeyboardImageProcessor =
        KeyboardImageProcessor(openCvManager)

    // Stores the most recent keyboard-detection result produced by OpenCV.
    // The result includes its status, detected region, timestamp, and confidence.
    // Volatile makes the latest value visible to both the background processing
    // thread and the OpenGL rendering thread.
    @Volatile
    private var latestKeyboardDetectionResult: KeyboardDetectionResult? = null

    // Remembers whether a camera image is currently being processed.
    // AtomicBoolean keeps this value safe because the camera renderer and the
    // image-processing worker will run on different threads.
    private val cameraImageBeingProcessed: AtomicBoolean =
        AtomicBoolean(false)

    // Remembers whether the user has started keyboard scanning.
    // Camera frames are not sent to OpenCV while this value is false.
    private val keyboardScanningActive: AtomicBoolean =
        AtomicBoolean(false)

    // Counts consecutive processed frames that contain a reliable keyboard result.
    // AtomicInteger keeps resets and updates safe across the renderer and worker.
    private val consecutiveReliableDetectionCount: AtomicInteger =
        AtomicInteger(0)

    // Requires several successful frames before keyboard geometry can be reported.
    private val requiredConsecutiveReliableDetections: Int = 3

    // Stores the first reliable region in the current stability sequence.
    // Later regions must remain close to this reference before being trusted.
    @Volatile
    private var stabilityReferenceKeyboardRegion: KeyboardRegion? = null

    // Allows small camera and detection jitter while rejecting a keyboard region
    // whose corners suddenly move more than three percent of the image diagonal.
    private val maximumStableCornerMovementRatio: Double = 0.03

    // Allows the last visible camera texture to stay on screen during a short
    // missing-frame interruption. After 500 milliseconds the surface becomes
    // black instead of making an old camera image appear live indefinitely.
    private val maximumPreviousCameraFrameDisplayTimeNanoseconds: Long =
        500_000_000L

    // Remembers whether this OpenGL surface has drawn a valid camera frame.
    // A frame from an older OpenGL surface is never reused.
    private var validCameraFrameHasBeenDrawn: Boolean = false

    // Stores when the most recent valid camera frame was drawn. This controls
    // only the visible preview and never makes old tracking data trustworthy.
    private var lastValidCameraFrameDrawTimeNanoseconds: Long = 0L

    private var cameraTextureId: Int = -1
    private var isBackgroundRendererReady: Boolean = false

    private var surfaceWidth: Int = 0
    private var surfaceHeight: Int = 0
    private var lastDisplayRotation: Int = -1

    // Stores the newest ARCore tracking status. Volatile makes tracking changes
    // visible to the background image-processing callback immediately.
    @Volatile
    private var lastTrackingStatus: ArCoreTrackingStatus? = null

    // Creates the external camera texture and prepares the camera shaders.
    override fun onSurfaceCreated(
        gl: GL10?,
        config: EGLConfig?
    ) {
        GLES20.glClearColor(
            0.0f,
            0.0f,
            0.0f,
            1.0f
        )

        cameraTextureId = -1
        isBackgroundRendererReady = false
        lastTrackingStatus = null
        validCameraFrameHasBeenDrawn = false
        lastValidCameraFrameDrawTimeNanoseconds = 0L

        reportTrackingStatus(
            ArCoreTrackingStatus.INITIALIZING
        )

        if (createCameraTextureOnGlThread() == false) {
            reportTrackingStatus(
                ArCoreTrackingStatus.FAILED
            )

            return
        }

        isBackgroundRendererReady =
            backgroundRenderer.createOnGlThread()

        if (isBackgroundRendererReady == false) {
            reportTrackingStatus(
                ArCoreTrackingStatus.FAILED
            )
        }
    }

    // Stores the surface size so ARCore can match camera frames to the display.
    override fun onSurfaceChanged(
        gl: GL10?,
        width: Int,
        height: Int
    ) {
        surfaceWidth = width
        surfaceHeight = height
        lastDisplayRotation = -1

        GLES20.glViewport(
            0,
            0,
            width,
            height
        )

        updateDisplayGeometryIfNeeded()
    }

    // Requests and validates the newest ARCore frame before replacing the
    // visible camera image. A short missing-frame interruption keeps only the
    // previous visual texture while tracking and keyboard geometry stay unsafe.
    override fun onDrawFrame(gl: GL10?) {
        if (
            isBackgroundRendererReady == false ||
            cameraTextureId < 0
        ) {
            clearCameraSurface()
            return
        }

        updateDisplayGeometryIfNeeded()

        val frame =
            sessionManager.updateArCoreFrame(
                cameraTextureId
            )

        if (frame == null) {
            reportTrackingStatus(
                ArCoreTrackingStatus.PAUSED
            )

            drawPreviousCameraFrameOrClearSurface()
            return
        }

        if (frame.timestamp == 0L) {
            reportTrackingStatus(
                ArCoreTrackingStatus.INITIALIZING
            )

            drawPreviousCameraFrameOrClearSurface()
            return
        }

        // The new frame is valid, so it can safely replace the previous image.
        clearCameraSurface()

        val trackingStatus =
            getTrackingStatus(frame)

        reportTrackingStatus(trackingStatus)

        // Camera images are accepted only while ARCore has a reliable pose.
        // Unreliable frames are still displayed, but they are not sent to OpenCV.
        if (
            trackingStatus == ArCoreTrackingStatus.TRACKING &&
            keyboardScanningActive.get()
        ) {
            tryProcessCameraImage(frame)
        }

        backgroundRenderer.updateCameraTextureCoordinates(
            frame
        )

        backgroundRenderer.draw(
            cameraTextureId
        )

        validCameraFrameHasBeenDrawn = true
        lastValidCameraFrameDrawTimeNanoseconds =
            System.nanoTime()
    }

    // Clears the visible camera color and depth information. This is used before
    // a valid camera draw and when no recent camera frame can remain visible.
    private fun clearCameraSurface() {
        GLES20.glClear(
            GLES20.GL_COLOR_BUFFER_BIT or
                    GLES20.GL_DEPTH_BUFFER_BIT
        )
    }

    // Draws the last camera texture only while it is less than 500 milliseconds
    // old. Tracking is already unreliable before this method runs, so retaining
    // the camera picture cannot keep an old keyboard crosshair visible.
    private fun drawPreviousCameraFrameOrClearSurface() {
        if (validCameraFrameHasBeenDrawn == false) {
            clearCameraSurface()
            return
        }

        val currentTimeNanoseconds =
            System.nanoTime()

        val previousFrameAgeNanoseconds =
            currentTimeNanoseconds -
                    lastValidCameraFrameDrawTimeNanoseconds

        val previousFrameIsRecent =
            previousFrameAgeNanoseconds >= 0L &&
                    previousFrameAgeNanoseconds <=
                    maximumPreviousCameraFrameDisplayTimeNanoseconds

        if (previousFrameIsRecent == false) {
            clearCameraSurface()
            return
        }

        // The full-screen camera rectangle replaces all color pixels. Only the
        // depth buffer needs clearing before drawing the retained texture.
        GLES20.glClear(
            GLES20.GL_DEPTH_BUFFER_BIT
        )

        backgroundRenderer.draw(
            cameraTextureId
        )
    }

    // Attempts to copy and process the current ARCore camera image.
    // Frames are skipped while the previous image is still being processed.
    private fun tryProcessCameraImage(
        frame: Frame
    ) {
        val processingStarted =
            tryStartCameraImageProcessing()

        if (processingStarted == false) {
            return
        }

        val cameraImageData =
            cameraImageReader.readCameraImage(frame)

        if (cameraImageData == null) {
            finishCameraImageProcessing()
            return
        }

        keyboardImageProcessor.processCameraImage(
            cameraImageData,
            ::handleKeyboardDetectionResult,
            ::finishCameraImageProcessing
        )
    }

    // Receives one completed background result and requires several consecutive
    // spatially stable detections before sending keyboard geometry to Flutter.
    private fun handleKeyboardDetectionResult(
        keyboardDetectionResult: KeyboardDetectionResult
    ) {
        if (
            keyboardScanningActive.get() == false ||
            lastTrackingStatus != ArCoreTrackingStatus.TRACKING
        ) {
            consecutiveReliableDetectionCount.set(0)
            stabilityReferenceKeyboardRegion = null
            return
        }

        val currentKeyboardRegion =
            keyboardDetectionResult.keyboardRegion

        if (
            keyboardDetectionResult.status !=
            KeyboardDetectionStatus.KEYBOARD_DETECTED ||
            currentKeyboardRegion == null
        ) {
            consecutiveReliableDetectionCount.set(0)
            stabilityReferenceKeyboardRegion = null

            reportKeyboardDetectionResult(
                keyboardDetectionResult
            )

            return
        }

        val referenceKeyboardRegion =
            stabilityReferenceKeyboardRegion

        if (referenceKeyboardRegion == null) {
            stabilityReferenceKeyboardRegion =
                currentKeyboardRegion

            consecutiveReliableDetectionCount.set(0)
        } else {
            val regionsAreStable =
                keyboardRegionsAreSpatiallyStable(
                    referenceKeyboardRegion,
                    currentKeyboardRegion
                )

            if (regionsAreStable == false) {
                stabilityReferenceKeyboardRegion =
                    currentKeyboardRegion

                consecutiveReliableDetectionCount.set(0)
            }
        }

        val reliableDetectionCount =
            consecutiveReliableDetectionCount.incrementAndGet()

        if (
            reliableDetectionCount <
            requiredConsecutiveReliableDetections
        ) {
            val stabilizingResult =
                KeyboardDetectionResult(
                    status = KeyboardDetectionStatus.SEARCHING,
                    keyboardRegion = null,
                    blackKeyCandidates =
                        keyboardDetectionResult.blackKeyCandidates,
                    whiteKeyBoundaryPositions =
                        keyboardDetectionResult.whiteKeyBoundaryPositions,
                    timestamp = keyboardDetectionResult.timestamp,
                    confidence = keyboardDetectionResult.confidence
                )

            reportKeyboardDetectionResult(
                stabilizingResult
            )

            return
        }

        consecutiveReliableDetectionCount.set(
            requiredConsecutiveReliableDetections
        )

        reportKeyboardDetectionResult(
            keyboardDetectionResult
        )
    }

    // Stores one result and sends it to the platform view for delivery to Flutter.
    private fun reportKeyboardDetectionResult(
        keyboardDetectionResult: KeyboardDetectionResult
    ) {
        latestKeyboardDetectionResult =
            keyboardDetectionResult

        keyboardDetectionResultListener.onKeyboardDetectionResultChanged(
            keyboardDetectionResult
        )
    }

    // Measures the straight-line pixel distance between the same corner in two
    // consecutive keyboard regions.
    private fun calculateImagePointDistance(
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

    // Checks whether all four current corners remain close to their matching
    // corners from the previous reliable frame.
    private fun keyboardRegionsAreSpatiallyStable(
        previousRegion: KeyboardRegion,
        currentRegion: KeyboardRegion
    ): Boolean {
        if (
            previousRegion.imageWidth != currentRegion.imageWidth ||
            previousRegion.imageHeight != currentRegion.imageHeight
        ) {
            return false
        }

        val imageWidth =
            currentRegion.imageWidth.toDouble()

        val imageHeight =
            currentRegion.imageHeight.toDouble()

        if (imageWidth <= 0.0 || imageHeight <= 0.0) {
            return false
        }

        val imageDiagonal =
            sqrt(
                (imageWidth * imageWidth) +
                        (imageHeight * imageHeight)
            )

        if (imageDiagonal <= 0.0) {
            return false
        }

        val topLeftMovement =
            calculateImagePointDistance(
                previousRegion.topLeft,
                currentRegion.topLeft
            )

        val topRightMovement =
            calculateImagePointDistance(
                previousRegion.topRight,
                currentRegion.topRight
            )

        val bottomRightMovement =
            calculateImagePointDistance(
                previousRegion.bottomRight,
                currentRegion.bottomRight
            )

        val bottomLeftMovement =
            calculateImagePointDistance(
                previousRegion.bottomLeft,
                currentRegion.bottomLeft
            )

        val maximumCornerMovement =
            maxOf(
                topLeftMovement,
                topRightMovement,
                bottomRightMovement,
                bottomLeftMovement
            )

        val cornerMovementRatio =
            maximumCornerMovement / imageDiagonal

        return cornerMovementRatio <=
                maximumStableCornerMovementRatio
    }

    // Creates the external texture that receives ARCore camera frames.
    // This method runs only when OpenGL creates a surface, so the texture belongs
    // to the same graphics context that will draw the camera background.
    private fun createCameraTextureOnGlThread(): Boolean {
        val generatedTextureIds = IntArray(1)

        GLES20.glGenTextures(
            1,
            generatedTextureIds,
            0
        )

        val newCameraTextureId = generatedTextureIds[0]

        if (newCameraTextureId == 0) {
            cameraTextureId = -1
            return false
        }

        GLES20.glBindTexture(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            newCameraTextureId
        )

        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_MIN_FILTER,
            GLES20.GL_LINEAR
        )

        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_MAG_FILTER,
            GLES20.GL_LINEAR
        )

        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_WRAP_S,
            GLES20.GL_CLAMP_TO_EDGE
        )

        GLES20.glTexParameteri(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            GLES20.GL_TEXTURE_WRAP_T,
            GLES20.GL_CLAMP_TO_EDGE
        )

        GLES20.glBindTexture(
            GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
            0
        )

        cameraTextureId = newCameraTextureId

        // ARCore must receive the newly generated ID before its next update.
        sessionManager.resetCameraTextureConnection()

        return true
    }

    // Converts ARCore's tracking state and failure reason into one status that
    // Dart can use to show instructions and hide unsafe overlays.
    private fun getTrackingStatus(
        frame: Frame
    ): ArCoreTrackingStatus {
        val camera = frame.camera

        if (camera.trackingState == TrackingState.TRACKING) {
            return ArCoreTrackingStatus.TRACKING
        }

        if (camera.trackingState == TrackingState.STOPPED) {
            return ArCoreTrackingStatus.STOPPED
        }

        return when (camera.trackingFailureReason) {
            TrackingFailureReason.NONE ->
                ArCoreTrackingStatus.INITIALIZING

            TrackingFailureReason.INSUFFICIENT_LIGHT ->
                ArCoreTrackingStatus.INSUFFICIENT_LIGHT

            TrackingFailureReason.EXCESSIVE_MOTION ->
                ArCoreTrackingStatus.EXCESSIVE_MOTION

            TrackingFailureReason.INSUFFICIENT_FEATURES ->
                ArCoreTrackingStatus.INSUFFICIENT_FEATURES

            TrackingFailureReason.CAMERA_UNAVAILABLE ->
                ArCoreTrackingStatus.CAMERA_UNAVAILABLE

            TrackingFailureReason.BAD_STATE ->
                ArCoreTrackingStatus.BAD_STATE
        }
    }

    // Sends tracking changes and immediately removes keyboard geometry whenever
    // ARCore can no longer provide a reliable camera pose.
    private fun reportTrackingStatus(
        status: ArCoreTrackingStatus
    ) {
        if (status == lastTrackingStatus) {
            return
        }

        lastTrackingStatus = status

        trackingStatusListener.onTrackingStatusChanged(
            status
        )

        if (
            status != ArCoreTrackingStatus.TRACKING &&
            keyboardScanningActive.get()
        ) {
            consecutiveReliableDetectionCount.set(0)
            stabilityReferenceKeyboardRegion = null
            val searchingResult =
                KeyboardDetectionResult(
                    status = KeyboardDetectionStatus.SEARCHING,
                    keyboardRegion = null,
                    blackKeyCandidates = emptyList(),
                    whiteKeyBoundaryPositions = emptyList(),
                    timestamp = 0L,
                    confidence = 0.0
                )

            reportKeyboardDetectionResult(
                searchingResult
            )
        }
    }

    // Reserves the image-processing worker for one camera image.
    // Returns true only when no other image is currently being processed.
    private fun tryStartCameraImageProcessing(): Boolean {
        return cameraImageBeingProcessed.compareAndSet(
            false,
            true
        )
    }

    // Enables keyboard image processing and immediately reports that the scanner
    // is searching for a reliable visible keyboard section.
    fun startKeyboardScanning() {
        if (keyboardScanningActive.get()) {
            return
        }

        consecutiveReliableDetectionCount.set(0)
        stabilityReferenceKeyboardRegion = null
        keyboardScanningActive.set(true)

        val searchingResult =
            KeyboardDetectionResult(
                status = KeyboardDetectionStatus.SEARCHING,
                keyboardRegion = null,
                blackKeyCandidates = emptyList(),
                whiteKeyBoundaryPositions = emptyList(),
                timestamp = 0L,
                confidence = 0.0
            )

        reportKeyboardDetectionResult(
            searchingResult
        )
    }

    // Stops new camera frames, removes the latest detected geometry, and reports
    // that keyboard scanning is no longer active.
    fun stopKeyboardScanning() {
        if (keyboardScanningActive.get() == false) {
            return
        }

        keyboardScanningActive.set(false)
        consecutiveReliableDetectionCount.set(0)
        stabilityReferenceKeyboardRegion = null

        val notStartedResult =
            KeyboardDetectionResult(
                status = KeyboardDetectionStatus.NOT_STARTED,
                keyboardRegion = null,
                blackKeyCandidates = emptyList(),
                whiteKeyBoundaryPositions = emptyList(),
                timestamp = 0L,
                confidence = 0.0
            )

        reportKeyboardDetectionResult(
            notStartedResult
        )
    }

    // Marks image processing as finished so a newer camera frame can be accepted.
    private fun finishCameraImageProcessing() {
        cameraImageBeingProcessed.set(false)
    }

    // Updates ARCore whenever the surface size or device rotation changes.
    private fun updateDisplayGeometryIfNeeded() {
        if (surfaceWidth <= 0 || surfaceHeight <= 0) {
            return
        }

        val currentDisplayRotation =
            getDisplayRotation()

        if (currentDisplayRotation == lastDisplayRotation) {
            return
        }

        lastDisplayRotation = currentDisplayRotation

        sessionManager.updateDisplayGeometry(
            currentDisplayRotation,
            surfaceWidth,
            surfaceHeight
        )
    }

    // Reads display rotation on both current and older supported Android APIs.
    @Suppress("DEPRECATION")
    private fun getDisplayRotation(): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val currentDisplay = activity.display

            if (currentDisplay != null) {
                return currentDisplay.rotation
            }
        }

        return activity.windowManager.defaultDisplay.rotation
    }

    // Stops keyboard scanning and releases its background worker when the
    // calibration camera is permanently closed.
    fun close() {
        stopKeyboardScanning()
        keyboardImageProcessor.close()
    }
}
