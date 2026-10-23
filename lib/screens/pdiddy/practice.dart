import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

import 'practice_content.dart';
import 'stages/stages.dart';

/// Landscape stage map shown when the user opens Practice from the drawer.
class FundamentalsScreen extends StatefulWidget {
  const FundamentalsScreen({super.key});

  @override
  State<FundamentalsScreen> createState() => _FundamentalsScreenState();
}

/// Owns the selected circle, theme preference, and screen orientation.
class _FundamentalsScreenState extends State<FundamentalsScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  final Set<int> _completedStages = <int>{};

  @override
  void initState() {
    super.initState();
    // The stage map is designed for landscape; load the user's theme as well.
    _setLandscape();
    _loadTheme();
  }

  // Requests landscape while this screen is open.
  Future<void> _setLandscape() => SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Reads the same saved light/dark preference used by the rest of the app.
  Future<void> _loadTheme() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      setState(() {
        _isDarkMode = userDoc.data()?['theme'] == 'dark';
      });
    } catch (_) {
      // Keep the app's light palette if the preference cannot be read.
    }
  }

  @override
  void dispose() {
    // Restore the normal app orientation when leaving the stage map.
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Reuse the app palette so this screen follows the selected theme.
    final colors = AppThemeColors.fromDarkMode(_isDarkMode);
    final foreground = colors.primaryColor;

    // The header provides back navigation; the remaining area is the stage row.
    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back, color: foreground, size: 24),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Practice',
                        style: TextStyle(
                          color: foreground,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Size the circles to the available height and allow horizontal scrolling.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final diameter = (constraints.maxHeight * .48).clamp(
                    92.0,
                    128.0,
                  );
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: practiceStages.length,
                    separatorBuilder: (_, _) => Center(
                      child: Container(
                        width: 28,
                        height: 2,
                        color: colors.borderColor,
                      ),
                    ),
                    itemBuilder: (context, index) => Center(
                      child: StageCircle(
                        stage: practiceStages[index],
                        diameter: diameter,
                        selected: index == _selectedIndex,
                        locked: !_isStageUnlocked(practiceStages[index]),
                        colors: colors,
                        onTap: () => _openStage(index, colors),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // The first stage starts open; later stages need the previous stage finished.
  bool _isStageUnlocked(PracticeStage stage) =>
      stage.number == 1 ||
      stage.unlockedForTesting ||
      _completedStages.contains(stage.number - 1);

  Future<void> _openStage(int index, AppThemeColors colors) async {
    // Ask before opening the stage and show its editable description.
    setState(() => _selectedIndex = index);
    final stage = practiceStages[index];
    final unlocked = _isStageUnlocked(stage);
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surfaceColor,
        title: Text(stage.title, style: TextStyle(color: colors.primaryColor)),
        content: Text(
          unlocked
              ? stage.description
              : 'Finish Stage ${stage.number - 1} to unlock this stage.',
          style: TextStyle(color: colors.secondaryTextColor),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.secondaryTextColor),
            ),
          ),
          if (unlocked)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primaryColor,
                foregroundColor: colors.isDarkMode
                    ? Colors.black
                    : Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Proceed'),
            ),
        ],
      ),
    );
    if (shouldProceed != true || !mounted) return;

    // Launch the stage's main activity after the user chooses Proceed.
    await openPracticeStage(
      context,
      stage,
      colors,
      onFinished: () {
        if (mounted) setState(() => _completedStages.add(stage.number));
      },
    );
  }
}
