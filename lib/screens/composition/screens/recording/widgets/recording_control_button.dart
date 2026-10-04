import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';

class RecordingControlButton extends StatelessWidget {
  const RecordingControlButton({
    super.key,
    required this.isRecording,
    required this.midiIsConnected,
    required this.cameraIsReady,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onMidiRequired,
  });

  final bool isRecording;
  final bool midiIsConnected;
  final bool cameraIsReady;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onMidiRequired;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.lg,
      child: Center(
        child: IconButton.filled(
          onPressed: isRecording
              ? onStopRecording
              : !midiIsConnected
              ? onMidiRequired
              : cameraIsReady
              ? onStartRecording
              : null,
          tooltip: isRecording
              ? 'Stop recording'
              : midiIsConnected
              ? 'Start recording'
              : 'Connect MIDI to start',
          style: IconButton.styleFrom(
            backgroundColor: isRecording
                ? Colors.red.shade700
                : Colors.white,
            foregroundColor: isRecording ? Colors.white : Colors.black,
            disabledBackgroundColor: Colors.white24,
            disabledForegroundColor: Colors.white38,
            minimumSize: const Size(72, 72),
          ),
          icon: Icon(
            isRecording ? Icons.stop_rounded : Icons.play_arrow_rounded,
            size: 38,
          ),
        ),
      ),
    );
  }
}
