import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'challenge_type_screen.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Levels')),
      body: FutureBuilder<String>(
        future: loadCurrentSkillLevel(),
        builder: (context, skillSnapshot) {
          if (skillSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (skillSnapshot.hasError) {
            return const Center(
              child: Text('Unable to load your skill level.'),
            );
          }

          final skillLevel = skillSnapshot.data ?? 'beginner';

          return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('challenge_levels')
                .get(),
            builder: (context, levelSnapshot) {
              if (levelSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (levelSnapshot.hasError) {
                return const Center(
                  child: Text('Unable to load challenge levels.'),
                );
              }

              final levelDocuments = levelSnapshot.data?.docs ?? [];

              if (levelDocuments.isEmpty) {
                return const Center(child: Text('No challenge levels found.'));
              }

              levelDocuments.sort((firstDocument, secondDocument) {
                final firstLevel = firstDocument.data()['level'] as int? ?? 0;

                final secondLevel = secondDocument.data()['level'] as int? ?? 0;

                return firstLevel.compareTo(secondLevel);
              });

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: levelDocuments.length,
                itemBuilder: (context, index) {
                  final levelData = levelDocuments[index].data();

                  final level = levelData['level'] as int? ?? index + 1;

                  final isUnlocked = canAccessLevel(skillLevel, level);

                  final requiredSkill = getRequiredSkill(level);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: isUnlocked
                        ? null
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      leading: CircleAvatar(
                        child: isUnlocked
                            ? Text('$level')
                            : const Icon(Icons.lock),
                      ),
                      title: Text(
                        'Level $level',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? null : Colors.grey,
                        ),
                      ),
                      subtitle: Text(
                        isUnlocked
                            ? 'Tap to view the challenges'
                            : 'Reach $requiredSkill to unlock',
                      ),
                      trailing: Icon(
                        isUnlocked
                            ? Icons.arrow_forward_ios
                            : Icons.lock_outline,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                      onTap: () {
                        if (!isUnlocked) {
                          final messenger = ScaffoldMessenger.of(context);

                          messenger.clearSnackBars();

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Reach $requiredSkill skill level to unlock Level $level.',
                              ),
                            ),
                          );

                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ChallengeTypeScreen(level: level),
                          ),
                        );
                      },
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

  Future<String> loadCurrentSkillLevel() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return 'beginner';
    }

    final userDocument = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final skillLevel = userDocument.data()?['skillLevel'];

    if (skillLevel is String) {
      return skillLevel.toLowerCase();
    }

    return 'beginner';
  }

  bool canAccessLevel(String skillLevel, int level) {
    if (skillLevel == 'intermediate') {
      return level <= 3;
    } else if (skillLevel == 'advanced') {
      return true;
    } else if (skillLevel == 'beginner') {
      return level == 1;
    } else {
      return level == 1;
    }
  }

  String getRequiredSkill(int level) {
    if (level == 1) {
      return 'Beginner';
    }

    if (level <= 3) {
      return 'Intermediate';
    }

    return 'Advanced';
  }
}
