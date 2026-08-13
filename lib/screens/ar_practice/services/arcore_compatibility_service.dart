import 'package:flutter/services.dart';

// Represents ARCore availability inside Flutter.
// Android returns uppercase strings, so they are converted into names that are
// easier and safer to use throughout the Dart code.
enum ArCoreAvailabilityStatus {
  supportedInstalled,
  supportedNotInstalled,
  supportedNeedsUpdate,
  unsupported,
  checking,
  timedOut,
  unknown,
  error,
}

// Provides the Flutter side of the connection to Android.
// The setup screen asks this service to check ARCore instead of communicating
// with the native Kotlin code by itself.
class ArCoreCompatibilityService {
  // Sends method calls between Dart and Kotlin.
  // This name must match channelName in MainActivity.kt exactly, or the Dart and
  // Kotlin sides will not be able to find each other.
  static const MethodChannel methodChannel = MethodChannel(
    'soundsight/arcore_compatibility',
  );

  // Asks Kotlin to perform the ARCore check and waits for its result.
  // Converts the returned string into a Dart enum and returns error when
  // communication fails so calibration can stop safely instead of crashing.
  Future<ArCoreAvailabilityStatus> checkAvailability() async {
    try {
      String? nativeAvailability = await methodChannel.invokeMethod<String>(
        'checkArCoreAvailability',
      );

      return convertAvailability(nativeAvailability);
    } on MissingPluginException {
      return ArCoreAvailabilityStatus.error;
    } on PlatformException {
      return ArCoreAvailabilityStatus.error;
    }
  }

  // Converts every known Android ARCore status into a Flutter status.
  // A null or unfamiliar value becomes unknown so an uncertain device is never
  // treated as ready for AR.
  ArCoreAvailabilityStatus convertAvailability(String? nativeAvailability) {
    if (nativeAvailability == 'SUPPORTED_INSTALLED') {
      return ArCoreAvailabilityStatus.supportedInstalled;
    }

    if (nativeAvailability == 'SUPPORTED_NOT_INSTALLED') {
      return ArCoreAvailabilityStatus.supportedNotInstalled;
    }

    if (nativeAvailability == 'SUPPORTED_APK_TOO_OLD') {
      return ArCoreAvailabilityStatus.supportedNeedsUpdate;
    }

    if (nativeAvailability == 'UNSUPPORTED_DEVICE_NOT_CAPABLE') {
      return ArCoreAvailabilityStatus.unsupported;
    }

    if (nativeAvailability == 'UNKNOWN_CHECKING') {
      return ArCoreAvailabilityStatus.checking;
    }

    if (nativeAvailability == 'UNKNOWN_TIMED_OUT') {
      return ArCoreAvailabilityStatus.timedOut;
    }

    if (nativeAvailability == 'UNKNOWN_ERROR') {
      return ArCoreAvailabilityStatus.error;
    }

    return ArCoreAvailabilityStatus.unknown;
  }
}
