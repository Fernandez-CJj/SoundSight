import 'package:flutter/material.dart';

import 'screens/flyaway_practice_test_screen.dart';

/// Introduces the standalone Flyaway practice prototype.
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
            const Text('Camera frames and session results are not saved.'),
            const SizedBox(height: 12),
            const Text(
              'Flyaway estimates excessive finger lift. It does not measure '
              'distance from the piano keys.',
            ),

            // Uses the remaining vertical space to keep the setup button
            // near the bottom of the screen.
            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FlyawayPracticeTestScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Open practice test'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
