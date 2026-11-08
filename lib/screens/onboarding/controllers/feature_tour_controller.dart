import 'dart:async';

import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:soundsight/screens/onboarding/controllers/feature_tour_journey.dart';
import 'package:soundsight/screens/onboarding/services/feature_tour_progress_service.dart';

class FeatureTourStep {
  FeatureTourStep({required this.targetKey, required this.prepare, this.isAvailable});

  // ShowcaseView 5 uses targetKey only as a registry identifier.
  final GlobalKey targetKey;
  final GlobalKey anchorKey = GlobalKey();
  final Future<bool> Function() prepare;
  final bool Function()? isAvailable;

  bool get available => isAvailable?.call() ?? true;
}

/// Owns one feature's tour, independently of other registered showcase scopes.
class FeatureTourController extends ChangeNotifier with WidgetsBindingObserver {
  FeatureTourController({
    required this.scope,
    required this.featureId,
    required this.steps,
    required this.currentUserId,
    required this.canPresent,
    required this.onExit,
    this.continueTour,
    this.canContinue,
    this.returnToPrevious,
    this.onSeen,
    this.stepOffset = 0,
    this.remainingStepCount,
    FeatureTourJourneyProgress? journeyProgress,
  }) : journeyProgress = journeyProgress ?? FeatureTourJourneyProgress() {
    _showcase = ShowcaseView.register(
      scope: scope,
      enableAutoScroll: false,
      disableBarrierInteraction: true,
      disableMovingAnimation: true,
      disableScaleAnimation: true,
      onFinish: () {
        // Steps are advanced by this controller, so a package-level finish
        // means the current target disappeared. Leave the tour eligible.
        if (_active && !_suspended && !_disposed) unawaited(cancel());
      },
      onDismiss: (_) {
        if (!_ignoringDismiss && _active && !_suspended && !_disposed) {
          unawaited(cancel());
        }
      },
    );
    WidgetsBinding.instance.addObserver(this);
  }

  final String scope;
  final String featureId;
  final List<FeatureTourStep> steps;
  final String? Function() currentUserId;
  final bool Function() canPresent;
  final Future<void> Function() onExit;
  final Future<void> Function()? continueTour;
  final bool Function()? canContinue;
  final Future<void> Function()? returnToPrevious;
  final VoidCallback? onSeen;
  final int stepOffset;
  final int? Function()? remainingStepCount;
  final FeatureTourJourneyProgress journeyProgress;
  final FeatureTourProgressService _progress = FeatureTourProgressService();
  late final ShowcaseView _showcase;

  static FeatureTourController? _activeTour;
  Timer? _visibilityTimer;
  String? _tourUserId;
  bool _active = false;
  bool _starting = false;
  bool _transitioning = false;
  bool _suspended = false;
  bool _ignoringDismiss = false;
  bool _disposed = false;
  int _runId = 0;
  int _startRequestId = 0;
  int _stepIndex = 0;
  int? _resumeRequestId;
  AppLifecycleState _lifecycleState =
      WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed;

  bool get isActive => _active;
  bool get isTransitioning => _transitioning || _suspended;
  bool get isSuspended => _suspended;
  bool get hasContinuation => continueTour != null && (canContinue?.call() ?? true);
  bool get canReturnToPrevious => returnToPrevious != null;
  int get stepIndex => _stepIndex;
  int get presentationId => _runId;
  int? get visibleStepCount => journeyProgress.totalSteps;

  int visibleStepNumber(int index) =>
      stepOffset + steps.take(index + 1).where((step) => step.available).length;

  bool hasNextStep(int index) => _availableIndex(index, 1) != null;
  bool hasPreviousStep(int index) => _availableIndex(index, -1) != null;

  int? _availableIndex(int index, int direction) {
    for (var next = index + direction;
        next >= 0 && next < steps.length; next += direction) {
      if (steps[next].available) return next;
    }
    return null;
  }

  bool get _isForeground => _lifecycleState == AppLifecycleState.resumed;

  bool isPresentationCurrent(int id) =>
      !_disposed && _active && !_suspended && _isForeground && id == _runId;

  Future<void> start({bool replay = false, int initialStep = 0}) async {
    if (_disposed || (!replay && (_active || _starting))) return;
    final userId = currentUserId();
    if (userId == null || steps.isEmpty) return;

    final startRequestId = ++_startRequestId;
    _starting = true;
    try {
      if (replay && _active) await _end(markSeen: false);
      if (_disposed || startRequestId != _startRequestId) return;

      if (!replay) {
        final seen = await _progress.hasSeen(userId, featureId).timeout(
          const Duration(seconds: 8),
        );
        if (_disposed || startRequestId != _startRequestId || seen) return;
      }
      // Wait for any startup dialog to close instead of showing over it.
      while (!_disposed && startRequestId == _startRequestId &&
          currentUserId() == userId && (!_isForeground || !canPresent())) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      if (_disposed || startRequestId != _startRequestId ||
          currentUserId() != userId || !_isForeground || !canPresent()) return;

      final otherTour = _activeTour;
      if (otherTour != null && !identical(otherTour, this)) {
        if (otherTour.canPresent()) return;
        await otherTour.cancel();
      }
      if (_disposed || startRequestId != _startRequestId) return;

      journeyProgress.prepareCount(
        stepOffset + steps.where((step) => step.available).length,
        hasContinuation ? remainingStepCount?.call() : 0,
        restart: stepOffset == 0 && initialStep == 0,
      );
      _tourUserId = userId;
      _active = true;
      _suspended = false;
      _activeTour = this;
      _runId++;
      _visibilityTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (currentUserId() != _tourUserId || (!_suspended && !canPresent())) {
          unawaited(cancel());
        }
      });
      await _presentStep(initialStep.clamp(0, steps.length - 1).toInt());
    } catch (error) {
      if (_disposed || startRequestId != _startRequestId) return;
      debugPrint('Could not start $featureId tutorial: $error');
      await cancel();
    } finally {
      if (startRequestId == _startRequestId) _starting = false;
    }
  }

  Future<void> next() async {
    if (!_active || isTransitioning || !_isForeground || _disposed) return;
    final nextIndex = _availableIndex(_stepIndex, 1);
    if (nextIndex == null) {
      if (hasContinuation) {
        await _end(markSeen: false);
        if (!_disposed) await continueTour!();
      } else {
        await _end(markSeen: true);
      }
    } else {
      await _presentStep(nextIndex);
    }
  }

  Future<void> previous() async {
    if (!_active || isTransitioning || !_isForeground || _disposed) return;
    final previousIndex = _availableIndex(_stepIndex, -1);
    if (previousIndex != null) {
      await _presentStep(previousIndex);
    } else if (returnToPrevious != null) {
      await _end(markSeen: false);
      if (!_disposed) await returnToPrevious!();
    }
  }

  Future<void> skip() async {
    if (!_active || isTransitioning || !_isForeground || _disposed) return;
    await _end(markSeen: true);
  }

  Future<void> cancel() {
    _startRequestId++;
    _starting = false;
    return _end(markSeen: false);
  }

  Future<void> _presentStep(int index) async {
    if (_disposed || !_active || _suspended || !_isForeground) return;
    if (!steps[index].available) {
      final replacement = _availableIndex(index, 1) ?? _availableIndex(index, -1);
      if (replacement == null) {
        await cancel();
        return;
      }
      index = replacement;
    }
    final runId = ++_runId;
    _transitioning = true;
    _dismissCurrent();
    _stepIndex = index;
    notifyListeners();

    try {
      final ready = await steps[index].prepare();
      if (!isPresentationCurrent(runId)) return;
      if (!ready || !canPresent() || currentUserId() != _tourUserId) {
        await cancel();
        return;
      }
      final step = steps[index];
      final target = step.anchorKey.currentContext?.findRenderObject();
      if (!_showcase.isTargetRendered(step.targetKey) ||
          target is! RenderBox || !target.attached || !target.hasSize) {
        debugPrint('Tutorial target is not ready: $featureId step ${index + 1}');
        await cancel();
        return;
      }

      _transitioning = false;
      notifyListeners();
      _showcase.startShowCase([steps[index].targetKey]);
    } catch (error) {
      debugPrint('Could not show $featureId tutorial step: $error');
      if (isPresentationCurrent(runId)) await cancel();
    }
  }

  void _dismissCurrent() {
    _ignoringDismiss = true;
    try {
      _showcase.dismiss();
    } finally {
      _ignoringDismiss = false;
    }
  }

  Future<void> _end({required bool markSeen}) async {
    if (_disposed || !_active) return;
    final userId = _tourUserId;
    _active = false;
    _transitioning = false;
    _suspended = false;
    _runId++;
    _visibilityTimer?.cancel();
    _dismissCurrent();
    if (identical(_activeTour, this)) _activeTour = null;
    notifyListeners();
    await onExit();

    if (markSeen && userId != null && currentUserId() == userId) {
      onSeen?.call();
      try {
        await _progress.markSeen(userId, featureId);
      } catch (error) {
        debugPrint('Could not save $featureId tutorial completion: $error');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
    if (state == AppLifecycleState.detached) {
      unawaited(cancel());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_resumeAfterInterruption());
    } else {
      _suspendForInterruption();
    }
  }

  void _suspendForInterruption() {
    if (_disposed || !_active || _suspended) return;
    _suspended = true;
    _transitioning = true;
    // Invalidate an unfinished scroll or drawer transition, retaining its step.
    _runId++;
    _dismissCurrent();
    notifyListeners();
  }

  Future<void> _resumeAfterInterruption() async {
    if (_disposed || !_active || !_suspended || !_isForeground) return;
    final resumeId = _runId;
    if (_resumeRequestId == resumeId) return;
    _resumeRequestId = resumeId;

    try {
      // Wait for foreground layout/insets before measuring the same target.
      WidgetsBinding.instance.scheduleFrame();
      await WidgetsBinding.instance.endOfFrame;
      if (_disposed || !_active || !_suspended || !_isForeground ||
          resumeId != _runId) return;
      if (currentUserId() != _tourUserId || !canPresent()) {
        await cancel();
        return;
      }

      _suspended = false;
      await _presentStep(_stepIndex);
    } catch (error) {
      debugPrint('Could not resume $featureId tutorial: $error');
      if (!_disposed && _active && resumeId == _runId) await cancel();
    } finally {
      if (_resumeRequestId == resumeId) _resumeRequestId = null;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _active = false;
    _startRequestId++;
    _runId++;
    _visibilityTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _dismissCurrent();
    _showcase.unregister();
    if (identical(_activeTour, this)) _activeTour = null;
    super.dispose();
  }
}
