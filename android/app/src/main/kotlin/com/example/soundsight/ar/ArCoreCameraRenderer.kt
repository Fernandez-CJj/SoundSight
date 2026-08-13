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

// Controls the OpenGL frame loop, draws camera frames, and reports whether
// ARCore tracking is reliable enough for future piano overlays.
class ArCoreCameraRenderer(
    private val sessionManager: ArCoreSessionManager,
    private val activity: Activity,
    private val trackingStatusListener: ArCoreTrackingStatusListener
) : GLSurfaceView.Renderer {
    private val backgroundRenderer: CameraBackgroundRenderer =
        CameraBackgroundRenderer()

    private var cameraTextureId: Int = -1
    private var isBackgroundRendererReady: Boolean = false

    private var surfaceWidth: Int = 0
    private var surfaceHeight: Int = 0
    private var lastDisplayRotation: Int = -1

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

    // Clears stale content, requests the newest ARCore frame, reports its
    // tracking state, and then draws the camera preview.
    override fun onDrawFrame(gl: GL10?) {
        GLES20.glClear(
            GLES20.GL_COLOR_BUFFER_BIT or
                GLES20.GL_DEPTH_BUFFER_BIT
        )

        if (
            isBackgroundRendererReady == false ||
            cameraTextureId < 0
        ) {
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

            return
        }

        if (frame.timestamp == 0L) {
            reportTrackingStatus(
                ArCoreTrackingStatus.INITIALIZING
            )

            return
        }

        val trackingStatus =
            getTrackingStatus(frame)

        reportTrackingStatus(trackingStatus)

        backgroundRenderer.updateCameraTextureCoordinates(
            frame
        )

        backgroundRenderer.draw(
            cameraTextureId
        )
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

    // Avoids sending the same tracking value on every rendered frame.
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
}
