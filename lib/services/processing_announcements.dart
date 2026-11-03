import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundsight/constants/backend_config.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/screens/composition_details_screen.dart';
import 'package:soundsight/screens/music_sheet/screens/music_sheet_viewer_screen.dart';
import 'package:soundsight/services/processing_job_service.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/app_snack_bar.dart';

@pragma('vm:entry-point')
Future<void> processingMessageBackground(RemoteMessage message) async {
  // FCM displays notification payloads. Do not display a duplicate local alert.
}

class ProcessingAnnouncements extends StatefulWidget {
  const ProcessingAnnouncements({
    super.key,
    required this.child,
    required this.messengerKey,
    required this.navigatorKey,
    required this.popupIsOpen,
  });
  final Widget child;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final GlobalKey<NavigatorState> navigatorKey;
  final bool Function() popupIsOpen;

  /// Set only after the authenticated home screen is reached.
  static final navigationReady = ValueNotifier<bool>(false);

  /// Called before the authenticated logout request, while its token still works.
  static Future<void> unregisterDevice() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      final installation = preferences.getString('processing-installation');
      if (installation != null && FirebaseAuth.instance.currentUser != null) {
        final token = await ProcessingJobService.requireToken();
        await BackendConfig.request(
          '/notifications/devices/$installation',
          retryOnAddressChange: true,
          send: (uri) => http
              .delete(uri, headers: {'Authorization': 'Bearer $token'})
              .timeout(const Duration(seconds: 5)),
        );
      }
    } catch (_) {
      // Logout must remain available even while the PC is offline.
    }
    try {
      await FirebaseMessaging.instance.deleteToken().timeout(
        const Duration(seconds: 5),
      );
    } catch (_) {}
  }

  @override
  State<ProcessingAnnouncements> createState() =>
      _ProcessingAnnouncementsState();
}

class _ProcessingAnnouncementsState extends State<ProcessingAnnouncements>
    with WidgetsBindingObserver {
  StreamSubscription<User?>? _auth;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profile;
  bool _isDarkMode = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _jobs;
  StreamSubscription<String>? _tokens;
  StreamSubscription<RemoteMessage>? _opened;
  StreamSubscription<RemoteMessage>? _messages;
  StreamSubscription<void>? _accepted;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _pending = [];
  final Set<String> _scheduled = {};
  Map<String, dynamic>? _pendingOpen;
  String? _owner;
  Timer? _timer;
  bool _preparingAlert = false;
  bool _opening = false;
  bool _foreground = true;
  bool get _android =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ProcessingAnnouncements.navigationReady.addListener(_ready);
    _auth = FirebaseAuth.instance.userChanges().listen(_onUser);
    _accepted = ProcessingJobService.accepted.listen(
      (_) => unawaited(_afterAccepted()),
    );
    if (_android) {
      _tokens = FirebaseMessaging.instance.onTokenRefresh.listen(
        (_) => unawaited(_register()),
      );
      _opened = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _open(message.data),
      );
      // The Firebase job stream displays foreground alerts, including when push is denied.
      _messages = FirebaseMessaging.onMessage.listen((_) {});
      unawaited(_initialMessage());
    }
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _ready());
  }

  void _onUser(User? user) {
    final owner = user?.emailVerified == true ? user!.uid : null;
    if (_owner == owner) return;
    _jobs?.cancel();
    _profile?.cancel();
    _isDarkMode = false;
    _pending.clear();
    _scheduled.clear();
    if (_owner != null || owner == null) {
      ProcessingAnnouncements.navigationReady.value = false;
    }
    _owner = owner;
    if (owner == null) {
      _pendingOpen = null;
      return;
    }
    unawaited(BackendConfig.refresh());
    _profile = FirebaseFirestore.instance
        .collection('users')
        .doc(owner)
        .snapshots()
        .listen((snapshot) {
          if (_owner == owner) {
            _isDarkMode = snapshot.data()?['theme'] == 'dark';
          }
        }, onError: (Object _) {});
    _jobs = FirebaseFirestore.instance
        .collection('users')
        .doc(owner)
        .collection('processingJobs')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
          if (_owner != owner || snapshot.metadata.hasPendingWrites) return;
          for (final document in snapshot.docs.reversed) {
            final data = document.data();
            if ((data['status'] == 'completed' || data['status'] == 'failed') &&
                data['seenAt'] == null &&
                _scheduled.add(document.id)) {
              _pending.add(document);
            }
          }
          _ready();
        }, onError: (Object _) {});
    unawaited(_register());
  }

  Future<void> _initialMessage() async {
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message != null) _open(message.data);
    } catch (_) {}
  }

  Future<void> _afterAccepted() async {
    if (!_android || _owner == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (preferences.getBool('processing-permission-requested') != true) {
        await preferences.setBool('processing-permission-requested', true);
        await FirebaseMessaging.instance.requestPermission();
      }
      await _register();
    } catch (_) {}
  }

  Future<void> _register() async {
    if (!_android) return;
    final owner = _owner;
    if (owner == null) return;
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        return;
      }
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || owner != _owner) return;
      final preferences = await SharedPreferences.getInstance();
      final installation =
          preferences.getString('processing-installation') ??
          ProcessingJobService.identifier();
      await preferences.setString('processing-installation', installation);
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(owner)
          .get();
      final language = profile.data()?['languageCode'] == 'fil' ? 'fil' : 'en';
      if (owner != _owner) return;
      final authToken = await ProcessingJobService.requireToken();
      if (owner != _owner) return;
      await BackendConfig.request(
        '/notifications/devices/$installation',
        retryOnAddressChange: true,
        send: (uri) => http
            .put(
              uri,
              headers: {
                'Authorization': 'Bearer $authToken',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({'token': token, 'language': language}),
            )
            .timeout(const Duration(seconds: 10)),
      );
    } catch (_) {
      // Register again on the next resume/token refresh or accepted task.
    }
  }

  void _open(Map<String, dynamic> data) {
    _pendingOpen = data;
    _ready();
  }

  void _ready() {
    if (!mounted ||
        !_foreground ||
        !ProcessingAnnouncements.navigationReady.value) {
      return;
    }
    if (_opening) return;
    if (_pendingOpen != null) {
      final payload = _pendingOpen!;
      _pendingOpen = null;
      unawaited(_navigate(payload));
      return;
    }
    if (!_preparingAlert && _pending.isNotEmpty && !widget.popupIsOpen()) {
      unawaited(_showNext());
    }
  }

  Future<void> _showNext() async {
    _preparingAlert = true;
    _pending.sort(
      (first, second) =>
          _completionTime(first).compareTo(_completionTime(second)),
    );
    final document = _pending.removeLast();
    // Only the newest banner is needed; every result remains in Firebase.
    _pending.clear();
    final owner = _owner;
    var continuePending = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      final key = 'processing-seen:$owner:${document.id}';
      if (!mounted || owner == null || owner != _owner) return;
      if (preferences.getBool(key) == true) {
        unawaited(
          document.reference
              .update({'seenAt': FieldValue.serverTimestamp()})
              .catchError((Object _) {}),
        );
        return;
      }
      final messenger = widget.messengerKey.currentState;
      if (messenger == null) {
        _pending.insert(0, document);
        continuePending = false;
        return;
      }
      if (_pending.isNotEmpty) return;
      await preferences.setBool(key, true);
      final data = document.data();
      if (!mounted || owner != _owner || _pending.isNotEmpty) return;
      messenger.showLatestSnackBar(
        appSnackBar(
          colors: AppThemeColors.fromDarkMode(_isDarkMode),
          type: data['status'] == 'completed'
              ? AppSnackBarType.success
              : AppSnackBarType.error,
          message: data['status'] == 'completed'
              ? context.l10n.jobCompletedTitle
              : context.l10n.jobFailedNotification,
          detail: data['title'] as String? ?? '',
          duration: const Duration(seconds: 6),
          actionLabel: context.l10n.jobOpen,
          onAction: () =>
              _open({...data, 'ownerId': owner, 'jobId': document.id}),
        ),
      );
      unawaited(
        document.reference
            .update({'seenAt': FieldValue.serverTimestamp()})
            .catchError((Object _) {}),
      );
    } catch (_) {
      // Persisted seen IDs prevent repeated alerts on listener reconnection.
    } finally {
      _preparingAlert = false;
      if (continuePending &&
          mounted &&
          owner == _owner &&
          _pending.isNotEmpty) {
        _ready();
      }
    }
  }

  int _completionTime(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    final timestamp = data['completedAt'] ?? data['createdAt'];
    return timestamp is Timestamp ? timestamp.millisecondsSinceEpoch : 0;
  }

  Future<void> _navigate(Map<String, dynamic> payload) async {
    if (_opening) return;
    _opening = true;
    try {
      final owner = _owner;
      if (owner == null || payload['ownerId'] != owner) {
        if (mounted) _unavailable();
        return;
      }
      final id = payload['targetId'];
      if (id is! String || id.contains('/')) return;
      final user = FirebaseFirestore.instance.collection('users').doc(owner);
      final composition = payload['taskType'] == 'composition';
      final document = await user
          .collection(composition ? 'compositions' : 'musicSheets')
          .doc(id)
          .get();
      final profile = await user.get();
      if (!mounted || owner != _owner) return;
      final data = document.data();
      if (data == null || data['ownerId'] != owner) {
        _unavailable();
        return;
      }
      final colors = AppThemeColors.fromDarkMode(
        profile.data()?['theme'] == 'dark',
      );
      final Widget screen = composition
          ? CompositionDetailsScreen(
              colors: colors,
              composition: Composition.fromMap(id, data),
            )
          : MusicSheetViewerScreen(
              colors: colors,
              sheetId: id,
              ownerId: owner,
              title: data['title'] as String? ?? '',
              type: data['type'] as String? ?? 'images',
              files: List<Map<String, dynamic>>.from(
                data['files'] as List? ?? [],
              ),
            );
      final jobId = payload['jobId'];
      if (jobId is String && !jobId.contains('/')) {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setBool('processing-seen:$owner:$jobId', true);
        unawaited(
          user
              .collection('processingJobs')
              .doc(jobId)
              .update({'seenAt': FieldValue.serverTimestamp()})
              .catchError((Object _) {}),
        );
      }
      if (mounted && owner == _owner) {
        widget.navigatorKey.currentState?.push(
          MaterialPageRoute<void>(builder: (_) => screen),
        );
      }
    } catch (_) {
      if (mounted) _unavailable();
    } finally {
      _opening = false;
    }
  }

  void _unavailable() => widget.messengerKey.currentState?.showLatestSnackBar(
    appSnackBar(
      colors: AppThemeColors.fromDarkMode(_isDarkMode),
      message: context.l10n.jobItemUnavailable,
      type: AppSnackBarType.error,
    ),
  );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      if (_owner != null) unawaited(BackendConfig.refresh());
      unawaited(_register());
      _ready();
    }
  }

  @override
  void dispose() {
    _auth?.cancel();
    _profile?.cancel();
    _jobs?.cancel();
    _tokens?.cancel();
    _opened?.cancel();
    _messages?.cancel();
    _accepted?.cancel();
    _timer?.cancel();
    ProcessingAnnouncements.navigationReady.removeListener(_ready);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
