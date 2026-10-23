import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';

class CameraSwitchButton extends StatelessWidget {
  const CameraSwitchButton({
    super.key,
    required this.isRecording,
    required this.onSwitch,
  });

  final bool isRecording;
  final VoidCallback onSwitch;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: AppSpacing.md,
      bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.xl,
      child: Material(
        color: Colors.black54,
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: isRecording ? null : onSwitch,
          tooltip: context.l10n.switchCamera,
          color: Colors.white,
          disabledColor: Colors.white38,
          icon: const Icon(Icons.cameraswitch_rounded),
        ),
      ),
    );
  }
}
