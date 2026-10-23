import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/composition/models/composition_options.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class CompositionSettings {
  const CompositionSettings({
    required this.title,
    required this.tempo,
    required this.keySignature,
    required this.beatsPerMeasure,
    required this.beatUnit,
  });

  final String title;
  final int tempo;
  final String keySignature;
  final int beatsPerMeasure;
  final int beatUnit;
}

class CompositionSettingsDialog extends StatefulWidget {
  const CompositionSettingsDialog({
    super.key,
    required this.colors,
    required this.title,
    required this.tempo,
    required this.keySignature,
    required this.beatsPerMeasure,
    required this.beatUnit,
  });

  final AppThemeColors colors;
  final String title;
  final int tempo;
  final String keySignature;
  final int beatsPerMeasure;
  final int beatUnit;

  @override
  State<CompositionSettingsDialog> createState() {
    return _CompositionSettingsDialogState();
  }
}

class _CompositionSettingsDialogState
    extends State<CompositionSettingsDialog> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController titleController;
  late final TextEditingController tempoController;
  late String selectedKey;
  late String selectedTimeSignature;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.title);
    tempoController = TextEditingController(text: '${widget.tempo}');
    selectedKey = compositionKeySignatures.contains(widget.keySignature)
        ? widget.keySignature
        : 'C Major';
    final incomingTimeSignature =
        '${widget.beatsPerMeasure}/${widget.beatUnit}';
    selectedTimeSignature = compositionTimeSignatures.contains(
      incomingTimeSignature,
    )
        ? incomingTimeSignature
        : '4/4';
  }

  @override
  void dispose() {
    titleController.dispose();
    tempoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return AlertDialog(
      backgroundColor: colors.surfaceColor,
      title: Text(
        context.l10n.compositionSettings,
        style: TextStyle(color: colors.primaryColor),
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(color: colors.primaryColor),
                  decoration: buildDecoration(context.l10n.compositionTitle),
                  validator: (value) {
                    final title = value?.trim() ?? '';
                    if (title.isEmpty) {
                      return context.l10n.compositionTitleRequired;
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.sm),
                TextFormField(
                  controller: tempoController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: TextStyle(color: colors.primaryColor),
                  decoration: buildDecoration(context.l10n.tempo),
                  validator: (value) {
                    final tempo = int.tryParse(value ?? '');
                    if (tempo == null || tempo < 40 || tempo > 200) {
                      return context.l10n.tempoRangeError;
                    }
                    return null;
                  },
                ),
                const Gap(AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedKey,
                  isExpanded: true,
                  dropdownColor: colors.surfaceColor,
                  style: TextStyle(color: colors.primaryColor),
                  decoration: buildDecoration(context.l10n.keySignature),
                  items: compositionKeySignatures.map((key) {
                    return DropdownMenuItem(value: key, child: Text(key));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => selectedKey = value);
                  },
                ),
                const Gap(AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: selectedTimeSignature,
                  isExpanded: true,
                  dropdownColor: colors.surfaceColor,
                  style: TextStyle(color: colors.primaryColor),
                  decoration: buildDecoration(context.l10n.timeSignature),
                  items: compositionTimeSignatures.map((timeSignature) {
                    return DropdownMenuItem(
                      value: timeSignature,
                      child: Text(timeSignature),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedTimeSignature = value);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            context.l10n.cancel,
            style: TextStyle(color: colors.secondaryTextColor),
          ),
        ),
        FilledButton(
          onPressed: save,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primaryColor,
            foregroundColor: colors.backgroundColor,
          ),
          child: Text(context.l10n.apply),
        ),
      ],
    );
  }

  InputDecoration buildDecoration(String label) {
    final colors = widget.colors;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: colors.secondaryTextColor),
      counterStyle: TextStyle(color: colors.secondaryTextColor),
      filled: true,
      fillColor: colors.backgroundColor,
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
        borderSide: BorderSide(color: colors.primaryColor),
      ),
    );
  }

  void save() {
    if (formKey.currentState?.validate() != true) return;

    Navigator.pop(
      context,
      CompositionSettings(
        title: titleController.text.trim(),
        tempo: int.parse(tempoController.text),
        keySignature: selectedKey,
        beatsPerMeasure: beatsFromTimeSignature(selectedTimeSignature),
        beatUnit: beatUnitFromTimeSignature(selectedTimeSignature),
      ),
    );
  }
}
