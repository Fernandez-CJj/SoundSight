import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';

class MidiConnectionButton extends StatelessWidget {
  const MidiConnectionButton({
    super.key,
    required this.status,
    required this.isConnecting,
    required this.isConnected,
    required this.isRecording,
    required this.onConnect,
  });

  final String status;
  final bool isConnecting;
  final bool isConnected;
  final bool isRecording;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Widget icon;
    late final Color color;

    if (isConnecting) {
      label = 'Connecting';
      color = Colors.white70;
      icon = SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    } else if (isConnected) {
      label = 'Connected';
      color = Colors.greenAccent.shade400;
      icon = const Icon(
        Icons.check_circle_rounded,
        size: AppIconSizes.sm,
      );
    } else {
      label = 'Connect MIDI';
      color = Colors.white;
      icon = const Icon(
        Icons.usb_rounded,
        size: AppIconSizes.sm,
      );
    }

    return Positioned(
      top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
      right: AppSpacing.md,
      child: Tooltip(
        message: status,
        child: OutlinedButton.icon(
          onPressed: isConnecting || isConnected || isRecording
              ? null
              : onConnect,
          icon: icon,
          label: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            disabledForegroundColor: color,
            backgroundColor: Colors.black54,
            disabledBackgroundColor: Colors.black54,
            minimumSize: const Size(116, 46),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            side: BorderSide(
              color: color.withValues(alpha: 0.75),
              width: 1.25,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
          ),
        ),
      ),
    );
  }
}
