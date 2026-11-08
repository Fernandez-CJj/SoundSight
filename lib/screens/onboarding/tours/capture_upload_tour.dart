import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/screens/onboarding/controllers/feature_tour_controller.dart';

class CaptureUploadTour {
  CaptureUploadTour({
    required this.context,
    required this.isMounted,
    required this.isBusy,
  }) {
    controller = FeatureTourController(
      scope: 'upload_capture_${_nextScope++}',
      featureId: 'upload_capture',
      currentUserId: () => FirebaseAuth.instance.currentUser?.uid,
      canPresent: () => isMounted() && !isBusy() &&
          ModalRoute.of(context())?.isCurrent == true,
      onExit: _closeDrawer,
      steps: [
        for (final key in [pdfKey, captureKey, recordingKey, tipsKey, previewKey, saveKey])
          FeatureTourStep(targetKey: key, prepare: () => _prepare(key)),
      ],
    );
  }

  static int _nextScope = 0;
  final BuildContext Function() context;
  final bool Function() isMounted;
  final bool Function() isBusy;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final scrollController = ScrollController();
  final pdfKey = GlobalKey();
  final captureKey = GlobalKey();
  final recordingKey = GlobalKey();
  final tipsKey = GlobalKey();
  final previewKey = GlobalKey();
  final saveKey = GlobalKey();
  late final FeatureTourController controller;
  bool _drawerOpen = false;
  bool _disposed = false;

  void onDrawerChanged(bool open) {
    _drawerOpen = open;
    if (open && controller.isActive && !controller.isTransitioning) {
      unawaited(controller.cancel());
    }
  }

  Future<void> _nextFrame() async {
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _closeDrawer() async {
    if (_disposed || !isMounted()) return;
    scaffoldKey.currentState?.closeDrawer();
    for (var attempt = 0; attempt < 40 && _drawerOpen; attempt++) {
      if (_disposed || !isMounted()) return;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  }

  bool _canPrepare(int id) => !_disposed && isMounted() &&
      !isBusy() && controller.isPresentationCurrent(id);

  Future<bool> _prepare(GlobalKey key) async {
    final id = controller.presentationId;
    await _closeDrawer();
    await _nextFrame();
    if (!_canPrepare(id) || _drawerOpen) return false;
    final step = controller.steps.firstWhere((step) => step.targetKey == key);
    final targetContext = step.anchorKey.currentContext;
    if (targetContext == null) return false;
    if (key != saveKey) {
      await Scrollable.ensureVisible(
        targetContext,
        alignment: 0.1,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
    if (!_canPrepare(id)) return false;
    await _nextFrame();
    return _canPrepare(id);
  }

  void dispose() {
    _disposed = true;
    controller.dispose();
    scrollController.dispose();
  }
}
