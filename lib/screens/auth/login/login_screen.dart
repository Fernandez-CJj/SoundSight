import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/screens/assessment/models/assessment_attempt.dart';
import 'package:soundsight/screens/assessment/screens/assessment_entry_screen.dart';
import 'package:soundsight/screens/assessment/services/assessment_attempt_service.dart';
import 'package:soundsight/screens/auth/login/login_dialogs.dart';
import 'package:soundsight/screens/auth/login/login_form.dart';
import 'package:soundsight/screens/auth/register/register_screen.dart';
import 'package:soundsight/screens/homescreen/screens/home_screen.dart';
import 'package:soundsight/theme/app_colors.dart';

import '../../../constants/constant.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  bool isObscure = true;
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background_image.png'),
              opacity: 0.8,
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: LoginForm(
              formKey: formKey,
              emailController: emailCtrl,
              passwordController: passwordCtrl,
              isObscure: isObscure,
              onTogglePasswordVisibility: () {
                setState(() {
                  isObscure = !isObscure;
                });
              },
              onSubmit: () {
                if (formKey.currentState!.validate()) {
                  firebaseLogin();
                }
              },
              onRegister: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// Authenticates the user, synchronizes assessment expiration, and opens the
  /// correct first screen for the user's assessment state.
  void firebaseLogin() async {
    showLoginLoadingDialog(context);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
      );

      await FirebaseAuth.instance.currentUser?.reload();

      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser?.emailVerified != true) {
        await currentUser?.delete();

        if (!mounted) return;

        Navigator.of(context).pop();

        await showLoginErrorDialog(
          context,
          "This email hasn't been verified, so the unfinished account was "
          'removed. Please register again.',
        );

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
          (route) => false,
        );

        return;
      }

      final userDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!userDocument.exists) {
        await currentUser.delete();

        if (!mounted) return;

        Navigator.of(context).pop();

        await showLoginErrorDialog(
          context,
          "We couldn't find a completed SoundSight profile for this account. "
          'The incomplete account was removed. Please register again.',
        );

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RegisterScreen()),
          (route) => false,
        );

        return;
      }

      // The service uses Firestore server time to detect expiration.
      final assessmentService = AssessmentAttemptService();
      final attempt = await assessmentService.loadCurrentAttempt();

      if (!mounted) {
        return;
      }

      // Close the login loading dialog before changing the main route.
      Navigator.of(context).pop();

      final assessmentStatus = attempt?.effectiveStatus;

      // Completed users keep their calculated level. Expired users have already
      // been assigned Beginner by the assessment service.
      final shouldOpenHome =
          assessmentStatus == AssessmentAttemptStatus.completed ||
          assessmentStatus == AssessmentAttemptStatus.expired;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) {
            if (shouldOpenHome) {
              return const HomeScreen();
            }

            // A null attempt means the assessment has not started. An active
            // attempt is passed in so the entry screen can display Resume.
            return AssessmentEntryScreen(initialAttempt: attempt);
          },
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      String message;

      if (error.code == 'network-request-failed') {
        message =
            "We couldn't sign you in. Check your internet connection and try "
            'again.';
      } else if (error.code == 'too-many-requests') {
        message =
            'Too many login attempts were made. Please wait a while and try '
            'again.';
      } else if (error.code == 'invalid-credential' ||
          error.code == 'wrong-password' ||
          error.code == 'user-not-found') {
        message = 'The email or password is incorrect.';
      } else if (error.code == 'user-disabled') {
        message = 'This account is currently disabled.';
      } else if (error.code == 'invalid-email') {
        message = 'Please enter a valid email address.';
      } else if (error.code == 'operation-not-allowed') {
        message =
            'Email login is unavailable right now. Please try again later.';
      } else {
        message = "We couldn't sign you in. Please try again.";
      }

      await showLoginErrorDialog(context, message);
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      String message;

      if (error.code == 'unavailable' ||
          error.code == 'network-request-failed') {
        message =
            "We couldn't load your account. Check your internet connection and "
            'try again.';
      } else if (error.code == 'permission-denied') {
        message = "We couldn't open this account. Please sign in again.";
      } else {
        message =
            "We couldn't load your account information. Please try again.";
      }

      await showLoginErrorDialog(context, message);
    } catch (error) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      await showLoginErrorDialog(
        context,
        "We couldn't finish signing you in. Please try again.",
      );
    }
  }
}
