import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/screens/auth/login/login_screen.dart';
import 'package:soundsight/screens/auth/email_verification/email_verification_screen.dart';
import 'package:soundsight/screens/auth/services/registration_profile_service.dart';
import 'package:soundsight/screens/auth/widgets/auth_loading_screen.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soundsight/l10n/generated/app_localizations.dart';
import 'package:soundsight/localization/app_locale_controller.dart';
import 'package:soundsight/screens/assessment/models/assessment_attempt.dart';
import 'package:soundsight/screens/assessment/screens/assessment_entry_screen.dart';
import 'package:soundsight/screens/assessment/services/assessment_attempt_service.dart';
import 'package:soundsight/screens/homescreen/screens/home_screen.dart';
import 'package:soundsight/screens/profile/achievement_announcements.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Firebase.initializeApp();

  runApp(const SoundSight());
}

class SoundSight extends StatefulWidget {
  const SoundSight({super.key});

  @override
  State<SoundSight> createState() => _SoundSightState();
}

class _SoundSightState extends State<SoundSight> {
  final AppLocaleController localeController = AppLocaleController();
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final AchievementPopupObserver _achievementPopupObserver =
      AchievementPopupObserver();

  @override
  void initState() {
    super.initState();
    loadSavedLanguage();
  }

  @override
  void dispose() {
    localeController.dispose();
    _achievementPopupObserver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: localeController,
      child: AnimatedBuilder(
        animation: localeController,
        builder: (context, _) {
          return MaterialApp(
            scaffoldMessengerKey: _messengerKey,
            navigatorObservers: [_achievementPopupObserver],
            builder: (context, child) => AchievementAnnouncements(
              messengerKey: _messengerKey,
              popupObserver: _achievementPopupObserver,
              child: child ?? const SizedBox.shrink(),
            ),
            locale: localeController.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AuthenticationGate(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  Future<void> loadSavedLanguage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      localeController.applyLanguageCode(userDocument.data()?['languageCode']);
    } on FirebaseException {
      localeController.reset();
    }
  }
}

enum _AuthenticationDestination { login, verification, assessment, home }

/// Validates the persisted Firebase session before exposing authenticated UI.
class AuthenticationGate extends StatefulWidget {
  const AuthenticationGate({
    super.key,
    this.auth,
    this.profileService,
    this.assessmentService,
  });

  final FirebaseAuth? auth;
  final RegistrationProfileService? profileService;
  final AssessmentAttemptService? assessmentService;

  @override
  State<AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<AuthenticationGate> {
  late final FirebaseAuth _auth;
  late final RegistrationProfileService _profileService;
  late final AssessmentAttemptService _assessmentService;
  late Future<_AuthenticationDestination> _destination;
  AssessmentAttempt? _initialAttempt;
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _auth = widget.auth ?? FirebaseAuth.instance;
    _profileService = widget.profileService ?? RegistrationProfileService();
    _assessmentService =
        widget.assessmentService ?? AssessmentAttemptService(auth: _auth);
    _destination = _resolveInitialDestination();
  }

  Future<_AuthenticationDestination> _resolveInitialDestination() async {
    final timer = Stopwatch()..start();
    try {
      return await _resolveDestination();
    } finally {
      final remaining = const Duration(seconds: 3) - timer.elapsed;
      if (remaining > Duration.zero) {
        await Future<void>.delayed(remaining);
      }
    }
  }

  Future<_AuthenticationDestination> _resolveDestination() async {
    _initialAttempt = null;
    _isDarkMode = false;
    var user = _auth.currentUser;

    if (user == null) {
      return _AuthenticationDestination.login;
    }

    // Firebase persists a cached User object. Reload before trusting fields
    // such as emailVerified, which may have changed outside the application.
    await user.reload();
    user = _auth.currentUser;

    if (user == null) {
      return _AuthenticationDestination.login;
    }

    if (!user.emailVerified) {
      return _AuthenticationDestination.verification;
    }

    await user.getIdTokenResult(true);
    final profile = await _profileService.loadProfile(user);

    if (!profile.exists) {
      // Complete a registration that was verified while the app was closed.
      await _profileService.ensureProfile(user);
    } else {
      _isDarkMode = profile.data()?['theme'] == 'dark';
    }

    _initialAttempt = await _assessmentService.loadCurrentAttempt();
    final assessmentStatus = _initialAttempt?.effectiveStatus;

    if (assessmentStatus == AssessmentAttemptStatus.completed ||
        assessmentStatus == AssessmentAttemptStatus.expired) {
      return _AuthenticationDestination.home;
    }

    return _AuthenticationDestination.assessment;
  }

  void _retry() {
    setState(() {
      _destination = _resolveDestination();
    });
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
    } finally {
      if (mounted) {
        _retry();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AuthenticationDestination>(
      future: _destination,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AuthLoadingScreen();
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "We couldn't verify your account status. Check your "
                        'connection and try again.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _retry,
                        child: const Text('Try Again'),
                      ),
                      TextButton(
                        onPressed: _signOut,
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        switch (snapshot.data!) {
          case _AuthenticationDestination.login:
            return LoginScreen(
              auth: _auth,
              profileService: _profileService,
              assessmentService: _assessmentService,
            );
          case _AuthenticationDestination.verification:
            return EmailVerificationScreen(
              auth: _auth,
              profileService: _profileService,
              assessmentService: _assessmentService,
            );
          case _AuthenticationDestination.assessment:
            return AssessmentEntryScreen(
              initialAttempt: _initialAttempt,
              isDarkMode: _isDarkMode,
            );
          case _AuthenticationDestination.home:
            return HomeScreen(isDarkMode: _isDarkMode);
        }
      },
    );
  }
}
