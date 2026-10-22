import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/screens/auth/login/login_screen.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:soundsight/l10n/generated/app_localizations.dart';
import 'package:soundsight/localization/app_locale_controller.dart';
import 'package:soundsight/screens/homescreen/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Firebase.initializeApp();

  final hasUnfinishedAccount = await hasUnfinishedRegistration();

  if (hasUnfinishedAccount) {
    final unfinishedUser = FirebaseAuth.instance.currentUser;

    try {
      await unfinishedUser?.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'user-token-expired') {
        await FirebaseAuth.instance.signOut();
      } else {
        await FirebaseAuth.instance.signOut();
      }
    }
  }

  runApp(const SoundSight());
}

class SoundSight extends StatefulWidget {
  const SoundSight({super.key});

  @override
  State<SoundSight> createState() => _SoundSightState();
}

class _SoundSightState extends State<SoundSight> {
  final AppLocaleController localeController = AppLocaleController();

  @override
  void initState() {
    super.initState();
    loadSavedLanguage();
  }

  @override
  void dispose() {
    localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    return AppLocaleScope(
      controller: localeController,
      child: AnimatedBuilder(
        animation: localeController,
        builder: (context, _) {
          return MaterialApp(
            locale: localeController.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: currentUser == null
                ? const LoginScreen()
                : const HomeScreen(),
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

Future<bool> hasUnfinishedRegistration() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return false;

    if (!user.emailVerified) return true;

    await user.getIdTokenResult(true);

    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return !userDocument.exists;
  } on FirebaseException {
    return false;
  }
}
