package com.example.soundsight.ar

import io.flutter.plugin.common.EventChannel

// Manages the Flutter event stream used for keyboard-detection results.
// Kotlin sends result maps through this handler, and Dart listens for them.
class KeyboardDetectionStreamHandler : EventChannel.StreamHandler {
    private var keyboardDetectionEventSink: EventChannel.EventSink? = null

    // Stores the newest result map even when Dart temporarily has no listener.
    // The latest safe state can then be resent when Dart reconnects.
    private var latestKeyboardDetectionData: Map<String, Any?>? = null

    // Runs when Dart starts listening to the keyboard-detection event channel.
    // The event sink is the connection used to send later results to Dart.
    override fun onListen(
        arguments: Any?,
        events: EventChannel.EventSink?
    ) {
        keyboardDetectionEventSink = events

        val latestDetectionData =
            latestKeyboardDetectionData

        if (latestDetectionData != null) {
            events?.success(
                latestDetectionData
            )
        }
    }

    // Runs when Dart stops listening to the keyboard-detection event channel.
    // Removing the event sink prevents results from being sent to an old screen.
    override fun onCancel(arguments: Any?) {
        keyboardDetectionEventSink = null
    }

    // Sends one keyboard-detection result map to Dart when a listener exists.
    fun sendKeyboardDetectionResult(
        keyboardDetectionData: Map<String, Any?>
    ) {
        latestKeyboardDetectionData =
            keyboardDetectionData

        keyboardDetectionEventSink?.success(
            keyboardDetectionData
        )
    }

    // Removes the event connection when the native camera view is disposed.
    fun close() {
        keyboardDetectionEventSink = null
        latestKeyboardDetectionData = null
    }
}