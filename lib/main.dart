import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'midi_editor/presentation/screens/midi_editor_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const SoundSightApp());
}

class SoundSightApp extends StatelessWidget {
  const SoundSightApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF00A3A3),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: 'SoundSight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF111315),
        appBarTheme: const AppBarTheme(centerTitle: false),
        sliderTheme: SliderThemeData(
          showValueIndicator: ShowValueIndicator.onDrag,
          activeTrackColor: scheme.primary,
        ),
      ),
      home: const MidiEditorScreen(),
    );
  }
}
