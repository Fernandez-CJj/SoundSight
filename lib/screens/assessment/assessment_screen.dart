import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/screens/homescreen/home_screen.dart';
import 'package:soundsight/theme/app_colors.dart';

import '../../constants/constant.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final questionTitles = [
    '1. How long have you been playing\nthe piano / keyboard?',
    '2. How well can you read sheet music?',
    '3. How comfortable are you playing\nwith both hands?',
    '4. How well can you follow rhythm\nor play with a metronome?',
    '5. How familiar are you with chords\nand scales?',
    '6. What can you play comfortably?',
  ];

  final questionChoices = [
    [
      "I'm just starting (0-6 months)",
      '6 months - 2 years',
      '2 - 5 years',
      'More than 5 years',
    ],
    [
      "I can't read it yet",
      'I can read simple notes with some help',
      'I can read most notes but still struggle',
      'I can read sheet music easily',
    ],
    [
      'I only use one hand for now',
      'I can play simple parts with both hands',
      'I can play both hands but slowly',
      'I can play both hands confidently',
    ],
    [
      'I struggle to stay on beat',
      'I can follow a slow beat',
      'I can play steady rhythm most of the time',
      'I can follow rhythm and tempo confidently',
    ],
    [
      "I don't know chords or scales yet",
      'I know a few basic chords or scales',
      'I know common chords and major scales',
      'I can use chords and scales comfortably',
    ],
    [
      'Very simple melodies',
      'Beginner songs with slow tempo',
      'Intermediate songs with both hands',
      'Advanced songs with good control',
    ],
  ];

  List<int?> selectedAnswers = List<int?>.filled(6, null);
  final questionKeys = List<GlobalKey>.generate(6, (index) => GlobalKey());
  bool showMissingAnswers = false;
  int totalScore = 0;
  String skillLevel = '';

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
            child: ListView(
              children: [
                const Gap(AppSpacing.lg),
                Row(
                  children: [
                    Image.asset(
                      'assets/images/logo_image_light.png',
                      width: AppIconSizes.xl,
                      height: AppIconSizes.xl,
                      fit: BoxFit.contain,
                    ),
                    const Gap(AppSpacing.md),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SoundSight',
                          style: TextStyle(
                            fontSize: AppTextSizes.sectionTitle,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightPrimary,
                            height: 1.0,
                          ),
                        ),
                        Gap(AppSpacing.xs),
                        Text(
                          'See the music. Play with confidence.',
                          style: TextStyle(
                            fontSize: AppTextSizes.label,
                            color: AppColors.lightSecondaryText,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Gap(AppSpacing.xl),
                const Text(
                  'Skill Level Assessment',
                  style: TextStyle(
                    fontSize: AppTextSizes.display,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightPrimary,
                    height: 1.1,
                  ),
                ),
                const Gap(AppSpacing.sm),
                const Text(
                  "Let's find the best learning experience for you.",
                  style: TextStyle(
                    fontSize: AppTextSizes.body,
                    color: AppColors.lightSecondaryText,
                    height: 1.3,
                  ),
                ),
                const Gap(AppSpacing.xl),

                for (
                  int questionIndex = 0;
                  questionIndex < questionTitles.length;
                  questionIndex++
                ) ...[
                  Container(
                    key: questionKeys[questionIndex],
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color:
                            showMissingAnswers &&
                                selectedAnswers[questionIndex] == null
                            ? AppColors.lightPrimary
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          questionTitles[questionIndex],
                          style: const TextStyle(
                            fontSize: AppTextSizes.body,
                            fontWeight: FontWeight.w700,
                            color: AppColors.lightPrimary,
                            height: 1.25,
                          ),
                        ),
                        const Gap(AppSpacing.md),

                        for (
                          int answerIndex = 0;
                          answerIndex < questionChoices[questionIndex].length;
                          answerIndex++
                        )
                          RadioListTile<int>(
                            value: answerIndex + 1,
                            groupValue: selectedAnswers[questionIndex],
                            activeColor: AppColors.lightPrimary,
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              questionChoices[questionIndex][answerIndex],
                              style: const TextStyle(
                                fontSize: AppTextSizes.body,
                                color: AppColors.lightPrimary,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                selectedAnswers[questionIndex] = value;
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                  const Gap(AppSpacing.lg),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: finishAssessment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightPrimary,
                      foregroundColor: AppColors.lightSurface,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Finish Assessment',
                          style: TextStyle(
                            fontSize: AppTextSizes.body,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Gap(AppSpacing.md),
                        Icon(Icons.arrow_forward, size: AppIconSizes.md),
                      ],
                    ),
                  ),
                ),
                const Gap(AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void finishAssessment() {
    final firstUnansweredIndex = selectedAnswers.indexWhere(
      (answer) => answer == null,
    );

    if (firstUnansweredIndex != -1) {
      setState(() {
        showMissingAnswers = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.lightPrimary,
          content: Text(
            'Please answer every question before finishing.',
            style: TextStyle(color: AppColors.lightSurface),
          ),
        ),
      );

      final questionContext = questionKeys[firstUnansweredIndex].currentContext;

      if (questionContext != null) {
        Scrollable.ensureVisible(
          questionContext,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }

      return;
    }

    setState(() {
      showMissingAnswers = false;
    });

    showConfirmAssessmentDialog();
  }

  void calculateSkillLevel() {
    totalScore = selectedAnswers.fold(0, (sum, answer) => sum + answer!);

    if (totalScore <= 13) {
      skillLevel = 'beginner';
    } else if (totalScore <= 19) {
      skillLevel = 'intermediate';
    } else {
      skillLevel = 'advanced';
    }
  }

  Future<void> saveAssessmentResult() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.lightPrimary,
          content: Text(
            'Unable to find your account. Please login again.',
            style: TextStyle(color: AppColors.lightSurface),
          ),
        ),
      );
      return;
    }

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
                  'Saving assessment',
                  style: TextStyle(
                    color: AppColors.lightPrimary,
                    fontSize: AppTextSizes.sectionTitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'skillLevel': skillLevel,
        'skillAssessmentCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.of(context).pop();
      showSkillLevelDialog();
    } catch (e) {
      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.lightPrimary,
          content: Text(
            'Something went wrong while saving your assessment.',
            style: TextStyle(color: AppColors.lightSurface),
          ),
        ),
      );
    }
  }

  Future<void> showConfirmAssessmentDialog() async {
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
                  'Finish Assessment?',
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
            'Are you sure you want to submit your answers?',
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
                        Navigator.of(dialogContext).pop();
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
                      onPressed: () async {
                        calculateSkillLevel();
                        Navigator.of(dialogContext).pop();
                        await saveAssessmentResult();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lightPrimary,
                        foregroundColor: AppColors.lightSurface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      child: const Text('Continue'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> showSkillLevelDialog() async {
    await showDialog<void>(
      context: context,
      builder: (resultDialogContext) {
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
                  Icons.star_outline,
                  size: AppIconSizes.sm,
                  color: AppColors.lightSurface,
                ),
              ),
              const Gap(AppSpacing.sm),
              const Expanded(
                child: Text(
                  'Your Skill Level',
                  style: TextStyle(
                    color: AppColors.lightPrimary,
                    fontSize: AppTextSizes.sectionTitle,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                skillLevel == 'beginner'
                    ? 'Beginner'
                    : skillLevel == 'intermediate'
                    ? 'Intermediate'
                    : 'Advanced',
                style: const TextStyle(
                  color: AppColors.lightPrimary,
                  fontSize: AppTextSizes.display,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Gap(AppSpacing.sm),
              Text(
                'Score: $totalScore / 24',
                style: const TextStyle(
                  color: AppColors.lightSecondaryText,
                  fontSize: AppTextSizes.body,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(resultDialogContext).pop();
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

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }
}
