import 'package:flutter/material.dart';

import 'challenge_items_screen.dart';

class ChallengeTypeScreen extends StatelessWidget {
  const ChallengeTypeScreen({super.key, required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Level $level')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              title: const Text('Exercises'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChallengeItemsScreen(
                      level: level,
                      category: 'exercises',
                      categoryTitle: 'Exercises',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Pieces'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChallengeItemsScreen(
                      level: level,
                      category: 'pieces',
                      categoryTitle: 'Pieces',
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
