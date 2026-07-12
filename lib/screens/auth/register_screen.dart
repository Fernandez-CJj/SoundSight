import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/screens/auth/login_screen.dart';
import 'package:soundsight/screens/auth/widgets/app_text_form_field.dart';
import 'package:soundsight/theme/app_colors.dart';

import '../../constants/constant.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  bool isChecked = false;
  bool isObscure = true;
  var usernameCtrl = TextEditingController();
  var emailCtrl = TextEditingController();
  var passwordCtrl = TextEditingController();
  var confirmPassCtrl = TextEditingController();

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
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/background_image.png"),
              opacity: 0.8,
              fit: BoxFit.cover,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Form(
              key: formKey,
              child: ListView(
                children: [
                  const Gap(AppSpacing.xxl),
                  Center(
                    child: Image.asset(
                      'assets/images/logo_image_light.png',
                      width: 92,
                      height: 92,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  const Text(
                    'SoundSight',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTextSizes.screenTitle,
                      fontWeight: FontWeight.w600,
                      color: AppColors.lightPrimary,
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  const Text(
                    "See the music. Play with confidence",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTextSizes.caption,
                      color: AppColors.lightSecondaryText,
                    ),
                  ),
                  const Gap(AppSpacing.xl),
                  const Text(
                    'Create your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTextSizes.display,
                      fontWeight: FontWeight.w400,
                      color: AppColors.lightPrimary,
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  const Text(
                    'Start your piano learning journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTextSizes.body,
                      color: AppColors.lightSecondaryText,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Gap(AppSpacing.lg),
                  AppTextFormField(
                    controller: usernameCtrl,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                    label: 'Username',
                    prefixIcon: Icons.person_outline,
                  ),
                  Gap(AppSpacing.md),
                  AppTextFormField(
                    controller: emailCtrl,
                    label: 'Email Address',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }

                      if (!EmailValidator.validate(value.trim())) {
                        return 'Enter a valid email address';
                      }

                      return null;
                    },

                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  Gap(AppSpacing.md),
                  AppTextFormField(
                    controller: passwordCtrl,
                    label: 'Password',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }

                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }

                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'Password must contain at least one capital letter';
                      }

                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return 'Password must contain at least one number';
                      }

                      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                        return 'Password must contain at least one special character';
                      }

                      return null;
                    },
                    prefixIcon: Icons.lock_outlined,
                    obscureText: isObscure,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isObscure = !isObscure;
                        });
                      },
                      icon: Icon(
                        isObscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  Gap(AppSpacing.sm),
                  Padding(
                    padding: EdgeInsets.only(left: AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: AppIconSizes.sm,
                          color: AppColors.lightSecondaryText,
                        ),
                        Gap(AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'Use at least 8 characters with a capital letter, number, and special character.',
                            style: TextStyle(
                              fontSize: AppTextSizes.caption,
                              color: AppColors.lightSecondaryText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gap(AppSpacing.md),
                  AppTextFormField(
                    controller: confirmPassCtrl,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }

                      if (value != passwordCtrl.text) {
                        return 'Passwords do not match';
                      }

                      return null;
                    },
                    label: 'Confirm Password',

                    prefixIcon: Icons.lock_outlined,
                    obscureText: isObscure,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isObscure = !isObscure;
                        });
                      },
                      icon: Icon(
                        isObscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  Gap(AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: isChecked,
                        activeColor: AppColors.lightPrimary,
                        checkColor: AppColors.lightSurface,
                        onChanged: (value) {
                          setState(() {
                            isChecked = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: AppTextSizes.body,
                              color: AppColors.lightSecondaryText,
                            ),
                            children: const [
                              TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.lightPrimary,
                                ),
                              ),
                              TextSpan(text: 'and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.lightPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap(AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (formKey.currentState!.validate() && isAgree()) {
                          register();
                        }
                      },
                      icon: const Icon(
                        Icons.person_add_alt_1,
                        size: AppIconSizes.md,
                      ),
                      label: const Text('Create Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightPrimary,
                        foregroundColor: AppColors.lightSurface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        textStyle: const TextStyle(
                          fontSize: AppTextSizes.body,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Gap(AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.lightBorder,
                          thickness: 1,
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(
                          'or',
                          style: TextStyle(
                            fontSize: AppTextSizes.label,
                            color: AppColors.lightSecondaryText,
                          ),
                        ),
                      ),

                      Expanded(
                        child: Divider(
                          color: AppColors.lightBorder,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  Gap(AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: AppColors.lightSecondaryText,
                          fontSize: AppTextSizes.body,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => LoginScreen()),
                          );
                        },
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightPrimary,
                            fontSize: AppTextSizes.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gap(AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool isAgree() {
    if (!isChecked) {
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.lightSurface,
            surfaceTintColor: AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            title: Row(
              children: [
                Container(
                  width: AppSpacing.xl,
                  height: AppSpacing.xl,
                  decoration: BoxDecoration(
                    color: AppColors.lightPrimary,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    size: AppIconSizes.sm,
                    color: AppColors.lightSurface,
                  ),
                ),
                const Gap(AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Agreement Required',
                    style: TextStyle(
                      color: AppColors.lightPrimary,
                      fontSize: AppTextSizes.sectionTitle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Please agree to the Terms and Privacy Policy before creating your account.',
              style: TextStyle(
                color: AppColors.lightSecondaryText,
                fontSize: AppTextSizes.body,
                height: 1.4,
              ),
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lightPrimary,
                    foregroundColor: AppColors.lightSurface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: const Text('Okay'),
                ),
              ),
            ],
          );
        },
      );

      return false;
    }

    return true;
  }

  void register() async {
    if (await showCreateAccountDialog()) {
      showRegisterLoadingDialog();

      try {
        UserCredential userCred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailCtrl.text,
              password: passwordCtrl.text,
            );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user!.uid)
            .set({
              'uid': userCred.user!.uid,
              'username': usernameCtrl.text.trim(),
              'email': emailCtrl.text.trim(),
              'role': 'piano_player',
              'theme': 'light',
              'skillAssessmentCompleted': false,
              'assessmentScore': null,
              'skillLevel': null,
              'preferredNotation': null,
              'accountStatus': 'active',
              'assessmentDate': null,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
        if (!mounted) return;
        Navigator.of(context).pop();
        await showAccountCreatedDialog();
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();
        await showRegisterErrorDialog(
          e.message ?? 'Something went wrong while creating your account.',
        );
      }
    }

    return;
  }

  Future<bool> showCreateAccountDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppColors.lightSurface,
              surfaceTintColor: AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              title: Row(
                children: [
                  Container(
                    width: AppSpacing.xl,
                    height: AppSpacing.xl,
                    decoration: BoxDecoration(
                      color: AppColors.lightPrimary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1,
                      size: AppIconSizes.sm,
                      color: AppColors.lightSurface,
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Create Account?',
                      style: TextStyle(
                        color: AppColors.lightPrimary,
                        fontSize: AppTextSizes.sectionTitle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Are you sure you want to create this account?',
                style: TextStyle(
                  color: AppColors.lightSecondaryText,
                  fontSize: AppTextSizes.body,
                  height: 1.4,
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.lightPrimary,
                            side: const BorderSide(
                              color: AppColors.lightInputBorder,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lightPrimary,
                            foregroundColor: AppColors.lightSurface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: const Text('Create'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> showAccountCreatedDialog() async {
    final goToLogin =
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppColors.lightSurface,
              surfaceTintColor: AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              title: Row(
                children: [
                  Container(
                    width: AppSpacing.xl,
                    height: AppSpacing.xl,
                    decoration: BoxDecoration(
                      color: AppColors.lightPrimary,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: AppIconSizes.sm,
                      color: AppColors.lightSurface,
                    ),
                  ),
                  const Gap(AppSpacing.sm),
                  const Expanded(
                    child: Text(
                      'Account Created',
                      style: TextStyle(
                        color: AppColors.lightPrimary,
                        fontSize: AppTextSizes.sectionTitle,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Your account has been created successfully. Do you want to go to the login screen?',
                style: TextStyle(
                  color: AppColors.lightSecondaryText,
                  fontSize: AppTextSizes.body,
                  height: 1.4,
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.lightPrimary,
                            side: const BorderSide(
                              color: AppColors.lightInputBorder,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: const Text('Stay'),
                        ),
                      ),
                    ),
                    const Gap(AppSpacing.sm),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lightPrimary,
                            foregroundColor: AppColors.lightSurface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: const Text('Login'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;

    if (!mounted) return;

    if (goToLogin) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Future<void> showRegisterErrorDialog(String message) async {
    const Color errorColor = Color(0xFFDC2626);

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.lightSurface,
          surfaceTintColor: AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Row(
            children: [
              Container(
                width: AppSpacing.xl,
                height: AppSpacing.xl,
                decoration: BoxDecoration(
                  color: errorColor,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: AppIconSizes.sm,
                  color: AppColors.lightSurface,
                ),
              ),
              const Gap(AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Account Error',
                  style: TextStyle(
                    color: AppColors.lightPrimary,
                    fontSize: AppTextSizes.sectionTitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppColors.lightSecondaryText,
              fontSize: AppTextSizes.body,
              height: 1.4,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: errorColor,
                  foregroundColor: AppColors.lightSurface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: const Text('Okay'),
              ),
            ),
          ],
        );
      },
    );
  }

  void showRegisterLoadingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: AppColors.lightSurface,
            surfaceTintColor: AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.lightPrimary,
                  ),
                ),
                Gap(AppSpacing.md),
                Text(
                  'Creating account',
                  style: TextStyle(
                    color: AppColors.lightPrimary,
                    fontSize: AppTextSizes.sectionTitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(AppSpacing.xs),
                Text(
                  'Please wait while we set up your account.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.lightSecondaryText,
                    fontSize: AppTextSizes.body,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
