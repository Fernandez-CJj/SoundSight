import 'package:permission_handler/permission_handler.dart';

// Represents the possible results after checking or requesting
// access to the device camera.
enum CameraPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unknown,
}

// Checks the camera permission that is currently stored by Android.
// This method only reads the permission and does not show a permission dialog.
class CameraPermissionService {
  Future<CameraPermissionResult> checkCameraPermission() async {
    try {
      PermissionStatus permissionStatus = await Permission.camera.status;

      if (permissionStatus == PermissionStatus.granted) {
        return CameraPermissionResult.granted;
      }

      if (permissionStatus == PermissionStatus.denied) {
        return CameraPermissionResult.denied;
      }

      if (permissionStatus == PermissionStatus.permanentlyDenied) {
        return CameraPermissionResult.permanentlyDenied;
      }

      if (permissionStatus == PermissionStatus.restricted) {
        return CameraPermissionResult.restricted;
      }

      return CameraPermissionResult.unknown;
    } on Exception {
      return CameraPermissionResult.unknown;
    }
  }

  // Requests camera access from Android.
  // Android may display a permission dialog for the user to answer.
  Future<CameraPermissionResult> requestCameraPermission() async {
    try {
      PermissionStatus permissionStatus = await Permission.camera.request();

      if (permissionStatus == PermissionStatus.granted) {
        return CameraPermissionResult.granted;
      }

      if (permissionStatus == PermissionStatus.denied) {
        return CameraPermissionResult.denied;
      }

      if (permissionStatus == PermissionStatus.permanentlyDenied) {
        return CameraPermissionResult.permanentlyDenied;
      }

      if (permissionStatus == PermissionStatus.restricted) {
        return CameraPermissionResult.restricted;
      }

      return CameraPermissionResult.unknown;
    } on Exception {
      return CameraPermissionResult.unknown;
    }
  }

  // Opens SoundSight's Android app settings.
  // This allows camera permission to be changed when Android cannot show
  // the normal permission dialog again.
  Future<bool> openCameraPermissionSettings() async {
    try {
      bool didOpenSettings = await openAppSettings();

      return didOpenSettings;
    } on Exception {
      return false;
    }
  }
}
