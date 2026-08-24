/// Identifies each finger and maps it to its four detector landmarks.
/// The detector uses the same landmark numbers for left and right hands.
enum FlyawayFinger {
  // Thumb landmarks: CMC, MCP, IP, and fingertip.
  thumb(
    baseLandmarkIndex: 1,
    firstJointLandmarkIndex: 2,
    secondJointLandmarkIndex: 3,
    tipLandmarkIndex: 4,
  ),

  // The name is `indexFinger` because Dart enums already have a built-in
  // property named `index`.
  indexFinger(
    baseLandmarkIndex: 5,
    firstJointLandmarkIndex: 6,
    secondJointLandmarkIndex: 7,
    tipLandmarkIndex: 8,
  ),

  middle(
    baseLandmarkIndex: 9,
    firstJointLandmarkIndex: 10,
    secondJointLandmarkIndex: 11,
    tipLandmarkIndex: 12,
  ),

  ring(
    baseLandmarkIndex: 13,
    firstJointLandmarkIndex: 14,
    secondJointLandmarkIndex: 15,
    tipLandmarkIndex: 16,
  ),

  pinky(
    baseLandmarkIndex: 17,
    firstJointLandmarkIndex: 18,
    secondJointLandmarkIndex: 19,
    tipLandmarkIndex: 20,
  );

  /// Creates one finger definition with its four landmark positions.
  const FlyawayFinger({
    required this.baseLandmarkIndex,
    required this.firstJointLandmarkIndex,
    required this.secondJointLandmarkIndex,
    required this.tipLandmarkIndex,
  });

  /// Landmark where the finger connects to the hand.
  final int baseLandmarkIndex;

  /// Landmark for the finger's first joint after its base.
  final int firstJointLandmarkIndex;

  /// Landmark for the joint immediately before the fingertip.
  final int secondJointLandmarkIndex;

  /// Landmark located at the end of the finger.
  final int tipLandmarkIndex;
}
