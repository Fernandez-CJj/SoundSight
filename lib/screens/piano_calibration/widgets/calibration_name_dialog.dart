import 'package:flutter/material.dart';

/// Dialog that validates and returns a user-friendly calibration name.
class CalibrationNameDialog extends StatefulWidget {
  const CalibrationNameDialog({super.key, this.initialName});

  /// Existing name shown when an already saved calibration is edited.
  final String? initialName;

  @override
  /// Creates text-entry state owned for the dialog's lifetime.
  State<CalibrationNameDialog> createState() {
    return CalibrationNameDialogState();
  }
}

/// Owns the name controller and inline validation message.
class CalibrationNameDialogState extends State<CalibrationNameDialog> {
  late final TextEditingController nameController;

  String? nameError;

  @override
  /// Seeds the field with the existing name when one was supplied.
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  /// Builds the name field and cancel/save actions.
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Name this calibration'),
      content: TextField(
        controller: nameController,
        autofocus: true,
        maxLength: 50,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: 'Calibration name',
          hintText: 'Example: Bedroom Piano',
          errorText: nameError,
        ),
        onChanged: (String value) {
          if (nameError == null) {
            return;
          }

          setState(() {
            nameError = null;
          });
        },
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: saveName, child: const Text('Save')),
      ],
    );
  }

  /// Trims and validates the name before returning it to the caller.
  void saveName() {
    String calibrationName = nameController.text.trim();

    if (calibrationName.isEmpty) {
      setState(() {
        nameError = 'Enter a name for this calibration.';
      });

      return;
    }

    Navigator.of(context).pop(calibrationName);
  }

  @override
  /// Releases the text controller when the dialog is removed.
  void dispose() {
    nameController.dispose();
    super.dispose();
  }
}
