import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/screens/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(SoundSight());
}

class SoundSight extends StatelessWidget {
  const SoundSight({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: LoginScreen(), debugShowCheckedModeBanner: false);
  }
}
