import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/screens/onboarding/controllers/feature_tour_controller.dart';
import 'package:soundsight/screens/onboarding/controllers/feature_tour_journey.dart';
import 'package:soundsight/screens/onboarding/tours/feature_tour_catalog.dart';
import 'package:soundsight/screens/onboarding/widgets/feature_showcase.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

/// Route-local support shared by the feature screens after the initial tours.
class ScreenFeatureTour extends StatefulWidget {
  const ScreenFeatureTour({
    super.key,
    required this.featureId,
    required this.child,
    this.colors,
    this.canStart,
    this.autoStart = true,
    this.openNext,
    this.nextScreens = const <String>{},
    this.canContinue,
    this.remainingStepCount,
  });

  final String featureId;
  final Widget child;
  final AppThemeColors? colors;
  final bool Function()? canStart;
  final bool autoStart;
  final Future<Object?> Function()? openNext;
  final Set<String> nextScreens;
  final bool Function()? canContinue;
  final int? Function()? remainingStepCount;

  static final Map<ModalRoute<dynamic>, ScreenFeatureTourState> _routes = {};

  static ScreenFeatureTourState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_TourScope>()?.state;

  /// Also works in the owning screen's State, above this widget in the tree.
  static bool isActiveOn(BuildContext context) =>
      _routes[ModalRoute.of(context)]?.controller.isActive ?? false;

  static bool targetAvailableOn(BuildContext context, String id) =>
      _routes[ModalRoute.of(context)]?._targetReady(id) ?? false;

  @override
  State<ScreenFeatureTour> createState() => ScreenFeatureTourState();
}

class ScreenFeatureTourState extends State<ScreenFeatureTour> {
  static int _nextScope = 0;
  late final List<FeatureTourHint> hints;
  late final FeatureTourController controller;
  FeatureTourJourney? _journey;
  final Map<String, Object> _owners = {};
  Timer? _readinessTimer;
  ModalRoute<dynamic>? _route;
  bool _attempted = false;
  bool _replayPending = false;

  bool get canReplay => !controller.isActive && !_replayPending &&
      (widget.canStart?.call() ?? true);

  AppThemeColors get colors => widget.colors ?? AppThemeColors.fromDarkMode(
    Theme.of(context).brightness == Brightness.dark,
  );

  @override
  void initState() {
    super.initState();
    hints = featureTourCatalog[widget.featureId]!;
    _journey = FeatureTourJourney.claim(widget.featureId, Navigator.of(context));
    controller = FeatureTourController(
      scope: '${widget.featureId}_${_nextScope++}',
      featureId: _journey?.featureId ?? featureTourParents[widget.featureId] ?? widget.featureId,
      stepOffset: _journey?.completedSteps ?? 0,
      journeyProgress: _journey?.progress,
      remainingStepCount: () {
        if (widget.remainingStepCount != null) return widget.remainingStepCount!();
        // Multiple destinations are alternatives, not steps to add together.
        if (widget.nextScreens.length != 1) return null;
        return featureTourCatalog[widget.nextScreens.single]?.length;
      },
      currentUserId: () => FirebaseAuth.instance.currentUser?.uid,
      canPresent: () => mounted && _route?.isCurrent == true &&
          (widget.canStart?.call() ?? true),
      onExit: _closeDrawer,
      continueTour: widget.openNext == null ? null : _continueToNextScreen,
      canContinue: () => widget.openNext != null && (widget.canContinue?.call() ?? true),
      returnToPrevious: _journey == null ? null : () async {
        await _frame();
        if (mounted) await Navigator.of(context).maybePop();
      },
      onSeen: () {
        _journey?.progress.finished = true;
      },
      steps: [
        for (final hint in hints)
          FeatureTourStep(
            targetKey: GlobalKey(),
            prepare: () => _prepare(hint.id),
            isAvailable: () => _targetReady(hint.id),
          ),
      ],
    );
    controller.addListener(_changed);
    _readinessTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || !controller.canPresent() ||
          !hints.any((hint) => _targetReady(hint.id))) return;
      if (_replayPending) {
        _replayPending = false;
        unawaited(_start(replay: true));
      } else if (!_attempted && (_journey != null ||
          (widget.autoStart && !featureTourParents.containsKey(widget.featureId)))) {
        _attempted = true;
        unawaited(_start(replay: _journey != null));
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (_route != route) {
      if (ScreenFeatureTour._routes[_route] == this) {
        ScreenFeatureTour._routes.remove(_route);
      }
      _route = route;
      if (route != null) ScreenFeatureTour._routes[route] = this;
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  int indexOf(String id) => hints.indexWhere((hint) => hint.id == id);

  bool claim(String id, Object owner) {
    if (indexOf(id) < 0) return false;
    _owners.putIfAbsent(id, () => owner);
    return identical(_owners[id], owner);
  }

  void release(String id, Object owner) {
    if (identical(_owners[id], owner)) _owners.remove(id);
  }

  BuildContext? _targetContext(String id) {
    final index = indexOf(id);
    return index < 0 ? null : controller.steps[index].anchorKey.currentContext;
  }

  bool _targetReady(String id) {
    final target = _targetContext(id)?.findRenderObject();
    return target is RenderBox && target.attached && target.hasSize &&
        !target.size.isEmpty;
  }

  ScaffoldState? get _scaffold {
    for (final hint in hints) {
      final target = _targetContext(hint.id);
      if (target != null) {
        final scaffold = Scaffold.maybeOf(target);
        if (scaffold != null) return scaffold;
      }
    }
    return null;
  }

  Future<void> _closeDrawer() async {
    final scaffold = _scaffold;
    scaffold?.closeDrawer();
    for (var count = 0; count < 40 && scaffold?.isDrawerOpen == true; count++) {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  Future<void> _frame() async {
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _start({bool replay = false}) async {
    _attempted = true;
    await _closeDrawer();
    if (!mounted || !controller.canPresent()) return;
    // Restore a lazy list's first targets when replay is requested after scrolling.
    for (final hint in hints) {
      final target = _targetContext(hint.id);
      final scrollable = target == null ? null : Scrollable.maybeOf(target);
      if (scrollable != null && scrollable.position.hasContentDimensions) {
        scrollable.position.jumpTo(scrollable.position.minScrollExtent);
        break;
      }
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await _frame();
    if (mounted) await controller.start(replay: replay);
  }

  void replay() {
    if (!mounted || controller.isActive || _replayPending) return;
    _attempted = true;
    _replayPending = true;
    _scaffold?.closeDrawer();
  }

  Future<void> _continueToNextScreen() async {
    if (!mounted || widget.openNext == null) return;
    var returnToGuide = true;
    try {
      returnToGuide = await FeatureTourJourney.open(
        context: context,
        featureId: controller.featureId,
        screens: widget.nextScreens,
        progress: controller.journeyProgress,
        completedSteps: controller.visibleStepNumber(controller.stepIndex),
        openScreen: widget.openNext!,
      );
    } catch (error) {
      debugPrint('Could not continue ${widget.featureId} guide: $error');
    }
    if (mounted && returnToGuide) {
      await controller.start(replay: true, initialStep: hints.length - 1);
    }
  }

  Future<bool> _prepare(String id) async {
    final run = controller.presentationId;
    await _closeDrawer();
    await _frame();
    if (!mounted || !controller.isPresentationCurrent(run)) return false;
    final target = _targetContext(id);
    if (target == null) return false;
    await Scrollable.ensureVisible(
      target,
      alignment: 0.1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    await _frame();
    return mounted && controller.isPresentationCurrent(run) && _targetReady(id);
  }

  @override
  void dispose() {
    _readinessTimer?.cancel();
    _journey?.release();
    if (ScreenFeatureTour._routes[_route] == this) {
      ScreenFeatureTour._routes.remove(_route);
    }
    controller.removeListener(_changed);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _TourScope(
    state: this,
    child: PopScope(
      canPop: !controller.isActive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && controller.isActive) {
          scheduleMicrotask(() {
            if (mounted) unawaited(controller.cancel());
          });
        }
      },
      child: AbsorbPointer(absorbing: controller.isActive, child: widget.child),
    ),
  );
}

class _TourScope extends InheritedWidget {
  const _TourScope({required this.state, required super.child});
  final ScreenFeatureTourState state;

  @override
  bool updateShouldNotify(_TourScope oldWidget) => true;
}

/// Repeated cards claim a target once, keeping keys unique across a list/grid.
class FeatureTourTarget extends StatefulWidget {
  const FeatureTourTarget({super.key, required this.id, required this.child,
    this.enabled = true});
  final String id;
  final Widget child;
  final bool enabled;

  @override
  State<FeatureTourTarget> createState() => _FeatureTourTargetState();
}

class _FeatureTourTargetState extends State<FeatureTourTarget> {
  ScreenFeatureTourState? _tour;
  String? _claimedId;

  void _release() {
    if (_claimedId != null) _tour?.release(_claimedId!, this);
    _claimedId = null;
  }

  @override
  void didUpdateWidget(FeatureTourTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id || !widget.enabled) _release();
  }

  @override
  Widget build(BuildContext context) {
    final tour = ScreenFeatureTour.maybeOf(context);
    if (!identical(tour, _tour)) {
      _release();
      _tour = tour;
    }
    if (!widget.enabled || tour == null || !tour.claim(widget.id, this)) {
      return widget.child;
    }
    _claimedId = widget.id;
    final index = tour.indexOf(widget.id);
    final hint = tour.hints[index];
    final filipino = Localizations.localeOf(context).languageCode == 'fil';
    return FeatureShowcase(
      controller: tour.controller,
      stepIndex: index,
      title: filipino ? hint.filipinoTitle : hint.title,
      description: filipino ? hint.filipinoBody : hint.body,
      colors: tour.colors,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _release();
    super.dispose();
  }
}

