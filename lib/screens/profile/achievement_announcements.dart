import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/l10n/generated/app_localizations.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

enum AchievementBadge {
  firstMeasure('first_measure.png'),
  sheetCollector('sheet_collector.png'),
  firstComposer('first_composer.png'),
  middleC('middle_c.png'),
  firstMelody('first_melody.png'),
  growingMusician('growing_musician.png'),
  chordBuilder('chord_builder.png'),
  musicNavigator('music_navigator.png'),
  soundSightMaster('soundsight_master.png');

  const AchievementBadge(this.filename);

  final String filename;

  String title(AppLocalizations l10n) => switch (this) {
    firstMeasure => l10n.badgeFirstMeasure,
    sheetCollector => l10n.badgeSheetCollector,
    firstComposer => l10n.badgeFirstComposer,
    middleC => l10n.badgeMiddleC,
    firstMelody => l10n.badgeFirstMelody,
    growingMusician => l10n.badgeGrowingMusician,
    chordBuilder => l10n.badgeChordBuilder,
    musicNavigator => l10n.badgeMusicNavigator,
    soundSightMaster => l10n.badgeSoundSightMaster,
  };
}

/// Keeps badge announcements from appearing behind dialogs and bottom sheets.
class AchievementPopupObserver extends NavigatorObserver with ChangeNotifier {
  final Set<Route<dynamic>> _popups = {};

  bool get hasPopup => _popups.isNotEmpty;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) {
      _popups.add(route);
      notifyListeners();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_popups.remove(route)) notifyListeners();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_popups.remove(route)) notifyListeners();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _popups.remove(oldRoute);
    if (newRoute is PopupRoute) _popups.add(newRoute);
    notifyListeners();
  }
}

/// Watches earned-state transitions while the signed-in app is open.
/// The first snapshots form a baseline, so old badges do not reappear on launch.
class AchievementAnnouncements extends StatefulWidget {
  const AchievementAnnouncements({
    super.key,
    required this.child,
    required this.messengerKey,
    required this.popupObserver,
  });

  final Widget child;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final AchievementPopupObserver popupObserver;

  @override
  State<AchievementAnnouncements> createState() =>
      _AchievementAnnouncementsState();
}

class _AchievementAnnouncementsState extends State<AchievementAnnouncements> {
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _assessmentSubscription;
  final Queue<AchievementBadge> _pending = Queue<AchievementBadge>();
  final Set<AchievementBadge> _announced = {};
  String? _observedUserId;
  Map<String, dynamic>? _previousProfile;
  String? _previousAssessmentStatus;
  bool _hasProfileBaseline = false;
  bool _hasAssessmentBaseline = false;
  bool _isDarkMode = false;
  bool _showing = false;
  bool _showScheduled = false;
  AchievementBadge? _activeBadge;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _activeController;

  @override
  void initState() {
    super.initState();
    widget.popupObserver.addListener(_onPopupChanged);
    _authSubscription = FirebaseAuth.instance.userChanges().listen(_onUser);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    _assessmentSubscription?.cancel();
    widget.popupObserver.removeListener(_onPopupChanged);
    super.dispose();
  }

  void _onUser(User? user) {
    final userId = user?.emailVerified == true ? user?.uid : null;
    if (userId == _observedUserId) return;

    _profileSubscription?.cancel();
    _assessmentSubscription?.cancel();
    _observedUserId = userId;
    _previousProfile = null;
    _previousAssessmentStatus = null;
    _hasProfileBaseline = false;
    _hasAssessmentBaseline = false;
    _pending.clear();
    _announced.clear();
    _activeBadge = null;
    _activeController?.close();
    if (userId == null) return;

    final profile = FirebaseFirestore.instance.collection('users').doc(userId);
    _profileSubscription = profile
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
          if (_observedUserId == userId) _onProfile(snapshot);
        }, onError: (Object _) {});
    _assessmentSubscription = profile
        .collection('assessment')
        .doc('current')
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
          if (_observedUserId == userId) _onAssessment(snapshot);
        }, onError: (Object _) {});
  }

  void _onProfile(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.metadata.hasPendingWrites) return;
    final current = snapshot.data();
    if (current == null) return;
    _isDarkMode = current['theme'] == 'dark';
    if (!_hasProfileBaseline) {
      _previousProfile = current;
      _hasProfileBaseline = true;
      return;
    }

    final previous = _previousProfile ?? const <String, dynamic>{};
    _previousProfile = current;
    if (previous['hasUploadedMusicSheet'] != true &&
        current['hasUploadedMusicSheet'] == true &&
        current['sheetBadgeBackfilled'] != true) {
      _enqueue(AchievementBadge.sheetCollector);
    }
    if (previous['hasCreatedComposition'] != true &&
        current['hasCreatedComposition'] == true &&
        current['compositionBadgeBackfilled'] != true) {
      _enqueue(AchievementBadge.firstComposer);
    }

    final oldLevel = (previous['practiceLevel'] as num?)?.toInt() ?? 1;
    final newLevel = (current['practiceLevel'] as num?)?.toInt() ?? 1;
    for (final (threshold, badge) in const [
      (3, AchievementBadge.middleC),
      (6, AchievementBadge.firstMelody),
      (9, AchievementBadge.growingMusician),
      (12, AchievementBadge.chordBuilder),
      (15, AchievementBadge.musicNavigator),
      (16, AchievementBadge.soundSightMaster),
    ]) {
      if (oldLevel <= threshold && newLevel > threshold) _enqueue(badge);
    }
  }

  void _onAssessment(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.metadata.hasPendingWrites) return;
    final status = snapshot.data()?['status'] as String?;
    if (!_hasAssessmentBaseline) {
      _previousAssessmentStatus = status;
      _hasAssessmentBaseline = true;
      return;
    }
    if (_previousAssessmentStatus != 'completed' && status == 'completed') {
      _enqueue(AchievementBadge.firstMeasure);
    }
    _previousAssessmentStatus = status;
  }

  void _enqueue(AchievementBadge badge) {
    if (!_announced.add(badge)) return;
    _pending.add(badge);
    _scheduleShow();
  }

  void _onPopupChanged() {
    if (widget.popupObserver.hasPopup && _activeBadge != null) {
      // A save-result dialog may open just after the badge is earned.
      // Show the same badge again when the dialog closes.
      _pending.addFirst(_activeBadge!);
      _activeBadge = null;
      _activeController?.close();
      return;
    }
    _scheduleShow();
  }

  void _scheduleShow() {
    if (_showScheduled || !mounted) return;
    _showScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showScheduled = false;
      if (mounted) _showNext();
    });
  }

  void _showNext() {
    if (_showing || _pending.isEmpty || widget.popupObserver.hasPopup) return;
    final messenger = widget.messengerKey.currentState;
    final l10n = AppLocalizations.of(context);
    if (messenger == null) return;

    final badge = _pending.removeFirst();
    final colors = AppThemeColors.fromDarkMode(_isDarkMode);
    _showing = true;
    _activeBadge = badge;
    messenger.hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: const Duration(seconds: 5),
        content: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Image.asset(
                  'assets/badge/${badge.filename}',
                  width: 54,
                  height: 54,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.badgeEarnedAnnouncement,
                        style: TextStyle(
                          color: colors.completedStageColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        badge.title(l10n),
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.stars_rounded, color: colors.completedStageColor),
              ],
            ),
          ),
        ),
      ),
    );
    _activeController = controller;
    controller.closed.then((_) {
      _showing = false;
      if (_activeController == controller) {
        _activeController = null;
        _activeBadge = null;
      }
      _scheduleShow();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
