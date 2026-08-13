package com.example.soundsight

import com.example.soundsight.ar.ArCoreViewFactory
import com.google.ar.core.ArCoreApk
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    // Identifies the communication channel shared by Kotlin and Dart.
    // This must exactly match the MethodChannel name in the Dart service.
    private val channelName = "soundsight/arcore_compatibility"

    // Identifies the native AR view shared by Kotlin and Dart.
    // The Dart AndroidView must use this exact same name.
    private val arCoreViewType = "soundsight/arcore_view"

    // Flutter calls this function when its engine is ready.
    // Calls super first to keep Flutter's normal setup, then registers the
    // method channel used for the ARCore compatibility check.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Registers the native AR view factory with Flutter.
        // Dart can request this factory using the matching arCoreViewType name.
        val platformViewRegistry =
            flutterEngine.platformViewsController.registry

        platformViewRegistry.registerViewFactory(
            arCoreViewType,
            ArCoreViewFactory(
                this,
                lifecycle,
                flutterEngine.dartExecutor.binaryMessenger
            )
        )

        // binaryMessenger carries messages between Dart and Kotlin.
        // The handler receives the requested method and a result object used to
        // send either a successful value or an error back to Dart.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            if (call.method == "checkArCoreAvailability") {
                try {
                    // Gets the official ARCore manager and checks the
                    // device asynchronously. This keeps Flutter responsive while
                    // ARCore checks support and installation status.
                    val arCoreApk = ArCoreApk.getInstance()

                    arCoreApk.checkAvailabilityAsync(this) { availability ->
                        result.success(availability.name)
                    }
                } catch (exception: Exception) {
                    // Sends native failures back as a structured channel error.
                    // Flutter receives a PlatformException and converts it into
                    // a safe error status instead of allowing the app to crash.
                    result.error(
                        "ARCORE_CHECK_FAILED",
                        exception.message,
                        null,
                    )
                }
            } else {
                // Reports method names that this channel does not support.
                // This prevents Dart from waiting for a result that never arrives.
                result.notImplemented()
            }
        }
    }
}
