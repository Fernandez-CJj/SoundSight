// Represents the live tracking condition reported by native ARCore.
// Only tracking means that the camera pose is reliable for AR overlays.
enum ArCoreTrackingStatus {
  initializing,
  tracking,
  paused,
  stopped,
  insufficientLight,
  excessiveMotion,
  insufficientFeatures,
  cameraUnavailable,
  badState,
  installRequired,
  permissionMissing,
  unsupported,
  failed,
}
