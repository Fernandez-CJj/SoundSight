package com.example.soundsight

import android.app.Activity
import android.content.Intent
import java.io.File
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val saveVideoRequest = 8301
    private var pendingVideo: File? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "soundsight/recorded_video")
            .setMethodCallHandler { call, result ->
                if (call.method != "saveVideo") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (pendingResult != null) {
                    result.error("busy", "A video save is already open.", null)
                    return@setMethodCallHandler
                }
                val path = call.argument<String>("path")
                val name = call.argument<String>("name")
                val source = path?.let(::File)
                if (source == null || !source.isFile || source.length() == 0L || name.isNullOrBlank()) {
                    result.error("missing_video", "The recording is unavailable.", null)
                    return@setMethodCallHandler
                }
                pendingVideo = source
                pendingResult = result
                val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "video/mp4"
                    putExtra(Intent.EXTRA_TITLE, name)
                }
                try {
                    startActivityForResult(intent, saveVideoRequest)
                } catch (error: Exception) {
                    pendingVideo = null
                    pendingResult = null
                    result.error("save_unavailable", error.message, null)
                }
            }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != saveVideoRequest) return
        val result = pendingResult ?: return
        val source = pendingVideo
        pendingResult = null
        pendingVideo = null
        val destination = data?.data
        if (resultCode != Activity.RESULT_OK || destination == null || source == null) {
            result.success(false)
            return
        }
        Thread {
            try {
                val output = contentResolver.openOutputStream(destination, "w")
                    ?: throw IllegalStateException("The selected location cannot be written.")
                source.inputStream().use { input ->
                    output.use { input.copyTo(it, 64 * 1024) }
                }
                runOnUiThread { result.success(true) }
            } catch (error: Exception) {
                try {
                    contentResolver.delete(destination, null, null)
                } catch (_: Exception) { }
                runOnUiThread { result.error("save_failed", error.message, null) }
            }
        }.start()
    }
}
