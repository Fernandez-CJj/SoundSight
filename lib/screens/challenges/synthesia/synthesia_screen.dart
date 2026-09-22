import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class SynthesiaScreen extends StatefulWidget {
  const SynthesiaScreen({super.key});

  @override
  State<SynthesiaScreen> createState() => _SynthesiaScreenState();
}

class _SynthesiaScreenState extends State<SynthesiaScreen> {
  late final VideoPlayerController _videoController;
  bool _videoIsReady = false;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _videoController = VideoPlayerController.asset('assets/synthesi_video.mp4');
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    await _videoController.initialize();
    await _videoController.setLooping(true);
    await _videoController.play();
    if (mounted) {
      setState(() => _videoIsReady = true);
    }
  }

  void _goBack() {
    setState(() => _canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: _videoIsReady
                  ? SizedBox.expand(
                      child: FittedBox(
                        fit: BoxFit.fill,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: _videoController.value.size.width,
                          height: _videoController.value.size.height,
                          child: VideoPlayer(_videoController),
                        ),
                      ),
                    )
                  : const SizedBox.expand(),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: _SynthesiaControlPanel(onBack: _goBack),
            ),
          ],
        ),
      ),
    );
  }
}

class _SynthesiaControlPanel extends StatelessWidget {
  const _SynthesiaControlPanel({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: Colors.black.withValues(alpha: 0.72),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelWidth = constraints.maxWidth < 940
              ? 940.0
              : constraints.maxWidth;

          return FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: panelWidth,
              height: 58,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 112,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: onBack,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 1.5),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const _PanelDivider(),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ControlButton(
                        icon: Icons.play_arrow_rounded,
                        tooltip: 'Play',
                      ),
                      _ControlButton(icon: Icons.stop_rounded, tooltip: 'Stop'),
                      _ControlButton(
                        icon: Icons.edit_note_rounded,
                        tooltip: 'Edit notes',
                      ),
                      _ControlButton(
                        icon: Icons.add_circle_outline_rounded,
                        tooltip: 'Add',
                      ),
                      SizedBox(width: 4),
                      IgnorePointer(child: _PanelSwitch()),
                    ],
                  ),
                  const _PanelDivider(),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ControlButton(
                        icon: Icons.zoom_out_rounded,
                        tooltip: 'Zoom out',
                      ),
                      _ControlButton(
                        icon: Icons.zoom_in_rounded,
                        tooltip: 'Zoom in',
                      ),
                    ],
                  ),
                  const _PanelDivider(),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ControlButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Decrease tempo',
                      ),
                      SizedBox(
                        width: 86,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '100%',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                height: 1,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Tempo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ControlButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Increase tempo',
                      ),
                    ],
                  ),
                  const _PanelDivider(),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ControlButton(icon: Icons.undo_rounded, tooltip: 'Undo'),
                      _ControlButton(icon: Icons.redo_rounded, tooltip: 'Redo'),
                      SizedBox(width: 6),
                      _ControlButton(
                        icon: Icons.folder_open_outlined,
                        tooltip: 'Open file',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PanelSwitch extends StatelessWidget {
  const _PanelSwitch();

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: false,
      onChanged: (_) {},
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackColor: const WidgetStatePropertyAll(Color(0x4DFFFFFF)),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.white),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({required this.icon, required this.tooltip});

  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      tooltip: tooltip,
      color: Colors.white,
      iconSize: 28,
      padding: const EdgeInsets.all(9),
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      icon: Icon(icon),
    );
  }
}
