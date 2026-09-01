import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
            .orderBy('stage')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load challenge items.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs.toList();

          if (items.isEmpty) {
            return Center(child: Text('No $categoryTitle available.'));
          }

          final user = FirebaseAuth.instance.currentUser;

          if (user == null) {
            return const Center(
              child: Text('Please sign in to view challenges.'),
            );
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('challenge_progress')
                .snapshots(),
            builder: (context, progressSnapshot) {
              if (progressSnapshot.hasError) {
                return const Center(
                  child: Text('Unable to load your challenge progress.'),
                );
              }

              if (!progressSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final completedItemIds = progressSnapshot.data!.docs
                  .where((document) => document.data()['completed'] == true)
                  .map((document) => document.id)
                  .toSet();

              final unlockedStages = calculateUnlockedStages(
                items,
                completedItemIds,
              );

              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final data = item.data();
                  final title = data['title'] as String? ?? 'Untitled';
                  final stage = readStage(data);
                  final isCompleted = completedItemIds.contains(item.id);
                  final isUnlocked =
                      isCompleted || unlockedStages.contains(stage);

                  late final String status;

                  if (isCompleted) {
                    status = 'Completed';
                  } else if (isUnlocked) {
                    status = 'Available';
                  } else {
                    status = 'Locked';
                  }

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : isUnlocked
                            ? Icons.music_note
                            : Icons.lock,
                        color: isCompleted
                            ? Colors.green
                            : isUnlocked
                            ? null
                            : Colors.grey,
                      ),
                      title: Text(title),
                      subtitle: Text(
                        stage == maximumStageValue
                            ? 'Stage unavailable'
                            : 'Stage $stage • $status',
                      ),
                      enabled: isUnlocked,
                      onTap: isUnlocked
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SelectedChallengeItemScreen(
                                    challengeItemId: item.id,
                                    title: title,
                                  ),
                                ),
                              );
                            }
                          : null,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static const int maximumStageValue = 2147483647;

  Set<int> calculateUnlockedStages(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> items,
    Set<String> completedItemIds,
  ) {
    final stages =
        items
            .map((item) => readStage(item.data()))
            .where((stage) => stage != maximumStageValue)
            .toSet()
            .toList()
          ..sort();

    final unlockedStages = <int>{1};

    for (final stage in stages) {
      if (stage <= 1) {
        continue;
      }

      final previousStage = stage - 1;

      final previousStageItems = items
          .where((item) => readStage(item.data()) == previousStage)
          .toList();

      if (previousStageItems.isEmpty) {
        break;
      }

      final previousStageCompleted = previousStageItems.every(
        (item) => completedItemIds.contains(item.id),
      );

      if (!previousStageCompleted) {
        break;
      }

      unlockedStages.add(stage);
    }

    return unlockedStages;
  }

  int readStage(Map<String, dynamic> data) {
    final stageValue = data['stage'];

    if (stageValue is num) {
      return stageValue.toInt();
    }

    return maximumStageValue;
  }
}
