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
import com.example.soundsight.vision.OpenCvManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.example.soundsight.vision.KeyboardDetectionResult

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
    ArCoreTrackingStatusListener,
    KeyboardDetectionResultListener {

    private val containerView: FrameLayout =
        FrameLayout(context)

    private val cameraSurfaceView: GLSurfaceView =
        GLSurfaceView(context)

    private val sessionManager: ArCoreSessionManager =
        ArCoreSessionManager(activity)

    // Loads OpenCV and stores whether its image-processing tools are ready.
    private val openCvManager: OpenCvManager =
        OpenCvManager()

    private val cameraRenderer: ArCoreCameraRenderer =
        ArCoreCameraRenderer(
            sessionManager,
            activity,
            openCvManager,
            this,
            this
        )
    private val trackingEventChannel: EventChannel =
        EventChannel(
            binaryMessenger,
            "soundsight/arcore_tracking_$viewId"
        )

    // Manages Dart's listener for keyboard-detection results.
    private val keyboardDetectionStreamHandler =
        KeyboardDetectionStreamHandler()

    // Creates a separate event channel for continuous keyboard-detection results.
    // The view ID connects this channel to the correct native camera view.
    private val keyboardDetectionEventChannel: EventChannel =
        EventChannel(
            binaryMessenger,
            "soundsight/keyboard_detection_$viewId"
        )

    // Receives one-time commands from this Flutter camera widget.
    // The view ID keeps commands connected to the correct native camera view.
    private val cameraCommandChannel: MethodChannel =
        MethodChannel(
            binaryMessenger,
            "soundsight/arcore_commands_$viewId"
        )

    private val mainHandler: Handler =
        Handler(Looper.getMainLooper())

    private var trackingEventSink: EventChannel.EventSink? = null

    private var latestTrackingStatus: ArCoreTrackingStatus =
        ArCoreTrackingStatus.INITIALIZING

    // Stores the newest OpenCV result received from the renderer.
    // Null means no camera image has produced a detection result yet.
    private var latestKeyboardDetectionResult: KeyboardDetectionResult? = null

    private var latestSessionResult: ArCoreSessionResult =
        ArCoreSessionResult.FAILED

    private var isCameraSurfacePaused: Boolean = false
    private var isViewActive: Boolean = false

    init {
        // Loads OpenCV when the calibration camera view is created.
        // The manager stores true when loading succeeds and false when it fails.
        openCvManager.loadOpenCv()

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

        keyboardDetectionEventChannel.setStreamHandler(
            keyboardDetectionStreamHandler
        )

        cameraCommandChannel.setMethodCallHandler(
            ::handleCameraCommand
        )

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

    // Receives scanning commands from Flutter and checks native safety conditions
    // before allowing camera images to enter the OpenCV processing pipeline.
    private fun handleCameraCommand(
        call: MethodCall,
        result: MethodChannel.Result
    ) {
        if (call.method == "startKeyboardScan") {
            if (isViewActive == false) {
                result.error(
                    "AR_VIEW_INACTIVE",
                    "The AR camera view is not active.",
                    null
                )
                return
            }

            if (latestTrackingStatus != ArCoreTrackingStatus.TRACKING) {
                result.error(
                    "TRACKING_UNRELIABLE",
                    "ARCore tracking is not reliable.",
                    null
                )
                return
            }

            if (openCvManager.isOpenCvLoaded() == false) {
                result.error(
                    "OPENCV_UNAVAILABLE",
                    "OpenCV is not available.",
                    null
                )
                return
            }

            cameraRenderer.startKeyboardScanning()
            result.success(null)
        } else if (call.method == "stopKeyboardScan") {
            cameraRenderer.stopKeyboardScanning()
            result.success(null)
        } else {
            result.notImplemented()
        }
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

    // Moves keyboard-detection results from the background processing thread to
    // Android's main thread, converts them, and sends them to Dart.
    override fun onKeyboardDetectionResultChanged(
        keyboardDetectionResult: KeyboardDetectionResult
    ) {
        mainHandler.post {
            if (isViewActive) {
                latestKeyboardDetectionResult =
                    keyboardDetectionResult

                val keyboardDetectionData =
                    keyboardDetectionResult.createFlutterData()

                keyboardDetectionStreamHandler.sendKeyboardDetectionResult(
                    keyboardDetectionData
                )
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
        cameraRenderer.close()

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

        // Disconnects Flutter commands from this camera view before its ARCore
        // session, renderer, and Android views are permanently released.
        cameraCommandChannel.setMethodCallHandler(null)

        isViewActive = false
        pauseCameraSurface()
        cameraRenderer.close()

        latestSessionResult =
            sessionManager.closeArCoreSession()

        updateTrackingStatus(
            ArCoreTrackingStatus.STOPPED
        )

        trackingEventChannel.setStreamHandler(null)
        trackingEventSink = null
        keyboardDetectionEventChannel.setStreamHandler(null)
        keyboardDetectionStreamHandler.close()

        containerView.removeAllViews()
    }
}
