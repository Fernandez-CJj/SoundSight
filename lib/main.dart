import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/screens/auth/login/login_screen.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class SoundSight extends StatelessWidget {
  const SoundSight({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
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
