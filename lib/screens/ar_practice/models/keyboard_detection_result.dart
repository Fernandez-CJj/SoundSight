import 'keyboard_detection_status.dart';
import 'keyboard_detection_reason.dart';

// Stores one position inside the camera image after Kotlin sends its x and y
// pixel coordinates to Flutter.
class KeyboardImagePoint {
  KeyboardImagePoint({required this.x, required this.y});

  final double x;
  final double y;
}

// Stores the four corners and source-image information for one keyboard region
// that passed Kotlin's computer-vision validation.
class KeyboardRegion {
  KeyboardRegion({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.imageWidth,
    required this.imageHeight,
    required this.timestamp,
    required this.confidence,
  });

  final KeyboardImagePoint topLeft;
  final KeyboardImagePoint topRight;
  final KeyboardImagePoint bottomRight;
  final KeyboardImagePoint bottomLeft;

  final int imageWidth;
  final int imageHeight;
  final int timestamp;
  final double confidence;
}

// Stores the position, size, and detected contour area of one dark shape that
// Kotlin considers a possible black piano key.
class BlackKeyCandidate {
  BlackKeyCandidate({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.contourArea,
  });

  final int left;
  final int top;
  final int width;
  final int height;
  final double contourArea;
}

// Stores one complete keyboard-detection result received from Kotlin.
// A keyboard region is available only when the current frame passed validation.
class KeyboardDetectionResult {
  KeyboardDetectionResult({
    required this.status,
    this.diagnosticReason = KeyboardDetectionReason.unknown,
    required this.keyboardRegion,
    required this.blackKeyCandidates,
    required this.whiteKeyBoundaryPositions,
    required this.timestamp,
    required this.confidence,
  });

  final KeyboardDetectionStatus status;
  final KeyboardDetectionReason diagnosticReason;
  final KeyboardRegion? keyboardRegion;
  final List<BlackKeyCandidate> blackKeyCandidates;
  final List<double> whiteKeyBoundaryPositions;
  final int timestamp;
  final double confidence;
}

// Converts one point map received from Kotlin into a KeyboardImagePoint.
// Invalid or missing coordinate values return null.
KeyboardImagePoint? parseKeyboardImagePoint(Object? pointData) {
  if (pointData is! Map<Object?, Object?>) {
    return null;
  }

  Object? xValue = pointData['x'];
  Object? yValue = pointData['y'];

  if (xValue is! num || yValue is! num) {
    return null;
  }

  KeyboardImagePoint imagePoint = KeyboardImagePoint(
    x: xValue.toDouble(),
    y: yValue.toDouble(),
  );

  return imagePoint;
}

// Converts one keyboard-region map received from Kotlin into a KeyboardRegion.
// Missing corners, image information, or confidence values return null.
KeyboardRegion? parseKeyboardRegion(Object? regionData) {
  if (regionData is! Map<Object?, Object?>) {
    return null;
  }

  KeyboardImagePoint? topLeft = parseKeyboardImagePoint(regionData['topLeft']);

  KeyboardImagePoint? topRight = parseKeyboardImagePoint(
    regionData['topRight'],
  );

  KeyboardImagePoint? bottomRight = parseKeyboardImagePoint(
    regionData['bottomRight'],
  );

  KeyboardImagePoint? bottomLeft = parseKeyboardImagePoint(
    regionData['bottomLeft'],
  );

  if (topLeft == null ||
      topRight == null ||
      bottomRight == null ||
      bottomLeft == null) {
    return null;
  }

  Object? imageWidthValue = regionData['imageWidth'];
  Object? imageHeightValue = regionData['imageHeight'];
  Object? timestampValue = regionData['timestamp'];
  Object? confidenceValue = regionData['confidence'];

  if (imageWidthValue is! num ||
      imageHeightValue is! num ||
      timestampValue is! num ||
      confidenceValue is! num) {
    return null;
  }

  KeyboardRegion keyboardRegion = KeyboardRegion(
    topLeft: topLeft,
    topRight: topRight,
    bottomRight: bottomRight,
    bottomLeft: bottomLeft,
    imageWidth: imageWidthValue.toInt(),
    imageHeight: imageHeightValue.toInt(),
    timestamp: timestampValue.toInt(),
    confidence: confidenceValue.toDouble(),
  );

  return keyboardRegion;
}

// Converts one possible black-key map received from Kotlin into a
// BlackKeyCandidate. Missing or invalid number values return null.
BlackKeyCandidate? parseBlackKeyCandidate(Object? blackKeyData) {
  if (blackKeyData is! Map<Object?, Object?>) {
    return null;
  }

  Object? leftValue = blackKeyData['left'];
  Object? topValue = blackKeyData['top'];
  Object? widthValue = blackKeyData['width'];
  Object? heightValue = blackKeyData['height'];
  Object? contourAreaValue = blackKeyData['contourArea'];

  if (leftValue is! num ||
      topValue is! num ||
      widthValue is! num ||
      heightValue is! num ||
      contourAreaValue is! num) {
    return null;
  }

  BlackKeyCandidate blackKeyCandidate = BlackKeyCandidate(
    left: leftValue.toInt(),
    top: topValue.toInt(),
    width: widthValue.toInt(),
    height: heightValue.toInt(),
    contourArea: contourAreaValue.toDouble(),
  );

  return blackKeyCandidate;
}

// Converts the list of possible black-key maps received from Kotlin into Dart
// BlackKeyCandidate objects. One invalid item rejects the complete list.
List<BlackKeyCandidate>? parseBlackKeyCandidates(Object? blackKeyListData) {
  if (blackKeyListData is! List<Object?>) {
    return null;
  }

  List<BlackKeyCandidate> blackKeyCandidates = [];

  for (Object? blackKeyData in blackKeyListData) {
    BlackKeyCandidate? blackKeyCandidate = parseBlackKeyCandidate(blackKeyData);

    if (blackKeyCandidate == null) {
      return null;
    }

    blackKeyCandidates.add(blackKeyCandidate);
  }

  return blackKeyCandidates;
}

// Converts the white-key boundary list received from Kotlin into decimal pixel
// positions. One invalid position rejects the complete list.
List<double>? parseWhiteKeyBoundaryPositions(Object? boundaryListData) {
  if (boundaryListData is! List<Object?>) {
    return null;
  }

  List<double> boundaryPositions = [];

  for (Object? boundaryValue in boundaryListData) {
    if (boundaryValue is! num) {
      return null;
    }

    double boundaryPosition = boundaryValue.toDouble();

    if (boundaryPosition.isFinite == false) {
      return null;
    }

    boundaryPositions.add(boundaryPosition);
  }

  return boundaryPositions;
}

// Converts the uppercase keyboard-detection status sent by Kotlin into the
// matching Dart enum. Unknown values become failed for overlay safety.
KeyboardDetectionStatus parseKeyboardDetectionStatus(Object? statusData) {
  if (statusData == 'NOT_STARTED') {
    return KeyboardDetectionStatus.notStarted;
  } else if (statusData == 'SEARCHING') {
    return KeyboardDetectionStatus.searching;
  } else if (statusData == 'KEYBOARD_DETECTED') {
    return KeyboardDetectionStatus.keyboardDetected;
  } else if (statusData == 'TOO_FEW_KEYS_VISIBLE') {
    return KeyboardDetectionStatus.tooFewKeysVisible;
  } else if (statusData == 'UNCERTAIN') {
    return KeyboardDetectionStatus.uncertain;
  } else {
    return KeyboardDetectionStatus.failed;
  }
}

// Converts the uppercase diagnostic reason sent by Kotlin into the matching
// Dart enum. An unrecognized or missing reason becomes unknown.
KeyboardDetectionReason parseKeyboardDetectionReason(Object? reasonData) {
  if (reasonData == 'NONE') {
    return KeyboardDetectionReason.none;
  } else if (reasonData == 'OPEN_CV_NOT_READY') {
    return KeyboardDetectionReason.openCvNotReady;
  } else if (reasonData == 'NO_KEYBOARD_CONTOUR') {
    return KeyboardDetectionReason.noKeyboardContour;
  } else if (reasonData == 'INVALID_KEYBOARD_REGION') {
    return KeyboardDetectionReason.invalidKeyboardRegion;
  } else if (reasonData == 'TOO_FEW_BLACK_KEYS') {
    return KeyboardDetectionReason.tooFewBlackKeys;
  } else if (reasonData == 'TOO_FEW_WHITE_KEY_BOUNDARIES') {
    return KeyboardDetectionReason.tooFewWhiteKeyBoundaries;
  } else if (reasonData == 'TOO_FEW_KEY_FEATURES') {
    return KeyboardDetectionReason.tooFewKeyFeatures;
  } else if (reasonData == 'INCONSISTENT_WHITE_KEY_SPACING') {
    return KeyboardDetectionReason.inconsistentWhiteKeySpacing;
  } else if (reasonData == 'INCONSISTENT_BLACK_KEY_PATTERN') {
    return KeyboardDetectionReason.inconsistentBlackKeyPattern;
  } else if (reasonData == 'LOW_CONFIDENCE') {
    return KeyboardDetectionReason.lowConfidence;
  } else if (reasonData == 'STABILIZING') {
    return KeyboardDetectionReason.stabilizing;
  } else if (reasonData == 'TRACKING_UNRELIABLE') {
    return KeyboardDetectionReason.trackingUnreliable;
  } else if (reasonData == 'PROCESSING_FAILED') {
    return KeyboardDetectionReason.processingFailed;
  } else {
    return KeyboardDetectionReason.unknown;
  }
}

// Converts one complete keyboard-detection map received from Kotlin into a
// validated Dart result. Invalid or unsafe data returns null.
KeyboardDetectionResult? parseKeyboardDetectionResult(Object? detectionData) {
  if (detectionData is! Map<Object?, Object?>) {
    return null;
  }

  KeyboardDetectionStatus status = parseKeyboardDetectionStatus(
    detectionData['status'],
  );

  KeyboardDetectionReason diagnosticReason = parseKeyboardDetectionReason(
    detectionData['diagnosticReason'],
  );

  Object? keyboardRegionData = detectionData['keyboardRegion'];

  KeyboardRegion? keyboardRegion;

  if (keyboardRegionData == null) {
    keyboardRegion = null;
  } else {
    keyboardRegion = parseKeyboardRegion(keyboardRegionData);

    if (keyboardRegion == null) {
      return null;
    }
  }

  List<BlackKeyCandidate>? blackKeyCandidates = parseBlackKeyCandidates(
    detectionData['blackKeyCandidates'],
  );

  List<double>? whiteKeyBoundaryPositions = parseWhiteKeyBoundaryPositions(
    detectionData['whiteKeyBoundaryPositions'],
  );

  if (blackKeyCandidates == null || whiteKeyBoundaryPositions == null) {
    return null;
  }

  Object? timestampValue = detectionData['timestamp'];
  Object? confidenceValue = detectionData['confidence'];

  if (timestampValue is! num || confidenceValue is! num) {
    return null;
  }

  int timestamp = timestampValue.toInt();
  double confidence = confidenceValue.toDouble();

  if (timestamp < 0) {
    return null;
  }

  if (confidence.isFinite == false || confidence < 0.0 || confidence > 1.0) {
    return null;
  }

  bool keyboardWasDetected = status == KeyboardDetectionStatus.keyboardDetected;

  if (keyboardWasDetected && keyboardRegion == null) {
    return null;
  }

  if (keyboardWasDetected == false && keyboardRegion != null) {
    return null;
  }

  KeyboardDetectionResult keyboardDetectionResult = KeyboardDetectionResult(
    status: status,
    diagnosticReason: diagnosticReason,
    keyboardRegion: keyboardRegion,
    blackKeyCandidates: blackKeyCandidates,
    whiteKeyBoundaryPositions: whiteKeyBoundaryPositions,
    timestamp: timestamp,
    confidence: confidence,
  );

  return keyboardDetectionResult;
}
