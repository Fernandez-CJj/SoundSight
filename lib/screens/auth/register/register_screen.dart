import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/screens/auth/login/login_screen.dart';
import 'package:soundsight/screens/auth/register/register_dialogs.dart';
import 'package:soundsight/screens/auth/register/register_form.dart';
import 'package:soundsight/theme/app_colors.dart';
import 'package:soundsight/screens/auth/email_verification/email_verification_screen.dart';

import '../../../constants/constant.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  bool isChecked = false;
  bool isObscure = true;
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    usernameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPassCtrl.dispose();
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
            child: RegisterForm(
              formKey: formKey,
              usernameController: usernameCtrl,
              emailController: emailCtrl,
              passwordController: passwordCtrl,
              confirmPasswordController: confirmPassCtrl,
              isChecked: isChecked,
              isObscure: isObscure,
              onAgreementChanged: (value) {
                setState(() {
                  isChecked = value ?? false;
                });
              },
              onTermsPressed: () {
                showTermsDialog(context);
              },
              onPrivacyPolicyPressed: () {
                showPrivacyPolicyDialog(context);
              },
              onTogglePasswordVisibility: () {
                setState(() {
                  isObscure = !isObscure;
                });
              },
              onSubmit: () {
                if (formKey.currentState!.validate() && isAgree()) {
                  register();
                }
              },
              onLogin: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ),
        ),
      ),
    );
  }

  bool isAgree() {
    if (!isChecked) {
      showAgreementRequiredDialog(context);
      return false;
    }

    return true;
  }

  void register() async {
    if (await showCreateAccountDialog(context)) {
      if (!mounted) return;
      showRegisterLoadingDialog(context);

      try {
        final userCred = await createRegistrationAccount();

        try {
          await userCred.user!.sendEmailVerification();
        } on FirebaseAuthException catch (e) {
          await userCred.user?.delete();

          if (!mounted) return;

          Navigator.of(context).pop();

          String message;

          if (e.code == 'network-request-failed') {
            message =
                "We couldn't send the verification email. Check your internet "
                'connection and register again.';
          } else if (e.code == 'too-many-requests') {
            message =
                'Too many verification emails were requested. Please wait a '
                'while and register again.';
          } else {
            message =
                "We couldn't send the verification email, so the temporary "
                'account was removed. Please try registering again.';
          }

          await showRegisterErrorDialog(context, message);

          return;
        }

        if (!mounted) return;
        Navigator.of(context).pop();

        await showAccountCreatedDialog(context);

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                EmailVerificationScreen(
                  username: usernameCtrl.text.trim(),
                  password: passwordCtrl.text,
                ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();
        String message;

        if (e.code == 'email-already-in-use') {
          message =
              'An account already uses this email. Please log in or use a '
              'different email address.';
        } else if (e.code == 'network-request-failed') {
          message =
              "We couldn't create your account. Check your internet connection "
              'and try again.';
        } else if (e.code == 'too-many-requests') {
          message =
              'Too many attempts were made from this device. Please wait a '
              'while and try again.';
        } else if (e.code == 'weak-password') {
          message =
              'That password is not strong enough. Please choose a stronger '
              'password.';
        } else if (e.code == 'invalid-email') {
          message = 'Please enter a valid email address.';
        } else if (e.code == 'operation-not-allowed') {
          message =
              'Email registration is unavailable right now. Please try again '
              'later.';
        } else {
          message = "We couldn't create your account. Please try again.";
        }

        await showRegisterErrorDialog(context, message);
      }
    }
  }

  Future<UserCredential> createRegistrationAccount() async {
    final auth = FirebaseAuth.instance;
    final email = emailCtrl.text.trim();
    final password = passwordCtrl.text;

    try {
      return await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (createError) {
      if (createError.code != 'email-already-in-use') {
        rethrow;
      }

      UserCredential unfinishedCredential;

      try {
        unfinishedCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (signInError) {
        await auth.signOut();

        if (signInError.code == 'invalid-credential' ||
            signInError.code == 'wrong-password' ||
            signInError.code == 'user-not-found') {
          throw createError;
        }

        rethrow;
      }

      await unfinishedCredential.user?.reload();

      final unfinishedUser = auth.currentUser;

      if (unfinishedUser == null || unfinishedUser.emailVerified) {
        await auth.signOut();
        throw createError;
      }

      await unfinishedUser.delete();

      return await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
  }
}
