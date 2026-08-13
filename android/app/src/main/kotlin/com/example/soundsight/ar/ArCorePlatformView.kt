package com.example.soundsight.ar

import android.app.Activity
import android.content.Context
import android.opengl.GLSurfaceView
import android.os.Handler
import android.os.Looper
import android.view.View
import android.widget.FrameLayout
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.platform.PlatformView

// Contains the native camera surface and sends ARCore tracking updates to Dart.
class ArCorePlatformView(
    context: Context,
    activity: Activity,
    private val lifecycle: Lifecycle,
    viewId: Int,
    binaryMessenger: BinaryMessenger
) : PlatformView,
    DefaultLifecycleObserver,
    EventChannel.StreamHandler,
    ArCoreTrackingStatusListener {

    private val containerView: FrameLayout =
        FrameLayout(context)

    private val cameraSurfaceView: GLSurfaceView =
        GLSurfaceView(context)

    private val sessionManager: ArCoreSessionManager =
        ArCoreSessionManager(activity)

    private val cameraRenderer: ArCoreCameraRenderer =
        ArCoreCameraRenderer(
            sessionManager,
            activity,
            this
        )

    private val trackingEventChannel: EventChannel =
        EventChannel(
            binaryMessenger,
            "soundsight/arcore_tracking_$viewId"
        )

    private val mainHandler: Handler =
        Handler(Looper.getMainLooper())

    private var trackingEventSink: EventChannel.EventSink? = null

    private var latestTrackingStatus: ArCoreTrackingStatus =
        ArCoreTrackingStatus.INITIALIZING

    private var latestSessionResult: ArCoreSessionResult =
        ArCoreSessionResult.FAILED

    private var isCameraSurfacePaused: Boolean = false
    private var isViewActive: Boolean = false

    init {
        // Keeps the OpenGL context when SoundSight temporarily enters the
        // background. The camera texture and compiled shader program belong to
        // this context, so preserving it allows the visible camera preview to
        // continue after pressing Home and returning to calibration.
        // Android may still recreate the context when required; the renderer's
        // onSurfaceCreated method already rebuilds those graphics resources.
        cameraSurfaceView.setPreserveEGLContextOnPause(true)

        cameraSurfaceView.setEGLContextClientVersion(2)

        cameraSurfaceView.setRenderer(cameraRenderer)

        cameraSurfaceView.renderMode =
            GLSurfaceView.RENDERMODE_CONTINUOUSLY

        val surfaceLayoutParameters =
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )

        containerView.addView(
            cameraSurfaceView,
            surfaceLayoutParameters
        )

        trackingEventChannel.setStreamHandler(this)

        lifecycle.addObserver(this)
    }

    // Connects Dart to the tracking stream and immediately sends the most
    // recent status so the Flutter screen never starts with an unknown value.
    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?
    ) {
        trackingEventSink = events

        events?.success(
            latestTrackingStatus.name
        )
    }

    // Stops native events when Dart cancels its tracking subscription.
    override fun onCancel(arguments: Any?) {
        trackingEventSink = null
    }

    // Moves renderer updates from the OpenGL thread to Android's main thread
    // before sending them through Flutter's event channel.
    override fun onTrackingStatusChanged(
        status: ArCoreTrackingStatus
    ) {
        mainHandler.post {
            if (isViewActive) {
                updateTrackingStatus(status)
            }
        }
    }

    // Starts ARCore before allowing the OpenGL thread to request frames.
    override fun onResume(owner: LifecycleOwner) {
        latestSessionResult =
            sessionManager.createArCoreSession()

        if (latestSessionResult != ArCoreSessionResult.SUCCESS) {
            isViewActive = false
            pauseCameraSurface()

            updateTrackingStatus(
                getSessionTrackingStatus(
                    latestSessionResult
                )
            )

            return
        }

        latestSessionResult =
            sessionManager.resumeArCoreSession()

        if (latestSessionResult != ArCoreSessionResult.SUCCESS) {
            isViewActive = false
            pauseCameraSurface()

            updateTrackingStatus(
                getSessionTrackingStatus(
                    latestSessionResult
                )
            )

            return
        }

        isViewActive = true

        updateTrackingStatus(
            ArCoreTrackingStatus.INITIALIZING
        )

        resumeCameraSurface()
    }

    // Stops rendering before pausing ARCore and reports that tracking is unsafe.
    override fun onPause(owner: LifecycleOwner) {
        isViewActive = false
        pauseCameraSurface()

        val pauseResult =
            sessionManager.pauseArCoreSession()

        if (pauseResult != ArCoreSessionResult.SUCCESS) {
            latestSessionResult = pauseResult

            updateTrackingStatus(
                ArCoreTrackingStatus.FAILED
            )

            return
        }

        updateTrackingStatus(
            ArCoreTrackingStatus.PAUSED
        )
    }

    // Stops rendering and permanently releases ARCore with the activity.
    override fun onDestroy(owner: LifecycleOwner) {
        isViewActive = false
        pauseCameraSurface()

        val closeResult =
            sessionManager.closeArCoreSession()

        if (closeResult != ArCoreSessionResult.SUCCESS) {
            latestSessionResult = closeResult

            updateTrackingStatus(
                ArCoreTrackingStatus.FAILED
            )
        } else {
            updateTrackingStatus(
                ArCoreTrackingStatus.STOPPED
            )
        }

        lifecycle.removeObserver(this)
    }

    // Sends a new value only when the tracking state actually changes.
    private fun updateTrackingStatus(
        status: ArCoreTrackingStatus
    ) {
        if (status == latestTrackingStatus) {
            return
        }

        latestTrackingStatus = status

        trackingEventSink?.success(
            status.name
        )
    }

    // Converts session startup failures into the same statuses used for live
    // ARCore tracking so Dart needs only one status stream.
    private fun getSessionTrackingStatus(
        sessionResult: ArCoreSessionResult
    ): ArCoreTrackingStatus {
        return when (sessionResult) {
            ArCoreSessionResult.SUCCESS ->
                ArCoreTrackingStatus.INITIALIZING

            ArCoreSessionResult.INSTALL_REQUESTED,
            ArCoreSessionResult.ARCORE_NOT_INSTALLED,
            ArCoreSessionResult.ARCORE_UPDATE_REQUIRED,
            ArCoreSessionResult.SDK_UPDATE_REQUIRED,
            ArCoreSessionResult.INSTALL_DECLINED ->
                ArCoreTrackingStatus.INSTALL_REQUIRED

            ArCoreSessionResult.CAMERA_PERMISSION_MISSING ->
                ArCoreTrackingStatus.PERMISSION_MISSING

            ArCoreSessionResult.DEVICE_NOT_SUPPORTED ->
                ArCoreTrackingStatus.UNSUPPORTED

            ArCoreSessionResult.CAMERA_UNAVAILABLE ->
                ArCoreTrackingStatus.CAMERA_UNAVAILABLE

            ArCoreSessionResult.FAILED ->
                ArCoreTrackingStatus.FAILED
        }
    }

    private fun resumeCameraSurface() {
        if (isCameraSurfacePaused == false) {
            return
        }

        cameraSurfaceView.onResume()
        isCameraSurfacePaused = false
    }

    private fun pauseCameraSurface() {
        if (isCameraSurfacePaused) {
            return
        }

        cameraSurfaceView.onPause()
        isCameraSurfacePaused = true
    }

    override fun getView(): View {
        return containerView
    }

    // Releases the event channel, renderer, and ARCore session when Flutter
    // removes this platform view from the calibration screen.
    override fun dispose() {
        lifecycle.removeObserver(this)

        isViewActive = false
        pauseCameraSurface()

        latestSessionResult =
            sessionManager.closeArCoreSession()

        updateTrackingStatus(
            ArCoreTrackingStatus.STOPPED
        )

        trackingEventChannel.setStreamHandler(null)
        trackingEventSink = null

        containerView.removeAllViews()
    }
}
