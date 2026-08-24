import 'package:flutter/material.dart';

import 'screens/flyaway_setup_screen.dart';

/// Introduces the Flyaway feature and opens its camera setup screen.
/// This widget does not manage the camera or hand detector. Those responsibilities
/// belong to [FlyawaySetupScreen].
class FlyawayScreen extends StatelessWidget {
  const FlyawayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flyaway Finger Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analyze your finger movement',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Place your phone on a fixed mount above the piano keyboard.',
            ),
            const SizedBox(height: 12),
            const Text(
              'SoundSight can analyze one or two visible hands during practice.',
            ),
            const SizedBox(height: 12),
            const Text('Camera frames are processed live and are not saved.'),

            // Uses the remaining vertical space to keep the setup button
            // near the bottom of the screen.
            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Places the setup screen above this introduction screen.
                  // Pressing Back from setup returns the user here.
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FlyawaySetupScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Set Up Camera'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
