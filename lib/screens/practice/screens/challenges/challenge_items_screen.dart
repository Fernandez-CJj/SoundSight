import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'selected_challenge_item_screen.dart';

class ChallengeItemsScreen extends StatelessWidget {
  const ChallengeItemsScreen({
    super.key,
    required this.level,
    required this.category,
    required this.categoryTitle,
  });

  final int level;
  final String category;
  final String categoryTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Level $level $categoryTitle')),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('challenge_items')
            .where('level', isEqualTo: level)
            .where('category', isEqualTo: category)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load challenge items.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs.toList();

          items.sort((firstItem, secondItem) {
            final firstStage = readStage(firstItem.data());
            final secondStage = readStage(secondItem.data());
            final stageComparison = firstStage.compareTo(secondStage);

            if (stageComparison != 0) {
              return stageComparison;
            }

            final firstTitle =
                firstItem.data()['title'] as String? ?? 'Untitled';
            final secondTitle =
                secondItem.data()['title'] as String? ?? 'Untitled';

            return firstTitle.toLowerCase().compareTo(
              secondTitle.toLowerCase(),
            );
          });

          if (items.isEmpty) {
            return Center(child: Text('No $categoryTitle available.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final data = item.data();
              final title = data['title'] as String? ?? 'Untitled';
              final stage = readStage(data);

              return Card(
                child: ListTile(
                  title: Text(title),
                  subtitle: Text(
                    stage == maximumStageValue
                        ? 'Stage unavailable'
                        : 'Stage $stage',
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SelectedChallengeItemScreen(
                          challengeItemId: item.id,
                          title: title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  static const int maximumStageValue = 2147483647;

  int readStage(Map<String, dynamic> data) {
    final stageValue = data['stage'];

    if (stageValue is num) {
      return stageValue.toInt();
    }

    return maximumStageValue;
  }
}
