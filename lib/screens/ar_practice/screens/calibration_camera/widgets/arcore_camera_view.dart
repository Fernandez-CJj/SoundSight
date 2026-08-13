import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../models/arcore_tracking_status.dart';

// Kotlin sends tracking statuses as uppercase strings because a Kotlin enum
// cannot be passed directly into Dart. This method converts each native name
// into the matching Dart enum value used by the calibration screen.
// An unknown name becomes failed so unreliable tracking is never treated as
// safe for future piano overlays.
ArCoreTrackingStatus parseArCoreTrackingStatus(String statusName) {
  switch (statusName) {
    case 'INITIALIZING':
      return ArCoreTrackingStatus.initializing;
    case 'TRACKING':
      return ArCoreTrackingStatus.tracking;
    case 'PAUSED':
      return ArCoreTrackingStatus.paused;
    case 'STOPPED':
      return ArCoreTrackingStatus.stopped;
    case 'INSUFFICIENT_LIGHT':
      return ArCoreTrackingStatus.insufficientLight;
    case 'EXCESSIVE_MOTION':
      return ArCoreTrackingStatus.excessiveMotion;
    case 'INSUFFICIENT_FEATURES':
      return ArCoreTrackingStatus.insufficientFeatures;
    case 'CAMERA_UNAVAILABLE':
      return ArCoreTrackingStatus.cameraUnavailable;
    case 'BAD_STATE':
      return ArCoreTrackingStatus.badState;
    case 'INSTALL_REQUIRED':
      return ArCoreTrackingStatus.installRequired;
    case 'PERMISSION_MISSING':
      return ArCoreTrackingStatus.permissionMissing;
    case 'UNSUPPORTED':
      return ArCoreTrackingStatus.unsupported;
    case 'FAILED':
      return ArCoreTrackingStatus.failed;
    default:
      return ArCoreTrackingStatus.failed;
  }
}

// Requests the native Android AR view registered in MainActivity and provides
// a callback that sends converted tracking changes to the parent calibration
// screen. StatefulWidget is required because the tracking subscription must
// remain stored for as long as this camera view exists.
class ArCoreCameraView extends StatefulWidget {
  const ArCoreCameraView({super.key, required this.onTrackingStatusChanged});

  // Stores the parent screen's method without calling it immediately.
  // The State object calls this method later when Kotlin sends a new status.
  final ValueChanged<ArCoreTrackingStatus> onTrackingStatusChanged;

  @override
  State<ArCoreCameraView> createState() => _ArCoreCameraViewState();
}

class _ArCoreCameraViewState extends State<ArCoreCameraView> {
  // Matches the native view name registered by MainActivity in Kotlin.
  // Flutter and Kotlin must use exactly the same name so Flutter can request
  // the factory that creates the ARCore camera view.
  final String viewType = 'soundsight/arcore_view';

  // Holds the active native tracking listener. The value starts as null before
  // Android creates the native view and receives a subscription after the
  // matching EventChannel begins listening.
  StreamSubscription<dynamic>? trackingSubscription;

  @override
  Widget build(BuildContext context) {
    // Connects this Dart widget to a native Android view. PlatformViewLink is
    // used here instead of AndroidView so the composition method can be chosen
    // explicitly. This prevents the AR camera SurfaceView from being placed in
    // the virtual-display path that became black after returning from Home.
    return PlatformViewLink(
      viewType: viewType,
      surfaceFactory: createAndroidViewSurface,
      onCreatePlatformView: createAndroidPlatformView,
    );
  }

  // Builds the Flutter-side surface where the completed native Android view
  // appears. Flutter automatically supplies the current BuildContext and the
  // controller that manages the native view.
  Widget createAndroidViewSurface(
    BuildContext context,
    PlatformViewController controller,
  ) {
    // Displays the Android view through Android's view hierarchy. The general
    // controller is converted to AndroidViewController because
    // AndroidViewSurface requires the Android-specific controller type.
    return AndroidViewSurface(
      controller: controller as AndroidViewController,

      // No special native tap, swipe, or drag gestures are required for the
      // calibration camera.
      gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},

      // The entire camera rectangle participates in touch hit testing.
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
    );
  }

  // Creates the controller that asks Kotlin to build the native camera view.
  // Flutter automatically supplies params when PlatformViewLink needs the view.
  PlatformViewController createAndroidPlatformView(
    PlatformViewCreationParams params,
  ) {
    // Uses Hybrid Composition so Android displays the camera SurfaceView
    // directly instead of placing it inside a Flutter virtual display.
    ExpensiveAndroidViewController controller =
        PlatformViewsService.initExpensiveAndroidView(
          id: params.id,
          viewType: viewType,

          // Controls left-to-right layout only. It does not control the phone's
          // portrait or landscape orientation.
          layoutDirection: TextDirection.ltr,
        );

    // Notifies PlatformViewLink after Kotlin finishes creating the native view.
    controller.addOnPlatformViewCreatedListener(
      params.onPlatformViewCreated,
    );

    // Uses the created view's unique ID to connect to its tracking EventChannel.
    controller.addOnPlatformViewCreatedListener(connectTrackingChannel);

    // Sends the native-view creation request after both listeners are ready.
    controller.create();

    // Gives PlatformViewLink the controller that manages the native camera view.
    return controller;
  }

  // Connects to the tracking channel created for this native camera view.
  // The view ID becomes part of the channel name so multiple AR views cannot
  // accidentally receive each other's tracking events.
  void connectTrackingChannel(int viewId) {
    // Stops an older listener first if Android recreated the native view.
    // The null-aware operator skips cancel when no subscription exists yet.
    trackingSubscription?.cancel();

    // Creates the same channel name used by ArCorePlatformView in Kotlin.
    // For example, view ID 3 creates soundsight/arcore_tracking_3.
    EventChannel trackingChannel = EventChannel(
      'soundsight/arcore_tracking_$viewId',
    );

    // Starts listening to the repeating stream of native tracking names and
    // stores the returned subscription for later cleanup.
    trackingSubscription = trackingChannel.receiveBroadcastStream().listen(
      (dynamic statusName) {
        // Ignores late native events after Flutter removes this widget.
        if (mounted == false) {
          return;
        }

        // Platform channels can carry different data types. Conversion only
        // continues when Kotlin supplied the expected String value.
        if (statusName is String) {
          ArCoreTrackingStatus status = parseArCoreTrackingStatus(statusName);

          // Calls the callback stored by ArCoreCameraView. The converted status
          // becomes the argument received by handleTrackingStatusChanged in the
          // parent calibration screen.
          widget.onTrackingStatusChanged(status);
        }
      },
      // A channel failure is reported as failed rather than leaving the screen
      // with an old tracking value that might incorrectly appear reliable.
      onError: (Object error) {
        if (mounted == false) {
          return;
        }

        widget.onTrackingStatusChanged(ArCoreTrackingStatus.failed);
      },
    );
  }

  // Runs when Flutter permanently removes this camera widget.
  // Canceling the subscription stops native tracking events from being delivered
  // to an old screen and releases the Dart listener stored by this State object.
  @override
  void dispose() {
    trackingSubscription?.cancel();

    super.dispose();
  }
}
