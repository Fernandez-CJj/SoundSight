package com.example.soundsight

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.*
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.*
import android.view.Surface
import java.io.File

/** Owns capture independently of Flutter widgets. All media operations are serialized. */
class PerformanceRecordingService : Service() {
    private val workerThread = HandlerThread("performance-capture")
    private lateinit var worker: Handler
    private val main = Handler(Looper.getMainLooper())
    private var projection: MediaProjection? = null
    private var display: VirtualDisplay? = null
    private var recorder: MediaRecorder? = null
    private var inputSurface: Surface? = null
    private var recording = false
    private var attempt: String? = null
    val activeAttemptId: String? get() = attempt
    private var output: File? = null
    @Volatile private var closing = false

    companion object {
        const val STOP = "soundsight.stop_performance_recording"
        const val CHANNEL = "performance_recording"
        const val NOTIFICATION = 8302
        @Volatile var current: PerformanceRecordingService? = null
        var listener: ((Map<String, Any?>) -> Unit)? = null
        fun root(context: android.content.Context) = File(context.cacheDir, "performance_recordings")
        fun validId(id: String) = RecordingStorage.validId(id)
        fun deleteAttempt(context: android.content.Context, id: String) {
            RecordingStorage(root(context)).discard(id)
        }
    }

    override fun onCreate() {
        super.onCreate()
        current = this
        workerThread.start()
        worker = Handler(workerThread.looper)
    }

    override fun onBind(intent: Intent?) = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == STOP) {
            finish(false, "interrupted")
            return START_NOT_STICKY
        }
        val id = intent?.getStringExtra("attemptId")
        if (id == null || !validId(id) || attempt != null) {
            stopSelf()
            return START_NOT_STICKY
        }
        attempt = id
        try {
            val manager = getSystemService(NotificationManager::class.java)
            if (Build.VERSION.SDK_INT >= 26) {
                manager.createNotificationChannel(NotificationChannel(CHANNEL,
                    getString(com.example.soundsight.R.string.performance_recording_channel), NotificationManager.IMPORTANCE_LOW))
            }
            val stop = PendingIntent.getService(this, 0,
                Intent(this, PerformanceRecordingService::class.java).setAction(STOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val notification = (if (Build.VERSION.SDK_INT >= 26) Notification.Builder(this, CHANNEL) else Notification.Builder(this))
                .setSmallIcon(android.R.drawable.presence_video_online)
                .setContentTitle(getString(R.string.performance_recording_title))
                .setContentText(getString(R.string.performance_recording_description))
                .setOngoing(true)
                .addAction(Notification.Action.Builder(null, getString(R.string.performance_recording_stop), stop).build())
                .build()
            if (Build.VERSION.SDK_INT >= 29) {
                var types = ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
                if (Build.VERSION.SDK_INT >= 30) types = types or ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                startForeground(NOTIFICATION, notification, types)
            } else startForeground(NOTIFICATION, notification)
            @Suppress("DEPRECATION")
            val permission = intent!!.getParcelableExtra<Intent>("permission")!!
            val code = intent.getIntExtra("resultCode", Activity.RESULT_CANCELED)
            worker.post { startCapture(id, code, permission) }
        } catch (_: Exception) {
            finish(false, "unavailable")
        }
        return START_NOT_STICKY
    }

    private fun startCapture(id: String, code: Int, permission: Intent) {
        try {
            if (closing) return
            val metrics = resources.displayMetrics
            val (width, height) = RecordingStorage.videoSize(metrics.widthPixels, metrics.heightPixels)
            val supported = MediaCodecList(MediaCodecList.REGULAR_CODECS).codecInfos.any { info ->
                info.isEncoder && info.supportedTypes.any { it.equals("video/avc", true) } &&
                    runCatching { info.getCapabilitiesForType("video/avc").videoCapabilities.areSizeAndRateSupported(width, height, 30.0) }.getOrDefault(false)
            }
            check(supported)
            val directory = RecordingStorage(root(this)).attemptDirectory(id).also { check(it.mkdirs() || it.isDirectory) }
            output = File(directory, "performance.mp4")
            @Suppress("DEPRECATION")
            val media = if (Build.VERSION.SDK_INT >= 31) MediaRecorder(this) else MediaRecorder()
            recorder = media
            media.setAudioSource(MediaRecorder.AudioSource.MIC)
            media.setVideoSource(MediaRecorder.VideoSource.SURFACE)
            media.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            media.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
            media.setVideoSize(width, height)
            media.setVideoFrameRate(30)
            media.setVideoEncodingBitRate(4_000_000)
            media.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            media.setAudioChannels(1)
            media.setAudioSamplingRate(48000)
            media.setAudioEncodingBitRate(128000)
            media.setOutputFile(output!!.absolutePath)
            media.setOnErrorListener { _, _, _ -> finish(false, "unavailable") }
            media.prepare()
            inputSurface = media.surface
            val capture = requireNotNull(getSystemService(MediaProjectionManager::class.java).getMediaProjection(code, permission))
            projection = capture
            capture.registerCallback(object : MediaProjection.Callback() {
                override fun onStop() { finish(false, "interrupted") }
                override fun onCapturedContentResize(w: Int, h: Int) {
                    // Keep the encoder canvas fixed; Android scales captured content to its surface.
                    if (!closing) display?.resize(width, height, metrics.densityDpi)
                }
            }, worker)
            display = capture.createVirtualDisplay("SoundSight performance", width, height,
                metrics.densityDpi, DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                inputSurface, null, worker)
            if (closing) return
            media.start()
            recording = true
            // Let the microphone/encoder pipeline warm up before enabling the
            // first-key trigger in sight reading (falling-note players have a lead-in).
            worker.postDelayed({ if (!closing) emit("recording") }, 250)
        } catch (_: Exception) {
            finish(false, "unavailable")
        }
    }

    fun finish(keep: Boolean, reason: String = if (keep) "ready" else "discarded") {
        synchronized(this) {
            if (closing) return
            closing = true
        }
        worker.post {
            var valid = keep && recording
            // Detach the display before any results UI is shown.
            runCatching { display?.release() }; display = null
            try { if (recording) recorder?.stop() } catch (_: Exception) { valid = false }
            recording = false
            runCatching { inputSurface?.release() }; inputSurface = null
            runCatching { recorder?.reset() }
            runCatching { recorder?.release() }; recorder = null
            runCatching { projection?.stop() }; projection = null
            val file = output
            valid = valid && file != null && file.isFile && file.length() > 0 && validMedia(file)
            if (!valid) attempt?.let { runCatching { deleteAttempt(this, it) } }
            emit(if (valid) "ready" else if (keep) "unavailable" else reason,
                if (valid) file!!.absolutePath else null)
            main.post {
                stopForeground(STOP_FOREGROUND_REMOVE)
                if (current === this) current = null
                stopSelf()
                workerThread.quitSafely()
            }
        }
    }

    private fun validMedia(file: File): Boolean {
        val extractor = MediaExtractor()
        return try {
            extractor.setDataSource(file.absolutePath)
            var video = false; var audio = false
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                val duration = if (format.containsKey(MediaFormat.KEY_DURATION)) format.getLong(MediaFormat.KEY_DURATION) else 0
                if (duration > 0 && mime.startsWith("video/")) video = true
                if (duration > 0 && mime.startsWith("audio/")) audio = true
            }
            video && audio
        } catch (_: Exception) { false } finally { extractor.release() }
    }

    private fun emit(state: String, path: String? = null) {
        val event = mapOf("attemptId" to attempt, "state" to state, "path" to path)
        main.post { listener?.invoke(event) }
    }

    override fun onDestroy() {
        finish(false, "interrupted")
        super.onDestroy()
    }
}
