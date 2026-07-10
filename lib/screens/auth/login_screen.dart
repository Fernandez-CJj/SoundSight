import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/screens/assessment/assessment_screen.dart';
import 'package:soundsight/screens/auth/register_screen.dart';
import 'package:soundsight/screens/auth/widgets/app_text_form_field.dart';
import 'package:soundsight/screens/homescreen/home_screen.dart';
import 'package:soundsight/theme/app_colors.dart';
import '../../constants/constant.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  bool isObscure = true;
  var emailCtrl = TextEditingController();
  var passwordCtrl = TextEditingController();

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
                    'Welcome back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTextSizes.display,
                      fontWeight: FontWeight.w400,
                      color: AppColors.lightPrimary,
                    ),
                  ),
                  const Gap(AppSpacing.xs),
                  const Text(
                    'Continue your piano learning journey',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTextSizes.body,
                      color: AppColors.lightSecondaryText,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Gap(AppSpacing.lg),

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

                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
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
                  Gap(AppSpacing.md),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.lightPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        textStyle: const TextStyle(
                          fontSize: AppTextSizes.label,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  Gap(AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          firebaseLogin();
                        }
                      },
                      icon: const Icon(
                        Icons.login_outlined,
                        size: AppIconSizes.md,
                      ),
                      label: const Text('Login'),
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
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppColors.lightSecondaryText,
                          fontSize: AppTextSizes.body,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => RegisterScreen()),
                          );
                        },
                        child: Text(
                          'Register',
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

  void firebaseLogin() async {
    showLoginLoadingDialog();
    try {
      UserCredential userCred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailCtrl.text,
            password: passwordCtrl.text,
          );
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .get();

      final isAssessed = userDoc.data()?['skillAssessmentCompleted'] ?? false;

      Navigator.of(context).pop();
      if (isAssessed == true) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => HomeScreen()));
      } else {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => AssessmentScreen()));
      }
    } on FirebaseAuthException catch (e) {
      Navigator.of(context).pop();

      await showLoginErrorDialog(
        e.message ?? 'Something went wrong while logging in to your account.',
      );
    }
  }

  void showLoginLoadingDialog() {
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
                  'Logging in',
                  style: TextStyle(
                    color: AppColors.lightPrimary,
                    fontSize: AppTextSizes.sectionTitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Gap(AppSpacing.xs),
                Text(
                  'Please wait while we open your account.',
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

  Future<void> showLoginErrorDialog(String message) async {
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
                  'Login Error',
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
}
