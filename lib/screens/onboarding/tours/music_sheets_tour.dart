import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/screens/onboarding/controllers/feature_tour_controller.dart';
import 'package:soundsight/screens/onboarding/controllers/feature_tour_journey.dart';

class MusicSheetsTour {
  MusicSheetsTour({
    required this.context,
    required this.isMounted,
    required this.isReady,
    required this.hasSheets,
    required this.hasProcessingStatus,
    required this.openSheet,
    required this.sheetStepCount,
  }) {
    controller = FeatureTourController(
      scope: 'music_sheets_${_nextScope++}',
      featureId: 'music_sheets',
      currentUserId: () => FirebaseAuth.instance.currentUser?.uid,
      canPresent: () => isMounted() && isReady() &&
          ModalRoute.of(context())?.isCurrent == true,
      onExit: _closeDrawer,
      continueTour: _continueInsideSheet,
      canContinue: hasSheets,
      remainingStepCount: sheetStepCount,
      steps: [
        FeatureTourStep(targetKey: addKey, prepare: () => _prepareScreen(addKey)),
        FeatureTourStep(targetKey: libraryKey, prepare: () => _prepareScreen(libraryKey)),
        FeatureTourStep(
          targetKey: statusKey,
          prepare: () => _prepareScreen(statusKey),
          isAvailable: hasProcessingStatus,
        ),
        FeatureTourStep(
          targetKey: sheetKey,
          prepare: () => _prepareScreen(sheetKey),
          isAvailable: hasSheets,
        ),
      ],
    );
  }

  static int _nextScope = 0;
  final BuildContext Function() context;
  final bool Function() isMounted;
  final bool Function() isReady;
  final bool Function() hasSheets;
  final bool Function() hasProcessingStatus;
  final Future<Object?> Function() openSheet;
  final int Function() sheetStepCount;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final scrollController = ScrollController();
  final drawerScrollController = ScrollController();
  final addKey = GlobalKey();
  final libraryKey = GlobalKey();
  final sheetKey = GlobalKey();
  final statusKey = GlobalKey();
  late final FeatureTourController controller;
  bool _drawerOpen = false;
  bool _disposed = false;

  void onDrawerChanged(bool open) {
    _drawerOpen = open;
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

  Future<void> _continueInsideSheet() async {
    var returnToGuide = true;
    try {
      returnToGuide = await FeatureTourJourney.open(
        context: context(),
        featureId: 'music_sheets',
        screens: const {'music_sheet_viewer'},
        progress: controller.journeyProgress,
        completedSteps: controller.visibleStepNumber(controller.stepIndex),
        openScreen: openSheet,
      );
    } catch (error) {
      debugPrint('Could not open the sheet guide: $error');
    }
    if (!_disposed && isMounted() && returnToGuide) {
      await controller.start(replay: true, initialStep: 3);
    }
  }

  bool _canPrepare(int id) => !_disposed && isMounted() &&
      isReady() && controller.isPresentationCurrent(id);

  Future<bool> _prepareScreen(GlobalKey key) async {
    final id = controller.presentationId;
    if (!_canPrepare(id)) return false;
    await _closeDrawer();
    if (!_canPrepare(id)) return false;
    // The list is lazy: mount its heading and first card before measuring.
    if (scrollController.hasClients) scrollController.jumpTo(0);
    await _nextFrame();
    if (!_canPrepare(id)) return false;
    return _reveal(key, id);
  }

  Future<bool> _reveal(GlobalKey key, int id) async {
    await _nextFrame();
    if (!_canPrepare(id)) return false;
    final step = controller.steps.firstWhere((step) => step.targetKey == key);
    final targetContext = step.anchorKey.currentContext;
    if (targetContext == null) return false;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: 0.1,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
    if (!_canPrepare(id)) return false;
    await _nextFrame();
    return _canPrepare(id);
  }

  void dispose() {
    _disposed = true;
    controller.dispose();
    scrollController.dispose();
    drawerScrollController.dispose();
  }
}
