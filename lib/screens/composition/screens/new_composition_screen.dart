import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/composition/models/composition.dart';
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
            'New Composition',
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
                      'Create your piano piece',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.sectionTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(AppSpacing.xs),
                    Text(
                      'Choose the starting title, key, tempo, and meter. You can '
                      'change them later in the composition workspace.',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Composition Title',
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
                        hintText: 'Example: My First Song',
                        prefixIcon: Icons.music_note_rounded,
                      ),
                      validator: (value) {
                        final title = value?.trim() ?? '';

                        if (title.isEmpty) {
                          return 'Enter a composition title.';
                        }

                        if (title.length > 80) {
                          return 'The title must be 80 characters or fewer.';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
                Gap(AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tempo',
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Gap(AppSpacing.xs),
                    Text(
                      'A lower BPM sounds slower. A higher BPM sounds faster.',
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
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      cursorColor: colors.primaryColor,
                      style: TextStyle(
                        color: colors.primaryColor,
                        fontSize: AppTextSizes.body,
                      ),
                      decoration: buildInputDecoration(
                        colors: colors,
                        hintText: '40 to 200',
                        prefixIcon: Icons.speed_rounded,
                        suffixText: 'BPM',
                      ),
                      validator: (value) {
                        final tempo = int.tryParse(value ?? '');

                        if (tempo == null) {
                          return 'Enter a valid tempo.';
                        }

                        if (tempo < 40 || tempo > 200) {
                          return 'Tempo must be between 40 and 200 BPM.';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
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
                        'Composition Settings',
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.label,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Gap(AppSpacing.xs),
                      Text(
                        'Set the musical structure for this piece.',
                        style: TextStyle(
                          color: colors.secondaryTextColor,
                          fontSize: AppTextSizes.caption,
                        ),
                      ),
                      Gap(AppSpacing.md),
                      Text(
                        'Key Signature',
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
                          hintText: 'Key Signature',
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
                        'Time Signature',
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
                          hintText: 'Time Signature',
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
                  isOpeningEditor ? 'Opening Editor...' : 'Start Composing',
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

  Widget buildCompositionMethodDialog(BuildContext dialogContext) {
    final colors = widget.colors;

    return Dialog(
      backgroundColor: colors.surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: colors.borderColor),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.backgroundColor,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: colors.borderColor),
                  ),
                  child: Icon(
                    Icons.library_music_rounded,
                    color: colors.primaryColor,
                    size: AppIconSizes.md,
                  ),
                ),
                Gap(AppSpacing.md),
                Expanded(
                  child: Text(
                    'Choose how to compose',
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.sectionTitle,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Gap(AppSpacing.lg),
            Material(
              color: colors.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: colors.borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.of(dialogContext).pop(_CompositionMethod.manual);
                },
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colors.surfaceColor,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Icon(
                          Icons.edit_note_rounded,
                          color: colors.primaryColor,
                          size: AppIconSizes.md,
                        ),
                      ),
                      Gap(AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Compose Manually',
                          style: TextStyle(
                            color: colors.primaryColor,
                            fontSize: AppTextSizes.label,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Gap(AppSpacing.sm),
            Material(
              color: colors.backgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                side: BorderSide(color: colors.borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  Navigator.of(dialogContext).pop(_CompositionMethod.recording);
                },
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: colors.surfaceColor,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: colors.borderColor),
                        ),
                        child: Icon(
                          Icons.videocam_rounded,
                          color: colors.primaryColor,
                          size: AppIconSizes.md,
                        ),
                      ),
                      Gap(AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Record Performance',
                          style: TextStyle(
                            color: colors.primaryColor,
                            fontSize: AppTextSizes.label,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colors.secondaryTextColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> startComposing() async {
    if (isOpeningEditor || formKey.currentState?.validate() != true) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      showMessage('Sign in before creating a composition.');
      return;
    }

    final compositionMethod = await showDialog<_CompositionMethod>(
      context: context,
      builder: buildCompositionMethodDialog,
    );

    if (!mounted || compositionMethod == null) {
      return;
    }

    final composition = Composition(
      id: '',
      ownerId: user.uid,
      title: titleController.text.trim(),
      tempo: int.parse(tempoController.text),
      measureCount: 1,
      notes: [],
      creationMethod: compositionMethod == _CompositionMethod.recording
          ? Composition.recordingCreationMethod
          : Composition.manualCreationMethod,
      keySignature: selectedKeySignature,
      beatsPerMeasure: int.parse(selectedTimeSignature.split('/').first),
      beatUnit: int.parse(selectedTimeSignature.split('/').last),
    );

    if (compositionMethod == _CompositionMethod.recording) {
      final savedCompositionId = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => RecordCompositionScreen(
            colors: widget.colors,
            composition: composition,
          ),
        ),
      );

      if (!mounted || savedCompositionId == null) {
        return;
      }

      Navigator.pop(context, savedCompositionId);

      return;
    }

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
