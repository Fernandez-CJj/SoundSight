package com.example.soundsight

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.media.projection.MediaProjectionConfig
import android.media.projection.MediaProjectionManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** Permission UI stays in the Activity; capture resources belong to the service. */
class PerformanceRecordingBridge(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "soundsight/performance_recording")
    private var attempt: String? = null
    private var startResult: MethodChannel.Result? = null
    private var stopResult: MethodChannel.Result? = null
    private var resumed = false
    private var launched = false
    private var canceled = false
    private var grant: Pair<Int, Intent>? = null
    private var permissionInFlight = false

    companion object { const val MICROPHONE = 8310; const val CAPTURE = 8311 }

    init {
        PerformanceRecordingService.listener = ::onEvent
        channel.setMethodCallHandler { call, result ->
            val id = call.argument<String>("attemptId")
            when (call.method) {
                "cleanupOrphans" -> {
                    val active = PerformanceRecordingService.current?.activeAttemptId ?: attempt
                    Thread {
                        runCatching { RecordingStorage(PerformanceRecordingService.root(activity)).cleanup(active) }
                        activity.runOnUiThread { result.success(null) }
                    }.start()
                }
                "start" -> {
                    if (id == null || !PerformanceRecordingService.validId(id) || startResult != null || launched || permissionInFlight) {
                        result.error("busy", "Capture is already starting or active.", null)
                    } else {
                        attempt = id; startResult = result; canceled = false
                        if (activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED) requestCapture()
                        else {
                            permissionInFlight = true
                            try {
                                activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), MICROPHONE)
                            } catch (_: Exception) {
                                permissionInFlight = false
                                completeStart("unavailable")
                            }
                        }
                    }
                }
                "finish", "discard" -> {
                    if (stopResult != null) {
                        result.error("busy", "Capture is already stopping.", null)
                    } else if (id != attempt || !launched) {
                        if (id == attempt) cancelPending()
                        if (id != null && PerformanceRecordingService.validId(id))
                            runCatching { PerformanceRecordingService.deleteAttempt(activity, id) }
                        result.success(null)
                    } else {
                        stopResult = result
                        canceled = call.method == "discard"
                        PerformanceRecordingService.current?.finish(!canceled)
                        // If service creation is pending, onEvent performs the stop.
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestCapture() {
        if (canceled || startResult == null) return
        try {
            permissionInFlight = true
            val manager = activity.getSystemService(MediaProjectionManager::class.java)
            // Capture this display without asking the player to select another
            // app. Android's recording-consent dialog is still required.
            val request = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                manager.createScreenCaptureIntent(MediaProjectionConfig.createConfigForDefaultDisplay())
            } else {
                manager.createScreenCaptureIntent()
            }
            activity.startActivityForResult(request, CAPTURE)
        } catch (_: Exception) { permissionInFlight = false; completeStart("unavailable") }
    }

    fun onRequestPermissionsResult(code: Int, results: IntArray): Boolean {
        if (code != MICROPHONE) return false
        permissionInFlight = false
        if (!canceled && startResult != null) {
            if (results.firstOrNull() == PackageManager.PERMISSION_GRANTED) requestCapture()
            else completeStart("declined")
        }
        return true
    }

    fun onActivityResult(code: Int, resultCode: Int, data: Intent?): Boolean {
        if (code != CAPTURE) return false
        permissionInFlight = false
        if (canceled || startResult == null) return true
        if (resultCode != Activity.RESULT_OK || data == null) completeStart("declined")
        else { grant = resultCode to data; launchIfReady() }
        return true
    }

    fun onResume() { resumed = true; launchIfReady() }
    fun onPause() { resumed = false }
    fun onStop() {
        if (launched) {
            canceled = true
            PerformanceRecordingService.current?.finish(false, "interrupted")
        }
    }

    private fun launchIfReady() {
        val permission = grant ?: return
        if (!resumed || canceled || startResult == null) return
        grant = null
        val intent = Intent(activity, PerformanceRecordingService::class.java)
            .putExtra("attemptId", attempt).putExtra("resultCode", permission.first).putExtra("permission", permission.second)
        try {
            launched = true
            channel.invokeMethod("status", mapOf("attemptId" to attempt, "state" to "starting"))
            if (Build.VERSION.SDK_INT >= 26) activity.startForegroundService(intent) else activity.startService(intent)
        } catch (_: Exception) { launched = false; completeStart("unavailable") }
    }

    private fun completeStart(state: String) {
        startResult?.success(mapOf("state" to state))
        startResult = null
    }

    private fun onEvent(event: Map<String, Any?>) {
        if (event["attemptId"] != attempt) return
        val state = event["state"] as String
        if (state == "recording") {
            if (canceled || stopResult != null) PerformanceRecordingService.current?.finish(!canceled)
            completeStart(if (canceled) "unavailable" else "recording")
        } else {
            launched = false
            completeStart("unavailable")
            stopResult?.success(event["path"])
            stopResult = null
        }
        channel.invokeMethod("status", event)
    }

    private fun cancelPending() {
        canceled = true; grant = null
        completeStart("declined")
    }

    fun dispose() {
        cancelPending()
        PerformanceRecordingService.current?.finish(false, "interrupted")
        PerformanceRecordingService.listener = null
        channel.setMethodCallHandler(null)
        stopResult?.success(null); stopResult = null
    }
}
