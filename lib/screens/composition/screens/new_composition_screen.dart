import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/models/recording_composition_draft.dart';
import 'package:soundsight/screens/composition/screens/manual/composition_editor_screen.dart';
import 'package:soundsight/screens/composition/models/composition_options.dart';
import 'package:soundsight/screens/composition/screens/recording/record_composition_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class NewCompositionScreen extends StatefulWidget {
  const NewCompositionScreen({super.key, required this.colors});

  final AppThemeColors colors;

  @override
  State<NewCompositionScreen> createState() => _NewCompositionScreenState();
}

class _NewCompositionScreenState extends State<NewCompositionScreen> {
  static const keySignatures = compositionKeySignatures;
  static const timeSignatures = compositionTimeSignatures;

  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  final tempoController = TextEditingController(text: '80');

  String selectedKeySignature = 'C Major';
  String selectedTimeSignature = '4/4';
  _CompositionMethod selectedMethod = _CompositionMethod.manual;
  bool isOpeningEditor = false;

  @override
  void dispose() {
    titleController.dispose();
    tempoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return PopScope(
      canPop: !isOpeningEditor,
      child: Scaffold(
        backgroundColor: colors.backgroundColor,
        appBar: AppBar(
          backgroundColor: colors.backgroundColor,
          foregroundColor: colors.primaryColor,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            context.l10n.newComposition,
            style: TextStyle(
              fontSize: AppTextSizes.sectionTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                AppSpacing.xl,
              ),
              children: [
                Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: colors.surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.borderColor),
                      ),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: colors.primaryColor,
                        size: AppIconSizes.xl,
                      ),
                    ),
                    Gap(AppSpacing.md),
                    Text(
                      context.l10n.createYourPianoPiece,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.sectionTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(AppSpacing.xs),
                    Text(
                      selectedMethod == _CompositionMethod.recording
                          ? context.l10n.newCompositionRecordingDescription
                          : context.l10n.newCompositionManualDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.label,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                Gap(AppSpacing.xl),
                Container(
                  padding: EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: colors.surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: SegmentedButton<_CompositionMethod>(
                    segments: [
                      ButtonSegment(
                        value: _CompositionMethod.manual,
                        icon: const Icon(Icons.edit_note_rounded),
                        label: Text(context.l10n.manual),
                      ),
                      ButtonSegment(
                        value: _CompositionMethod.recording,
                        icon: const Icon(Icons.videocam_rounded),
                        label: Text(context.l10n.recording),
                      ),
                    ],
                    selected: {selectedMethod},
                    onSelectionChanged: isOpeningEditor
                        ? null
                        : (selection) {
                            setState(() {
                              selectedMethod = selection.first;
                            });
                          },
                    style: ButtonStyle(
                      foregroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? colors.backgroundColor
                            : colors.primaryColor,
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? colors.primaryColor
                            : colors.surfaceColor,
                      ),
                    ),
                  ),
                ),
                Gap(AppSpacing.xl),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.compositionTitle,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(AppSpacing.sm),
                    TextFormField(
                      controller: titleController,
                      enabled: !isOpeningEditor,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      maxLength: 80,
                      cursorColor: colors.primaryColor,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.body,
                      ),
                      decoration: buildInputDecoration(
                        colors: colors,
                        hintText: context.l10n.compositionTitleHint,
                        prefixIcon: Icons.music_note_rounded,
                      ),
                      validator: (value) {
                        final title = value?.trim() ?? '';

                        if (title.isEmpty) {
                          return context.l10n.compositionTitleRequired;
                        }

                        if (title.length > 80) {
                          return context.l10n.compositionTitleTooLong;
                        }

                        return null;
                      },
                    ),
                  ],
                ),
                if (selectedMethod == _CompositionMethod.manual) ...[
                  Gap(AppSpacing.md),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.tempo,
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.label,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Gap(AppSpacing.xs),
                      Text(
                        context.l10n.tempoDescription,
                        style: TextStyle(
                          color: colors.secondaryTextColor,
                          fontSize: AppTextSizes.caption,
                        ),
                      ),
                      Gap(AppSpacing.sm),
                      TextFormField(
                        controller: tempoController,
                        enabled: !isOpeningEditor,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        cursorColor: colors.primaryColor,
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.body,
                        ),
                        decoration: buildInputDecoration(
                          colors: colors,
                          hintText: context.l10n.tempoRangeHint,
                          prefixIcon: Icons.speed_rounded,
                          suffixText: 'BPM',
                        ),
                        validator: (value) {
                          if (selectedMethod != _CompositionMethod.manual) {
                            return null;
                          }
                          final tempo = int.tryParse(value ?? '');

                          if (tempo == null) {
                            return context.l10n.validTempoRequired;
                          }

                          if (tempo < 40 || tempo > 200) {
                            return context.l10n.tempoRangeError;
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  Gap(AppSpacing.md),
                  Container(
                    padding: EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surfaceColor,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colors.borderColor),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: colors.primaryColor,
                        ),
                        Gap(AppSpacing.sm),
                        Expanded(
                          child: Text(
                            context.l10n.detectedTempoDescription,
                            style: TextStyle(
                              color: colors.secondaryTextColor,
                              fontSize: AppTextSizes.caption,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                Gap(AppSpacing.xl),
                Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.compositionSettings,
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.label,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Gap(AppSpacing.xs),
                      Text(
                        context.l10n.compositionSettingsDescription,
                        style: TextStyle(
                          color: colors.secondaryTextColor,
                          fontSize: AppTextSizes.caption,
                        ),
                      ),
                      Gap(AppSpacing.md),
                      Text(
                        context.l10n.keySignature,
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.label,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Gap(AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: selectedKeySignature,
                        isExpanded: true,
                        dropdownColor: colors.surfaceColor,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colors.secondaryTextColor,
                        ),
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.body,
                        ),
                        decoration: buildInputDecoration(
                          colors: colors,
                          hintText: context.l10n.keySignature,
                          prefixIcon: Icons.music_note_rounded,
                        ),
                        items: keySignatures.map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: isOpeningEditor
                            ? null
                            : (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedKeySignature = newValue;
                                  });
                                }
                              },
                      ),
                      Gap(AppSpacing.md),
                      Text(
                        context.l10n.timeSignature,
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.label,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Gap(AppSpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: selectedTimeSignature,
                        isExpanded: true,
                        dropdownColor: colors.surfaceColor,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: colors.secondaryTextColor,
                        ),
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.body,
                        ),
                        decoration: buildInputDecoration(
                          colors: colors,
                          hintText: context.l10n.timeSignature,
                          prefixIcon: Icons.grid_view_rounded,
                        ),
                        items: timeSignatures.map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: isOpeningEditor
                            ? null
                            : (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedTimeSignature = newValue;
                                  });
                                }
                              },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.backgroundColor,
              border: Border(top: BorderSide(color: colors.borderColor)),
            ),
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isOpeningEditor ? null : startComposing,
                icon: isOpeningEditor
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colors.backgroundColor,
                        ),
                      )
                    : Icon(Icons.edit_note_rounded),
                label: Text(
                  isOpeningEditor
                      ? context.l10n.opening
                      : selectedMethod == _CompositionMethod.recording
                      ? context.l10n.openRecorder
                      : context.l10n.startComposing,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryColor,
                  foregroundColor: colors.backgroundColor,
                  disabledBackgroundColor: colors.primaryColor,
                  disabledForegroundColor: colors.backgroundColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration buildInputDecoration({
    required AppThemeColors colors,
    required String hintText,
    required IconData prefixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: colors.surfaceColor,
      hintText: hintText,
      hintStyle: TextStyle(
        color: colors.secondaryTextColor,
        fontSize: AppTextSizes.body,
      ),
      prefixIcon: Icon(prefixIcon, color: colors.secondaryTextColor),
      suffixText: suffixText,
      suffixStyle: TextStyle(
        color: colors.secondaryTextColor,
        fontWeight: FontWeight.w600,
      ),
      counterStyle: TextStyle(color: colors.secondaryTextColor),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: colors.borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: colors.borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: colors.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: colors.primaryColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: colors.primaryColor, width: 1.5),
      ),
    );
  }

  Future<void> startComposing() async {
    if (isOpeningEditor || formKey.currentState?.validate() != true) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage(context.l10n.signInBeforeCreatingComposition);
      return;
    }

    final beatsPerMeasure = int.parse(selectedTimeSignature.split('/').first);
    final beatUnit = int.parse(selectedTimeSignature.split('/').last);

    if (selectedMethod == _CompositionMethod.recording) {
      final draft = RecordingCompositionDraft(
        ownerId: user.uid,
        title: titleController.text.trim(),
        keySignature: selectedKeySignature,
        beatsPerMeasure: beatsPerMeasure,
        beatUnit: beatUnit,
      );
      final savedCompositionId = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) =>
              RecordCompositionScreen(colors: widget.colors, draft: draft),
        ),
      );

      if (!mounted || savedCompositionId == null) {
        return;
      }

      Navigator.pop(context, savedCompositionId);
      return;
    }

    final composition = Composition(
      id: '',
      ownerId: user.uid,
      title: titleController.text.trim(),
      tempo: int.parse(tempoController.text),
      measureCount: 1,
      notes: [],
      creationMethod: Composition.manualCreationMethod,
      keySignature: selectedKeySignature,
      beatsPerMeasure: beatsPerMeasure,
      beatUnit: beatUnit,
    );

    setState(() {
      isOpeningEditor = true;
    });

    String? savedCompositionId;

    try {
      savedCompositionId = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => CompositionEditorScreen(
            colors: widget.colors,
            composition: composition,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isOpeningEditor = false;
        });
      }
    }

    if (!mounted || savedCompositionId == null) {
      return;
    }

    Navigator.pop(context, savedCompositionId);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _CompositionMethod { manual, recording }
