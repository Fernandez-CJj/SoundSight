import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';

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
          tooltip: 'Switch camera',
          color: Colors.white,
          disabledColor: Colors.white38,
          icon: const Icon(Icons.cameraswitch_rounded),
        ),
      ),
    );
  }
}
