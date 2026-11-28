import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import 'package:pdfrx/pdfrx.dart';

enum SheetMusicVerdict { likelyMusic, unlikelyMusic, uncertain }

class SheetMusicValidationCancelled implements Exception {
  const SheetMusicValidationCancelled();
}

/// A structural check for conventional staff notation, not a guarantee that
/// the score can be converted. All image analysis runs outside the UI isolate.
class SheetMusicValidationService {
  Future<SheetMusicVerdict> validateImage(Uint8List bytes) {
    return compute(_inspectPixels, (bytes: bytes, width: null, height: null));
  }

  Future<SheetMusicVerdict> validatePdf(
    PdfDocument document, {
    required void Function(int page, int total) onProgress,
    required bool Function() isCancelled,
  }) async {
    var uncertain = false;
    for (var index = 0; index < document.pages.length; index++) {
      if (isCancelled()) throw const SheetMusicValidationCancelled();
      onProgress(index + 1, document.pages.length);
      final page = document.pages[index];
      final longestSide = math.max(page.width, page.height);
      if (!longestSide.isFinite || longestSide <= 0) {
        uncertain = true;
        continue;
      }
      final scale = 1600 / longestSide;
      final image = await page.render(
        fullWidth: math.max(1, (page.width * scale).round()).toDouble(),
        fullHeight: math.max(1, (page.height * scale).round()).toDouble(),
        backgroundColor: 0xFFFFFFFF,
      );
      if (image == null) {
        uncertain = true;
        continue;
      }
      try {
        if (isCancelled()) throw const SheetMusicValidationCancelled();
        final verdict = await compute(_inspectPixels, (
          bytes: Uint8List.fromList(image.pixels),
          width: image.width,
          height: image.height,
        ));
        if (isCancelled()) throw const SheetMusicValidationCancelled();
        // The document must contain music; covers and instructions are allowed.
        if (verdict == SheetMusicVerdict.likelyMusic) return verdict;
        uncertain = uncertain || verdict == SheetMusicVerdict.uncertain;
      } finally {
        image.dispose();
      }
    }
    return uncertain
        ? SheetMusicVerdict.uncertain
        : SheetMusicVerdict.unlikelyMusic;
  }
}

typedef _SheetPixels = ({Uint8List bytes, int? width, int? height});

SheetMusicVerdict _inspectPixels(_SheetPixels input) {
  final matrices = <cv.Mat>[];
  cv.Mat keep(cv.Mat matrix) {
    matrices.add(matrix);
    return matrix;
  }

  try {
    final cv.Mat grayscale;
    if (input.width != null && input.height != null) {
      final raw = keep(cv.Mat.fromList(
        input.height!, input.width!, cv.MatType.CV_8UC4, input.bytes,
      ));
      grayscale = keep(cv.cvtColor(raw, cv.COLOR_BGRA2GRAY));
    } else {
      grayscale = keep(cv.imdecode(input.bytes, cv.IMREAD_GRAYSCALE));
    }
    if (grayscale.isEmpty) throw const FormatException('Unreadable sheet image.');
    if (grayscale.rows < 64 || grayscale.cols < 64) {
      return SheetMusicVerdict.uncertain;
    }
    final longestSide = math.max(grayscale.rows, grayscale.cols);
    final scale = math.min(1.0, 1600 / longestSide);
    final resized = keep(cv.resize(grayscale, (
      math.max(1, (grayscale.cols * scale).round()),
      math.max(1, (grayscale.rows * scale).round()),
    ), interpolation: cv.INTER_AREA));
    final binary = keep(cv.adaptiveThreshold(
      resized, 255, cv.ADAPTIVE_THRESH_GAUSSIAN_C,
      cv.THRESH_BINARY_INV, 31, 9,
    ));
    final first = _inspectStaffs(binary);
    if (first == SheetMusicVerdict.likelyMusic) return first;
    // A sideways capture or landscape scan should also be recognized.
    final rotated = keep(cv.rotate(binary, cv.ROTATE_90_CLOCKWISE));
    final second = _inspectStaffs(rotated);
    if (second == SheetMusicVerdict.likelyMusic) return second;
    return first == SheetMusicVerdict.uncertain ||
            second == SheetMusicVerdict.uncertain || _isUnclear(resized, binary)
        ? SheetMusicVerdict.uncertain
        : SheetMusicVerdict.unlikelyMusic;
  } finally {
    for (final matrix in matrices.reversed) {
      matrix.dispose();
    }
  }
}

bool _isUnclear(cv.Mat grayscale, cv.Mat binary) {
  final pixels = grayscale.data;
  final mask = binary.data;
  var minimum = 255;
  var maximum = 0;
  var gradient = 0;
  var ink = 0;
  var samples = 0;
  for (var y = 1; y + 1 < grayscale.rows; y += 4) {
    for (var x = 1; x + 1 < grayscale.cols; x += 4) {
      final index = y * grayscale.cols + x;
      final value = pixels[index];
      minimum = math.min(minimum, value);
      maximum = math.max(maximum, value);
      gradient += (value - pixels[index + 1]).abs() +
          (value - pixels[index + grayscale.cols]).abs();
      if (mask[index] != 0) ink++;
      samples++;
    }
  }
  // A nearly blank image is not a score. Low-detail or low-contrast content
  // instead needs user review; missing lines alone do not prove it is unrelated.
  if (samples == 0 || ink / samples < 0.001) return false;
  return maximum - minimum < 48 || gradient / samples < 5;
}

class _Line {
  _Line(this.left, this.right, this.y, this.slope);

  double left;
  double right;
  double y;
  final double slope;
  double get length => right - left;
}

SheetMusicVerdict _inspectStaffs(cv.Mat binary) {
  final lines = cv.HoughLinesP(
    binary, 1, math.pi / 720, 60,
    minLineLength: math.max(40, binary.cols * 0.18).toDouble(),
    maxLineGap: math.max(6, binary.cols * 0.012).toDouble(),
  );
  final candidates = <_Line>[];
  try {
    // Dense texture is inconclusive, and should not cause unbounded work.
    if (lines.total > 1500) return SheetMusicVerdict.uncertain;
    for (var index = 0; index < lines.rows; index++) {
      final segment = lines.at<cv.Vec4i>(index, 0);
      try {
        final x1 = segment.val1.toDouble();
        final y1 = segment.val2.toDouble();
        final x2 = segment.val3.toDouble();
        final y2 = segment.val4.toDouble();
        if ((x2 - x1).abs() < binary.cols * 0.18) continue;
        final slope = (y2 - y1) / (x2 - x1);
        if (slope.abs() > 0.27) continue;
        candidates.add(_Line(
          math.min(x1, x2), math.max(x1, x2),
          (y1 + y2) / 2, slope,
        ));
      } finally {
        segment.dispose();
      }
    }
  } finally {
    lines.dispose();
  }
  if (candidates.length < 5) return SheetMusicVerdict.unlikelyMusic;

  // Use the dominant line direction to tolerate modest camera rotation.
  final directions = <int, double>{};
  for (final line in candidates) {
    final bin = (line.slope / 0.02).round();
    directions[bin] = (directions[bin] ?? 0) + line.length;
  }
  final dominant = directions.entries.reduce(
    (first, second) => first.value > second.value ? first : second,
  ).key * 0.02;
  final aligned = candidates.where(
    (line) => (line.slope - dominant).abs() <= 0.025,
  ).toList();
  if (aligned.length < 5) return SheetMusicVerdict.uncertain;
  final slope = aligned.fold<double>(
    0, (total, line) => total + line.slope * line.length,
  ) / aligned.fold<double>(0, (total, line) => total + line.length);
  for (final line in aligned) {
    line.y -= slope * (line.left + line.right) / 2;
  }
  aligned.sort((first, second) => first.y.compareTo(second.y));
  final merged = <_Line>[];
  for (final line in aligned) {
    if (merged.isNotEmpty && (merged.last.y - line.y).abs() <= 2) {
      final previous = merged.last;
      previous.left = math.min(previous.left, line.left);
      previous.right = math.max(previous.right, line.right);
    } else {
      merged.add(line);
    }
  }

  for (var index = 0; index + 4 < merged.length; index++) {
    final staff = merged.sublist(index, index + 5);
    final spacing = (staff.last.y - staff.first.y) / 4;
    if (spacing < 4 || spacing > 45) continue;
    final tolerance = math.max(1.5, spacing * 0.2);
    if (List.generate(4, (i) =>
        ((staff[i + 1].y - staff[i].y) - spacing).abs())
        .any((difference) => difference > tolerance)) continue;
    final left = staff.map((line) => line.left).reduce(math.max);
    final right = staff.map((line) => line.right).reduce(math.min);
    if (right - left < binary.cols * 0.25) continue;

    bool continuesRuling(_Line other, double expectedY) {
      return (other.y - expectedY).abs() <= tolerance &&
          math.min(other.right, right) - math.max(other.left, left) >
              (right - left) * 0.7;
    }
    // Six or more equally spaced lines are more likely ruled notebook paper.
    if (index > 0 && continuesRuling(
      merged[index - 1], staff.first.y - spacing,
    )) continue;
    if (index + 5 < merged.length && continuesRuling(
      merged[index + 5], staff.last.y + spacing,
    )) continue;
    if (_hasNotation(binary, staff, left, right, slope, spacing)) {
      return SheetMusicVerdict.likelyMusic;
    }
  }
  // Blank staves, damaged lines, and unusual notation need user review.
  return SheetMusicVerdict.uncertain;
}

bool _hasNotation(
  cv.Mat binary,
  List<_Line> staff,
  double left,
  double right,
  double slope,
  double spacing,
) {
  final width = (right - left).floor();
  final height = (spacing * 6).ceil();
  final pixels = Uint8List(width * height);
  final source = binary.data;
  final top = staff.first.y - spacing;
  final lineThickness = math.max(1.0, spacing * 0.12);
  for (var y = 0; y < height; y++) {
    final ordinate = top + y;
    if (staff.any((line) => (ordinate - line.y).abs() <= lineThickness)) {
      continue;
    }
    for (var x = 0; x < width; x++) {
      final sourceX = (left + x).round();
      final sourceY = (ordinate + slope * sourceX).round();
      if (sourceX >= 0 && sourceX < binary.cols &&
          sourceY >= 0 && sourceY < binary.rows) {
        pixels[y * width + x] = source[sourceY * binary.cols + sourceX];
      }
    }
  }
  final symbols = cv.Mat.fromList(height, width, cv.MatType.CV_8UC1, pixels);
  try {
    final (contours, hierarchy) = cv.findContours(
      symbols, cv.RETR_EXTERNAL, cv.CHAIN_APPROX_SIMPLE,
    );
    try {
      final positions = <double>[];
      for (var index = 0; index < contours.length; index++) {
        final contour = contours[index];
        final bounds = cv.boundingRect(contour);
        try {
          if (bounds.width < spacing * 0.5 || bounds.width > spacing * 2.5 ||
              bounds.height < spacing * 0.25 || bounds.height > spacing * 3.5 ||
              bounds.x < spacing * 2 || bounds.x > width - spacing) continue;
          final area = cv.contourArea(contour);
          if (area < spacing * spacing * 0.1 ||
              area / (bounds.width * bounds.height) < 0.2) continue;
          final center = bounds.x + bounds.width / 2;
          if (positions.every((x) => (x - center).abs() > spacing * 1.5)) {
            positions.add(center);
          }
          if (positions.length >= 3) return true;
        } finally {
          bounds.dispose();
          // The contour is borrowed from contours, which owns its memory.
        }
      }
      return false;
    } finally {
      hierarchy.dispose();
      contours.dispose();
    }
  } finally {
    symbols.dispose();
  }
}
