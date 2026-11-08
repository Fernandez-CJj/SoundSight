import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/screens/onboarding/controllers/feature_tour_controller.dart';

class HomeDrawerTour {
  HomeDrawerTour({required this.context, required this.isMounted}) {
    controller = FeatureTourController(
      scope: 'home_drawer_${_nextScope++}',
      featureId: 'home_drawer',
      currentUserId: () => FirebaseAuth.instance.currentUser?.uid,
      canPresent: () => isMounted() && ModalRoute.of(context())?.isCurrent == true,
      onExit: _closeDrawer,
      steps: [
        FeatureTourStep(targetKey: searchKey, prepare: () => _prepareHome(searchKey)),
        FeatureTourStep(targetKey: quickActionsKey, prepare: () => _prepareHome(quickActionsKey)),
        FeatureTourStep(targetKey: communityKey, prepare: () => _prepareHome(communityKey)),
        FeatureTourStep(targetKey: menuKey, prepare: () => _prepareHome(menuKey)),
        FeatureTourStep(targetKey: navigationKey, prepare: () => _prepareDrawer(navigationKey)),
        FeatureTourStep(targetKey: preferencesKey, prepare: () => _prepareDrawer(preferencesKey)),
        FeatureTourStep(targetKey: replayKey, prepare: () => _prepareDrawer(replayKey)),
      ],
    );
  }

  static int _nextScope = 0;
  final BuildContext Function() context;
  final bool Function() isMounted;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final homeScrollController = ScrollController();
  final drawerScrollController = ScrollController();
  final searchKey = GlobalKey();
  final quickActionsKey = GlobalKey();
  final communityKey = GlobalKey();
  final menuKey = GlobalKey();
  final navigationKey = GlobalKey();
  final preferencesKey = GlobalKey();
  final replayKey = GlobalKey();
  late final FeatureTourController controller;
  bool _drawerOpen = false;
  bool _disposed = false;

  void onDrawerChanged(bool open) {
    _drawerOpen = open;
    if (!open && controller.isActive && !controller.isTransitioning &&
        controller.stepIndex >= 4) {
      unawaited(controller.cancel());
    }
  }

  Future<void> _nextFrame() async {
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<bool> _waitForDrawer(bool open) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      if (_disposed || !isMounted()) return false;
      if (_drawerOpen == open) {
        await _nextFrame();
        return !_disposed && isMounted();
      }
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    return false;
  }

  Future<void> _closeDrawer() async {
    if (_disposed || !isMounted()) return;
    scaffoldKey.currentState?.closeDrawer();
    await _waitForDrawer(false);
  }

  Future<bool> _prepareHome(GlobalKey targetKey) async {
    final presentationId = controller.presentationId;
    if (!_canPrepare(presentationId)) return false;
    await _closeDrawer();
    if (!_canPrepare(presentationId)) return false;
    if (targetKey == searchKey || targetKey == menuKey) {
      if (homeScrollController.hasClients) {
        await homeScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
        );
      }
    }
    return _reveal(targetKey, presentationId);
  }

  Future<bool> _prepareDrawer(GlobalKey targetKey) async {
    final presentationId = controller.presentationId;
    if (!_canPrepare(presentationId)) return false;
    scaffoldKey.currentState?.openDrawer();
    if (!await _waitForDrawer(true)) return false;
    if (!_canPrepare(presentationId)) return false;
    return _reveal(targetKey, presentationId);
  }

  bool _canPrepare(int presentationId) =>
      !_disposed && isMounted() && controller.isPresentationCurrent(presentationId);

  Future<bool> _reveal(GlobalKey targetKey, int presentationId) async {
    await _nextFrame();
    if (!_canPrepare(presentationId)) return false;
    final step = controller.steps.firstWhere((step) => step.targetKey == targetKey);
    final targetContext = step.anchorKey.currentContext;
    if (targetContext == null) return false;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    if (!_canPrepare(presentationId)) return false;
    await _nextFrame();
    return _canPrepare(presentationId);
  }

  void dispose() {
    _disposed = true;
    controller.dispose();
    homeScrollController.dispose();
    drawerScrollController.dispose();
  }
}
