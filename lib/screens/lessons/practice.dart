import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

import 'practice_content.dart';
import 'practice_progress_service.dart';
import 'stages/stages.dart';

/// The portrait and landscape map of the user's practice stages.
class FundamentalsScreen extends StatefulWidget {
  const FundamentalsScreen({super.key});

  @override
  State<FundamentalsScreen> createState() => _FundamentalsScreenState();
}

class _FundamentalsScreenState extends State<FundamentalsScreen> {
  final PracticeProgressService _progressService = PracticeProgressService();
  final ScrollController _pathScrollController = ScrollController();
  bool _isDarkMode = false;
  String? _skillLevel;
  int? _practiceLevel;
  String? _progressError;
  int? _pendingPassedStage;
  bool _savingProgress = false;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.orientationOf(context);
    if (_lastOrientation != orientation) {
      _lastOrientation = orientation;
      _scrollToCurrentStage();
    }
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _progressError = 'Sign in to open lessons.');
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
        _skillLevel = userDoc.data()?['skillLevel'] as String?;
        _practiceLevel = null;
      });
      final level = await _progressService.loadLevel();
      if (!mounted) return;
      setState(() {
        _practiceLevel = level;
        _progressError = null;
      });
      _scrollToCurrentStage();
    } catch (error) {
      if (mounted) {
        setState(() => _progressError = 'Could not load lesson progress: $error');
      }
    }
  }

  void _scrollToCurrentStage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _practiceLevel == null || !_pathScrollController.hasClients) {
        return;
      }
      final index = _practiceLevel! > practiceStages.length
          ? practiceStages.length - 1
          : _practiceLevel! - 1;
      final horizontal = _lastOrientation == Orientation.landscape;
      final step = horizontal ? 248.0 : 128.0;
      final position = _pathScrollController.position;
      final offset = (index * step - position.viewportDimension * .12).clamp(
        0.0,
        position.maxScrollExtent,
      ).toDouble();
      _pathScrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _pathScrollController.dispose();
    SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(_isDarkMode);
    final horizontal = MediaQuery.orientationOf(context) == Orientation.landscape;
    return Scaffold(
      backgroundColor: colors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.arrow_back, color: colors.primaryColor),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Practice',
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (_practiceLevel != null)
                    Text(
                      '${_completedCount()}/${practiceStages.length} complete',
                      style: TextStyle(
                        color: _completedCount() > 0
                            ? colors.completedStageColor
                            : colors.secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            if (_practiceLevel != null) _buildProgressHeader(colors, horizontal),
            if (_pendingPassedStage != null) _buildSaveBanner(colors),
            Expanded(
              child: _practiceLevel == null
                  ? Center(
                      child: _progressError == null
                          ? CircularProgressIndicator(color: colors.primaryColor)
                          : Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _progressError!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: colors.primaryColor),
                                  ),
                                  TextButton(
                                    onPressed: _loadProfile,
                                    child: Text(
                                      'Retry',
                                      style: TextStyle(color: colors.primaryColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    )
                  : _buildStagePath(colors, horizontal),
            ),
          ],
        ),
      ),
    );
  }

  int _completedCount() => _practiceLevel! > practiceStages.length
      ? practiceStages.length
      : _practiceLevel! - 1;

  Widget _buildProgressHeader(AppThemeColors colors, bool horizontal) {
    final allComplete = _practiceLevel! > practiceStages.length;
    final completed = _completedCount();
    final heading = allComplete
        ? 'All stages complete'
        : 'Stage $_practiceLevel of ${practiceStages.length}';
    final continueButton = FilledButton.icon(
      onPressed: allComplete
          ? null
          : () => _openStage(_practiceLevel! - 1, colors),
      style: FilledButton.styleFrom(
        backgroundColor: colors.primaryColor,
        foregroundColor: colors.isDarkMode ? Colors.black : Colors.white,
      ),
      icon: const Icon(Icons.play_arrow_rounded),
      label: const Text('Continue'),
    );

    return Container(
      margin: EdgeInsets.fromLTRB(20, horizontal ? 2 : 4, 20, horizontal ? 6 : 8),
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: horizontal ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        border: Border.all(color: colors.borderColor),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading,
                      style: TextStyle(
                        color: allComplete
                            ? colors.completedStageColor
                            : colors.primaryColor,
                        fontSize: horizontal ? 18 : 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$completed of ${practiceStages.length} stages completed',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (horizontal && !allComplete) ...[
                const SizedBox(width: 12),
                continueButton,
              ],
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: completed / practiceStages.length,
            minHeight: 6,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: colors.borderColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              colors.completedStageColor,
            ),
          ),
          if (!horizontal && !allComplete) ...[
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: continueButton),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveBanner(AppThemeColors colors) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        border: Border.all(color: colors.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _savingProgress
                  ? 'Saving Stage $_pendingPassedStage progress...'
                  : 'Stage $_pendingPassedStage passed, but progress was not saved.',
              style: TextStyle(color: colors.primaryColor),
            ),
          ),
          TextButton(
            onPressed: _savingProgress
                ? null
                : () => _savePassedStage(_pendingPassedStage!),
            child: Text(
              'Retry save',
              style: TextStyle(color: colors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStagePath(AppThemeColors colors, bool horizontal) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = horizontal && constraints.maxHeight < 150;
        return ListView(
          controller: _pathScrollController,
          scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
          padding: horizontal
              ? const EdgeInsets.symmetric(horizontal: 20, vertical: 8)
              : const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            for (var index = 0; index < practiceStages.length; index++)
              horizontal
                  ? Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _stageCard(index, colors, horizontal, compact),
                          if (index < practiceStages.length - 1)
                            Container(
                              width: 30,
                              height: 2,
                              color: _connectorColor(index, colors),
                            ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _stageCard(index, colors, horizontal, compact),
                        if (index < practiceStages.length - 1)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 34),
                              child: Container(
                                width: 2,
                                height: 24,
                                color: _connectorColor(index, colors),
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

  Color _connectorColor(int index, AppThemeColors colors) =>
      practiceStages[index].number < _practiceLevel!
      ? colors.completedStageColor.withValues(alpha: .75)
      : colors.borderColor;

  Widget _stageCard(
    int index,
    AppThemeColors colors,
    bool horizontal,
    bool compact,
  ) {
    final stage = practiceStages[index];
    final status = stage.number < _practiceLevel!
        ? PracticeStageStatus.completed
        : stage.number == _practiceLevel!
        ? PracticeStageStatus.current
        : PracticeStageStatus.locked;
    return PracticeStageCard(
      stage: stage,
      status: status,
      horizontal: horizontal,
      compact: compact,
      colors: colors,
      onTap: () => _openStage(index, colors),
    );
  }

  Future<void> _openStage(int index, AppThemeColors colors) async {
    if (_practiceLevel == null) return;
    final stage = practiceStages[index];
    final unlocked = stage.number <= _practiceLevel!;
    final completed = stage.number < _practiceLevel!;
    final rankMilestoneMessage = _rankMilestoneMessage(stage.number, completed);
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final narrow = MediaQuery.sizeOf(dialogContext).width < 390;
        final activity = practiceStageActivityLabel(stage);
        final stageStatus = !unlocked
            ? 'LOCKED'
            : completed
            ? 'COMPLETED'
            : 'CURRENT';
        final closeButton = OutlinedButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.primaryColor,
            side: BorderSide(color: colors.borderColor),
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Close'),
        );
        final startButton = FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colors.primaryColor,
            foregroundColor: colors.isDarkMode ? Colors.black : Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          child: Text(completed ? 'Replay' : 'Start'),
        );
        return Dialog(
          backgroundColor: colors.surfaceColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STAGE ${stage.number}  /  $stageStatus',
                    style: TextStyle(
                      color: completed
                          ? colors.completedStageColor
                          : colors.secondaryTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    stage.title,
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        activity == 'Video + quiz'
                            ? Icons.play_circle_outline_rounded
                            : Icons.piano_rounded,
                        size: 20,
                        color: colors.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          activity,
                          style: TextStyle(
                            color: colors.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    unlocked
                        ? stage.description
                        : 'Finish Stage ${stage.number - 1} to unlock this stage.',
                    style: TextStyle(color: colors.secondaryTextColor),
                  ),
                  if (rankMilestoneMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.completedStageSurfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.completedStageColor.withValues(alpha: .5),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.workspace_premium_outlined,
                            color: colors.completedStageColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Rank milestone',
                                  style: TextStyle(
                                    color: colors.completedStageColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  rankMilestoneMessage,
                                  style: TextStyle(color: colors.primaryColor),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (!unlocked)
                    SizedBox(width: double.infinity, child: closeButton)
                  else if (narrow)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        closeButton,
                        const SizedBox(height: 10),
                        startButton,
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(child: closeButton),
                        const SizedBox(width: 12),
                        Expanded(child: startButton),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (shouldProceed != true || !mounted) return;

    final passed = await openPracticeStage(context, stage, colors);
    if (!passed || !mounted) return;
    if (stage.number == _practiceLevel) {
      await _savePassedStage(stage.number);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stage ${stage.number} replay complete.')),
      );
    }
  }

  String? _rankMilestoneMessage(int stageNumber, bool completed) {
    final rank = _skillLevel?.toLowerCase();
    if (stageNumber == 9) {
      if (rank == 'advanced') {
        return 'You already have the Advanced rank. Completing this stage will not lower it.';
      }
      if (rank == 'intermediate') {
        return 'You already have the Intermediate rank. Completing this stage will keep it.';
      }
      return completed
          ? 'The Intermediate promotion is awarded on the first completion of this stage.'
          : 'A perfect Performance run promotes you to Intermediate once your progress is saved.';
    }
    if (stageNumber == 16) {
      if (rank == 'advanced') {
        return 'You already have the Advanced rank. Completing this stage will keep it.';
      }
      return completed
          ? 'The Advanced promotion is awarded on the first completion of this stage.'
          : 'A perfect Performance run in this final stage promotes you to Advanced once your progress is saved.';
    }
    return null;
  }

  Future<void> _savePassedStage(int stageNumber) async {
    if (_savingProgress) return;
    setState(() {
      _pendingPassedStage = stageNumber;
      _savingProgress = true;
    });
    try {
      final level = await _progressService.advanceAfterPass(stageNumber);
      if (!mounted) return;
      setState(() {
        _practiceLevel = level;
        if (stageNumber == 16) {
          _skillLevel = 'advanced';
        } else if (stageNumber == 9 && _skillLevel != 'advanced') {
          _skillLevel = 'intermediate';
        }
        _pendingPassedStage = null;
      });
      _scrollToCurrentStage();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            level == 17 ? 'All stages complete!' : 'Stage $level unlocked!',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save progress: $error')),
      );
    } finally {
      if (mounted) setState(() => _savingProgress = false);
    }
  }
}
