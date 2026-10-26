import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/achievements/achievement_badge.dart';
import 'package:soundsight/l10n/generated/app_localizations.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _badgesSubscription;
  final Queue<AchievementBadge> _pending = Queue<AchievementBadge>();
  final Set<AchievementBadge> _announced = {};
  String? _observedUserId;
  Set<String>? _previousBadgeIds;
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
    _badgesSubscription?.cancel();
    widget.popupObserver.removeListener(_onPopupChanged);
    super.dispose();
  }

  void _onUser(User? user) {
    final userId = user?.emailVerified == true ? user?.uid : null;
    if (userId == _observedUserId) return;

    _profileSubscription?.cancel();
    _badgesSubscription?.cancel();
    _observedUserId = userId;
    _previousBadgeIds = null;
    _pending.clear();
    _announced.clear();
    _activeBadge = null;
    _activeController?.close();
    if (userId == null) return;

    final profile = FirebaseFirestore.instance.collection('users').doc(userId);
    _profileSubscription = profile.snapshots().listen((snapshot) {
      if (_observedUserId == userId) {
        _isDarkMode = snapshot.data()?['theme'] == 'dark';
      }
    }, onError: (Object _) {});
    _badgesSubscription = profile
        .collection('achievements')
        .snapshots(includeMetadataChanges: true)
        .listen((snapshot) {
          if (_observedUserId == userId) _onBadges(snapshot);
        }, onError: (Object _) {});
  }

  void _onBadges(QuerySnapshot<Map<String, dynamic>> snapshot) {
    if (snapshot.metadata.hasPendingWrites) return;
    final ids = snapshot.docs.map((doc) => doc.id).toSet();
    final previous = _previousBadgeIds;
    _previousBadgeIds = ids;
    if (previous == null) {
      return;
    }
    for (final document in snapshot.docs) {
      if (previous.contains(document.id) ||
          document.data()['source'] == 'migration') {
        continue;
      }
      final badge = AchievementBadge.fromId(document.id);
      if (badge != null) _enqueue(badge);
    }
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
                  badge.assetPath,
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
