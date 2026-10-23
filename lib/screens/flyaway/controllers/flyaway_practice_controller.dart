import 'dart:math' as math;

import 'package:hand_detection/hand_detection.dart';

import '../models/finger_measurement.dart';
import '../models/flyaway_finger.dart';
import 'flyaway_analysis_controller.dart';

enum FlyawayPracticeStage { idle, preparing, resting, moving, ready, running, finished }

class FlyawayFingerSummary {
  const FlyawayFingerSummary({required this.events, required this.flaggedTime});

  final int events;
  final Duration flaggedTime;
}

class FlyawaySessionSummary {
  const FlyawaySessionSummary({required this.duration, required this.fingers});

  final Duration duration;
  final Map<Handedness, Map<FlyawayFinger, FlyawayFingerSummary>> fingers;
}

class FlyawayFrameResult {
  const FlyawayFrameResult({required this.detectedHands, required this.flaggedFingers});

  final Set<Handedness> detectedHands;
  final Map<Handedness, Set<FlyawayFinger>> flaggedFingers;
}

class _FingerProfile {
  _FingerProfile(this.restingDepth);

  final double restingDepth;
  final List<double> normalLifts = <double>[];
  final List<double> independentLifts = <double>[];
  double? liftLimit;
  double? independentLimit;
}

class _FingerEvent {
  DateTime? highStartedAt;
  DateTime? lastSeenAt;
  DateTime? lastHighAt;
  DateTime? flaggedStartedAt;
  int highFrames = 0;
  int lowFrames = 0;
  int events = 0;
  Duration flaggedTime = Duration.zero;

  bool get flagged => flaggedStartedAt != null;

  void close() {
    final start = flaggedStartedAt;
    final end = lastHighAt;
    if (start != null && end != null && end.isAfter(start)) {
      flaggedTime += end.difference(start);
    }
    flaggedStartedAt = null;
    highStartedAt = null;
    lastHighAt = null;
    highFrames = 0;
    lowFrames = 0;
  }
}

/// Consumes detected hands; camera setup and frame scheduling belong to the caller.
class FlyawayPracticeController {
  static const int minimumRestingSamples = 5;
  static const int minimumMovementSamples = 15;
  static const Duration maximumTrackingGap = Duration(milliseconds: 250);
  static const Duration requiredHighTime = Duration(milliseconds: 300);

  final FlyawayAnalysisController _analysis = FlyawayAnalysisController();
  final Map<Handedness, Map<FlyawayFinger, List<double>>> _restSamples = {};
  final Map<Handedness, Map<FlyawayFinger, _FingerProfile>> _profiles = {};
  final Map<Handedness, List<FingerMeasurement>> _previous = {};
  final Map<Handedness, DateTime> _lastSeen = {};
  final Map<Handedness, Map<FlyawayFinger, _FingerEvent>> _events = {};

  FlyawayPracticeStage stage = FlyawayPracticeStage.idle;
  DateTime? _sessionStartedAt;
  FlyawaySessionSummary? lastSummary;

  Set<Handedness> get calibratedHands => Set<Handedness>.unmodifiable(
    _profiles.entries
        .where((entry) => entry.value.length == FlyawayFinger.values.length &&
            entry.value.values.every((profile) =>
                profile.liftLimit != null && profile.independentLimit != null))
        .map((entry) => entry.key),
  );

  void reset() {
    stage = FlyawayPracticeStage.idle;
    _restSamples.clear();
    _profiles.clear();
    _previous.clear();
    _lastSeen.clear();
    _events.clear();
    _sessionStartedAt = null;
    lastSummary = null;
  }

  void beginCalibration() {
    reset();
    stage = FlyawayPracticeStage.preparing;
  }

  void beginResting() {
    _previous.clear();
    _lastSeen.clear();
    stage = FlyawayPracticeStage.resting;
  }

  void beginMovement() {
    _profiles.clear();
    for (final handEntry in _restSamples.entries) {
      final profiles = <FlyawayFinger, _FingerProfile>{};
      for (final finger in FlyawayFinger.values) {
        final samples = handEntry.value[finger];
        if (samples != null && samples.length >= minimumRestingSamples) {
          profiles[finger] = _FingerProfile(_percentile(samples, 0.5));
        }
      }
      if (profiles.length == FlyawayFinger.values.length) {
        _profiles[handEntry.key] = profiles;
      }
    }
    _previous.clear();
    _lastSeen.clear();
    stage = FlyawayPracticeStage.moving;
  }

  bool completeCalibration() {
    _profiles.removeWhere((_, profiles) {
      if (profiles.length != FlyawayFinger.values.length) return true;
      for (final profile in profiles.values) {
        if (profile.normalLifts.length < minimumMovementSamples ||
            profile.independentLifts.length < minimumMovementSamples) {
          return true;
        }
      }
      for (final profile in profiles.values) {
        profile.liftLimit = _limit(_percentile(profile.normalLifts, 0.95));
        profile.independentLimit =
            _limit(_percentile(profile.independentLifts, 0.95));
      }
      return false;
    });
    _restSamples.clear();
    _previous.clear();
    _lastSeen.clear();
    stage = _profiles.isEmpty ? FlyawayPracticeStage.idle : FlyawayPracticeStage.ready;
    return _profiles.isNotEmpty;
  }

  bool startSession(DateTime timestamp) {
    if (stage != FlyawayPracticeStage.ready || calibratedHands.isEmpty) return false;
    _events.clear();
    for (final handedness in calibratedHands) {
      _events[handedness] = {
        for (final finger in FlyawayFinger.values) finger: _FingerEvent(),
      };
    }
    _previous.clear();
    _lastSeen.clear();
    lastSummary = null;
    _sessionStartedAt = timestamp;
    stage = FlyawayPracticeStage.running;
    return true;
  }

  FlyawaySessionSummary stopSession(DateTime timestamp) {
    for (final handEvents in _events.values) {
      for (final event in handEvents.values) {
        final lastSeen = event.lastSeenAt;
        if (event.flagged && lastSeen != null &&
            !timestamp.isBefore(lastSeen) &&
            timestamp.difference(lastSeen) <= maximumTrackingGap) {
          event.lastHighAt = timestamp;
        }
        event.close();
      }
    }
    final started = _sessionStartedAt;
    final duration = started == null || timestamp.isBefore(started)
        ? Duration.zero
        : timestamp.difference(started);
    final fingers = <Handedness, Map<FlyawayFinger, FlyawayFingerSummary>>{};
    for (final handEntry in _events.entries) {
      fingers[handEntry.key] = {
        for (final fingerEntry in handEntry.value.entries)
          fingerEntry.key: FlyawayFingerSummary(
            events: fingerEntry.value.events,
            flaggedTime: fingerEntry.value.flaggedTime,
          ),
      };
    }
    final summary = FlyawaySessionSummary(duration: duration, fingers: fingers);
    lastSummary = summary;
    _sessionStartedAt = null;
    _previous.clear();
    _lastSeen.clear();
    stage = FlyawayPracticeStage.finished;
    return summary;
  }

  FlyawayFrameResult acceptHands(List<Hand> hands, DateTime timestamp) {
    final selected = <Handedness, Hand>{};
    final ambiguous = <Handedness>{};
    for (final hand in hands) {
      final handedness = hand.handedness;
      if (handedness == null || hand.score < 0.5 || hand.landmarks.length < 21) {
        continue;
      }
      if (FlyawayFinger.values.any((finger) =>
          !hand.landmarks[finger.baseLandmarkIndex].z.isFinite ||
          !hand.landmarks[finger.tipLandmarkIndex].z.isFinite)) {
        continue;
      }
      if (selected.containsKey(handedness)) {
        ambiguous.add(handedness);
      } else {
        selected[handedness] = hand;
      }
    }
    for (final handedness in ambiguous) {
      selected.remove(handedness);
    }

    for (final handedness in _lastSeen.keys.toList()) {
      final previousTime = _lastSeen[handedness]!;
      if (!selected.containsKey(handedness) ||
          timestamp.difference(previousTime) > maximumTrackingGap ||
          timestamp.isBefore(previousTime)) {
        _forgetTracking(handedness);
      }
    }

    final flagged = <Handedness, Set<FlyawayFinger>>{};
    for (final handEntry in selected.entries) {
      final handedness = handEntry.key;
      final measurements = _smooth(
        handedness,
        _analysis.measureHand(handEntry.value),
      );
      _previous[handedness] = measurements;
      _lastSeen[handedness] = timestamp;

      if (stage == FlyawayPracticeStage.resting) {
        final handSamples = _restSamples.putIfAbsent(handedness, () => {});
        for (final measurement in measurements) {
          handSamples.putIfAbsent(measurement.finger, () => <double>[])
              .add(measurement.relativeDepth);
        }
      } else if (stage == FlyawayPracticeStage.moving) {
        _collectMovement(handedness, measurements);
      } else if (stage == FlyawayPracticeStage.running) {
        final current = _updateEvents(handedness, measurements, timestamp);
        if (current.isNotEmpty) flagged[handedness] = current;
      }
    }
    return FlyawayFrameResult(
      detectedHands: selected.keys.toSet(),
      flaggedFingers: flagged,
    );
  }

  void _forgetTracking(Handedness handedness) {
    _previous.remove(handedness);
    _lastSeen.remove(handedness);
    for (final event in _events[handedness]?.values ?? <_FingerEvent>[]) {
      event.close();
    }
  }

  List<FingerMeasurement> _smooth(
    Handedness handedness,
    List<FingerMeasurement> current,
  ) {
    final previous = _previous[handedness];
    if (previous == null || previous.length != current.length) return current;
    return <FingerMeasurement>[
      for (var index = 0; index < current.length; index++)
        FingerMeasurement(
          finger: current[index].finger,
          relativeDepth: previous[index].relativeDepth * 0.6 +
              current[index].relativeDepth * 0.4,
        ),
    ];
  }

  Map<FlyawayFinger, double> _lifts(
    Map<FlyawayFinger, _FingerProfile> profiles,
    List<FingerMeasurement> measurements,
  ) => {
    for (final measurement in measurements)
      if (profiles.containsKey(measurement.finger))
        measurement.finger:
            measurement.relativeDepth - profiles[measurement.finger]!.restingDepth,
  };

  double? _independentLift(
    FlyawayFinger finger,
    Map<FlyawayFinger, double> lifts,
  ) {
    final value = lifts[finger];
    if (value == null) return null;
    final adjacent = switch (finger) {
      FlyawayFinger.thumb => <FlyawayFinger>[FlyawayFinger.indexFinger],
      FlyawayFinger.indexFinger =>
        <FlyawayFinger>[FlyawayFinger.thumb, FlyawayFinger.middle],
      FlyawayFinger.middle =>
        <FlyawayFinger>[FlyawayFinger.indexFinger, FlyawayFinger.ring],
      FlyawayFinger.ring =>
        <FlyawayFinger>[FlyawayFinger.middle, FlyawayFinger.pinky],
      FlyawayFinger.pinky => <FlyawayFinger>[FlyawayFinger.ring],
    };
    final neighbors = <double>[
      for (final neighbor in adjacent)
        if (lifts[neighbor] != null) lifts[neighbor]!,
    ];
    if (neighbors.isEmpty) return null;
    return value - neighbors.reduce((a, b) => a + b) / neighbors.length;
  }

  void _collectMovement(
    Handedness handedness,
    List<FingerMeasurement> measurements,
  ) {
    final profiles = _profiles[handedness];
    if (profiles == null) return;
    final lifts = _lifts(profiles, measurements);
    for (final finger in FlyawayFinger.values) {
      final lift = lifts[finger];
      final independent = _independentLift(finger, lifts);
      if (lift == null || independent == null) continue;
      profiles[finger]!.normalLifts.add(lift);
      profiles[finger]!.independentLifts.add(independent);
    }
  }

  Set<FlyawayFinger> _updateEvents(
    Handedness handedness,
    List<FingerMeasurement> measurements,
    DateTime timestamp,
  ) {
    final profiles = _profiles[handedness];
    final events = _events[handedness];
    if (profiles == null || events == null) return {};
    final lifts = _lifts(profiles, measurements);
    final flagged = <FlyawayFinger>{};
    for (final finger in FlyawayFinger.values) {
      final profile = profiles[finger]!;
      final lift = lifts[finger];
      final independent = _independentLift(finger, lifts);
      final high = lift != null && independent != null &&
          lift > profile.liftLimit! &&
          independent > profile.independentLimit!;
      final event = events[finger]!;
      final last = event.lastSeenAt;
      if (last != null &&
          (timestamp.difference(last) > maximumTrackingGap ||
              timestamp.isBefore(last))) {
        event.close();
      }
      event.lastSeenAt = timestamp;
      if (high) {
        event.lowFrames = 0;
        event.lastHighAt = timestamp;
        event.highStartedAt ??= timestamp;
        event.highFrames++;
        if (!event.flagged && event.highFrames >= 3 &&
            timestamp.difference(event.highStartedAt!) >= requiredHighTime) {
          event.flaggedStartedAt = timestamp;
          event.events++;
        }
      } else if (event.flagged) {
        event.lowFrames++;
        if (event.lowFrames >= 2) event.close();
      } else {
        event.highStartedAt = null;
        event.highFrames = 0;
      }
      if (event.flagged) flagged.add(finger);
    }
    return flagged;
  }

  double _limit(double normal) {
    final safeNormal = math.max(0.0, normal);
    return safeNormal + math.max(safeNormal * 0.2, 0.5);
  }

  double _percentile(List<double> values, double percentile) {
    final sorted = List<double>.from(values)..sort();
    final position = (sorted.length - 1) * percentile;
    final lower = position.floor();
    final upper = position.ceil();
    if (lower == upper) return sorted[lower];
    return sorted[lower] +
        (sorted[upper] - sorted[lower]) * (position - lower);
  }
}
