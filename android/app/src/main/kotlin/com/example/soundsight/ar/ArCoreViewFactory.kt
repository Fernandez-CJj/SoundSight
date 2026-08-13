package com.example.soundsight.ar

import android.app.Activity
import android.content.Context
import androidx.lifecycle.Lifecycle
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

// Creates a native AR view and gives it a unique tracking event channel.
class ArCoreViewFactory(
    private val activity: Activity,
    private val lifecycle: Lifecycle,
    private val binaryMessenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        return ArCorePlatformView(
            context,
            activity,
            lifecycle,
            viewId,
            binaryMessenger
        )
    }
}
