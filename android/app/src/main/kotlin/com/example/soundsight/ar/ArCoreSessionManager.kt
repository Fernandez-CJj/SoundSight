package com.example.soundsight.ar

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import com.google.ar.core.ArCoreApk
import com.google.ar.core.Config
import com.google.ar.core.Session
import com.google.ar.core.exceptions.CameraNotAvailableException
import com.google.ar.core.exceptions.UnavailableApkTooOldException
import com.google.ar.core.exceptions.UnavailableArcoreNotInstalledException
import com.google.ar.core.exceptions.UnavailableDeviceNotCompatibleException
import com.google.ar.core.exceptions.UnavailableSdkTooOldException
import com.google.ar.core.exceptions.UnavailableUserDeclinedInstallationException
import com.google.ar.core.Frame

// Represents the result of creating or starting an ARCore session.
// Each failure has a separate result so Flutter can respond safely.
enum class ArCoreSessionResult {
    SUCCESS,
    INSTALL_REQUESTED,
    CAMERA_PERMISSION_MISSING,
    ARCORE_NOT_INSTALLED,
    ARCORE_UPDATE_REQUIRED,
    SDK_UPDATE_REQUIRED,
    DEVICE_NOT_SUPPORTED,
    INSTALL_DECLINED,
    CAMERA_UNAVAILABLE,
    FAILED
}

// Owns the ARCore session and controls its safe startup and cleanup.
class ArCoreSessionManager(
    private val activity: Activity
) {
    private var arCoreSession: Session? = null
    private var shouldRequestInstall: Boolean = true
    private var isSessionRunning: Boolean = false
    private var connectedCameraTextureId: Int = -1
    private var displayRotation: Int = 0
    private var displayWidth: Int = 0
    private var displayHeight: Int = 0
    private var isDisplayGeometryPending: Boolean = false

    // Confirms that Android still allows SoundSight to use the camera.
    // This protects ARCore if permission was revoked after Flutter checked it.
    private fun hasCameraPermission(): Boolean {
        val permissionResult =
            activity.checkSelfPermission(Manifest.permission.CAMERA)

        return permissionResult == PackageManager.PERMISSION_GRANTED
    }

    // Confirms that ARCore and its required device data are installed.
    // Converts installation problems into safe results instead of crashing.
    private fun checkArCoreInstallation(): ArCoreSessionResult {
        try {
            val arCoreApk = ArCoreApk.getInstance()

            val installStatus =
                arCoreApk.requestInstall(activity, shouldRequestInstall)

            if (installStatus == ArCoreApk.InstallStatus.INSTALL_REQUESTED) {
                shouldRequestInstall = false
                return ArCoreSessionResult.INSTALL_REQUESTED
            }

            return ArCoreSessionResult.SUCCESS
        } catch (exception: UnavailableArcoreNotInstalledException) {
            return ArCoreSessionResult.ARCORE_NOT_INSTALLED
        } catch (exception: UnavailableApkTooOldException) {
            return ArCoreSessionResult.ARCORE_UPDATE_REQUIRED
        } catch (exception: UnavailableSdkTooOldException) {
            return ArCoreSessionResult.SDK_UPDATE_REQUIRED
        } catch (exception: UnavailableDeviceNotCompatibleException) {
            return ArCoreSessionResult.DEVICE_NOT_SUPPORTED
        } catch (exception: UnavailableUserDeclinedInstallationException) {
            return ArCoreSessionResult.INSTALL_DECLINED
        } catch (exception: Exception) {
            return ArCoreSessionResult.FAILED
        }
    }

    // Creates one ARCore session only after permission and installation checks pass.
    // Every known startup failure is converted into a safe result.
    fun createArCoreSession(): ArCoreSessionResult {
        if (arCoreSession != null) {
            return ArCoreSessionResult.SUCCESS
        }

        if (hasCameraPermission() == false) {
            return ArCoreSessionResult.CAMERA_PERMISSION_MISSING
        }

        val installationResult = checkArCoreInstallation()

        if (installationResult != ArCoreSessionResult.SUCCESS) {
            return installationResult
        }

        try {
            arCoreSession = Session(activity)
            connectedCameraTextureId = -1

            isDisplayGeometryPending =
                displayWidth > 0 && displayHeight > 0

            val configurationResult = configureArCoreSession()

            return configurationResult
        } catch (exception: SecurityException) {
            return ArCoreSessionResult.CAMERA_PERMISSION_MISSING
        } catch (exception: UnavailableArcoreNotInstalledException) {
            return ArCoreSessionResult.ARCORE_NOT_INSTALLED
        } catch (exception: UnavailableApkTooOldException) {
            return ArCoreSessionResult.ARCORE_UPDATE_REQUIRED
        } catch (exception: UnavailableSdkTooOldException) {
            return ArCoreSessionResult.SDK_UPDATE_REQUIRED
        } catch (exception: UnavailableDeviceNotCompatibleException) {
            return ArCoreSessionResult.DEVICE_NOT_SUPPORTED
        } catch (exception: Exception) {
            return ArCoreSessionResult.FAILED
        }
    }

    // Configures the existing ARCore session to wait for each camera frame.
    // BLOCKING is kept because it prevents the frame loop from racing ahead of
    // ARCore during rapid Home and return lifecycle changes on the test phone.
    // A configuration failure closes the incomplete session safely.
    private fun configureArCoreSession(): ArCoreSessionResult {
        val session = arCoreSession

        if (session == null) {
            return ArCoreSessionResult.FAILED
        }

        try {
            val sessionConfig = Config(session)

            sessionConfig.updateMode =
                Config.UpdateMode.BLOCKING

            session.configure(sessionConfig)

            return ArCoreSessionResult.SUCCESS
        } catch (exception: Exception) {
            session.close()
            arCoreSession = null

            return ArCoreSessionResult.FAILED
        }
    }

    // Starts the configured ARCore session and opens the rear camera.
    // Repeated calls are ignored when the session is already running.
    fun resumeArCoreSession(): ArCoreSessionResult {
        val session = arCoreSession

        if (session == null) {
            return ArCoreSessionResult.FAILED
        }

        if (isSessionRunning) {
            return ArCoreSessionResult.SUCCESS
        }

        try {
            session.resume()
            isSessionRunning = true

            return ArCoreSessionResult.SUCCESS
        } catch (exception: CameraNotAvailableException) {
            isSessionRunning = false

            return ArCoreSessionResult.CAMERA_UNAVAILABLE
        } catch (exception: SecurityException) {
            isSessionRunning = false

            return ArCoreSessionResult.CAMERA_PERMISSION_MISSING
        } catch (exception: Exception) {
            isSessionRunning = false

            return ArCoreSessionResult.FAILED
        }
    }

    // Stores the latest OpenGL surface size and device rotation.
    // ARCore receives these values immediately before the next frame update.
    fun updateDisplayGeometry(
        newDisplayRotation: Int,
        newDisplayWidth: Int,
        newDisplayHeight: Int
    ) {
        if (
            newDisplayWidth <= 0 ||
            newDisplayHeight <= 0
        ) {
            return
        }

        displayRotation = newDisplayRotation
        displayWidth = newDisplayWidth
        displayHeight = newDisplayHeight
        isDisplayGeometryPending = true
    }

    // Forces ARCore to reconnect when OpenGL creates a new camera texture.
    // This is needed when Android destroys and recreates the OpenGL context.
    fun resetCameraTextureConnection() {
        connectedCameraTextureId = -1
    }

    // Applies pending display information, connects the camera texture,
    // and requests the newest available ARCore frame.
    fun updateArCoreFrame(cameraTextureId: Int): Frame? {
        if (cameraTextureId < 0) {
            return null
        }

        val session = arCoreSession

        if (session == null || isSessionRunning == false) {
            return null
        }

        try {
            if (isDisplayGeometryPending) {
                session.setDisplayGeometry(
                    displayRotation,
                    displayWidth,
                    displayHeight
                )

                isDisplayGeometryPending = false
            }

            if (connectedCameraTextureId != cameraTextureId) {
                session.setCameraTextureName(cameraTextureId)
                connectedCameraTextureId = cameraTextureId
            }

            return session.update()
        } catch (exception: Exception) {
            return null
        }
    }

    // Pauses camera and tracking while keeping the session available to resume.
    // Repeated calls are ignored when the session is already paused.
    fun pauseArCoreSession(): ArCoreSessionResult {
        val session = arCoreSession

        if (session == null) {
            isSessionRunning = false
            return ArCoreSessionResult.SUCCESS
        }

        if (isSessionRunning == false) {
            return ArCoreSessionResult.SUCCESS
        }

        try {
            session.pause()
            isSessionRunning = false

            return ArCoreSessionResult.SUCCESS
        } catch (exception: Exception) {
            return ArCoreSessionResult.FAILED
        }
    }

    // Permanently releases the ARCore session and all of its native resources.
    // A new session must be created before calibration can start again.
    fun closeArCoreSession(): ArCoreSessionResult {
        val session = arCoreSession

        if (session == null) {
            isSessionRunning = false
            shouldRequestInstall = true
            connectedCameraTextureId = -1

            return ArCoreSessionResult.SUCCESS
        }

        var closeResult = ArCoreSessionResult.SUCCESS

        if (isSessionRunning) {
            try {
                session.pause()
            } catch (exception: Exception) {
                closeResult = ArCoreSessionResult.FAILED
            }
        }

        try {
            session.close()
        } catch (exception: Exception) {
            closeResult = ArCoreSessionResult.FAILED
        }

        arCoreSession = null
        isSessionRunning = false
        shouldRequestInstall = true
        connectedCameraTextureId = -1

        return closeResult
    }
}
