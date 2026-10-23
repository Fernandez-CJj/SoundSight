import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/screens/assessment/models/assessment_attempt.dart';
import 'package:soundsight/screens/assessment/screens/assessment_entry_screen.dart';
import 'package:soundsight/screens/assessment/services/assessment_attempt_service.dart';
import 'package:soundsight/screens/auth/email_verification/email_verification_screen.dart';
import 'package:soundsight/screens/auth/login/login_dialogs.dart';
import 'package:soundsight/screens/auth/login/login_form.dart';
import 'package:soundsight/screens/auth/register/register_screen.dart';
import 'package:soundsight/screens/auth/services/registration_profile_service.dart';
import 'package:soundsight/screens/homescreen/screens/home_screen.dart';
import 'package:soundsight/theme/app_colors.dart';
import 'package:soundsight/localization/app_locale_controller.dart';

import '../../../constants/constant.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.auth,
    this.profileService,
    this.assessmentService,
  });

  final FirebaseAuth? auth;
  final RegistrationProfileService? profileService;
  final AssessmentAttemptService? assessmentService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final FirebaseAuth auth;
  late final RegistrationProfileService profileService;
  late final AssessmentAttemptService assessmentService;
  final formKey = GlobalKey<FormState>();
  bool isObscure = true;
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    auth = widget.auth ?? FirebaseAuth.instance;
    profileService = widget.profileService ?? RegistrationProfileService();
    assessmentService =
        widget.assessmentService ?? AssessmentAttemptService(auth: auth);
  }

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
  Future<void> firebaseLogin() async {
    var authenticationSucceeded = false;
    showLoginLoadingDialog(context);

    try {
      await auth.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text,
      );
      authenticationSucceeded = true;

      await auth.currentUser?.reload();

      final currentUser = auth.currentUser;

      if (currentUser == null) {
        throw StateError('The authenticated user is unavailable.');
      }

      if (!currentUser.emailVerified) {
        if (!mounted) {
          await auth.signOut();
          return;
        }

        Navigator.of(context).pop();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => EmailVerificationScreen(
              username: currentUser.displayName,
              password: passwordCtrl.text,
              auth: auth,
              profileService: profileService,
              assessmentService: assessmentService,
            ),
          ),
          (route) => false,
        );

        return;
      }

      await currentUser.getIdTokenResult(true);
      var userDocument = await profileService.loadProfile(currentUser);

      if (!userDocument.exists) {
        await profileService.ensureProfile(
          currentUser,
          fallbackUsername: currentUser.displayName,
        );
        userDocument = await profileService.loadProfile(currentUser);
      }

      if (mounted) {
        AppLocaleScope.of(
          context,
        ).applyLanguageCode(userDocument.data()?['languageCode']);
      }

      // The service uses Firestore server time to detect expiration.
      final attempt = await assessmentService.loadCurrentAttempt();

      if (!mounted) {
        await auth.signOut();
        return;
      }

      // Close the login loading dialog before changing the main route.
      Navigator.of(context).pop();

      final assessmentStatus = attempt?.effectiveStatus;
      final isDarkMode = userDocument.data()?['theme'] == 'dark';

      // Completed users keep their calculated level. Expired users have already
      // been assigned Beginner by the assessment service.
      final shouldOpenHome =
          assessmentStatus == AssessmentAttemptStatus.completed ||
          assessmentStatus == AssessmentAttemptStatus.expired;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) {
            if (shouldOpenHome) {
              return HomeScreen(isDarkMode: isDarkMode);
            }

            // A null attempt means the assessment has not started. An active
            // attempt is passed in so the entry screen can display Resume.
            return AssessmentEntryScreen(
              initialAttempt: attempt,
              isDarkMode: isDarkMode,
            );
          },
        ),
        (route) => false,
      );
    } on FirebaseAuthException catch (error) {
      await _signOutAfterFailedInitialization(authenticationSucceeded);

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
      await _signOutAfterFailedInitialization(authenticationSucceeded);

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
      await _signOutAfterFailedInitialization(authenticationSucceeded);

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

  Future<void> _signOutAfterFailedInitialization(
    bool authenticationSucceeded,
  ) async {
    if (!authenticationSucceeded) {
      return;
    }

    try {
      await auth.signOut();
    } on FirebaseAuthException {
      // Preserve the original setup error shown by the caller.
    }
  }
}
