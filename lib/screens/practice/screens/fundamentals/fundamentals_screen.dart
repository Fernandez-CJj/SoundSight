import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'fundamental_exercise_screen.dart';
import 'selected_fundamental_lesson_screen.dart';

class FundamentalScreen extends StatelessWidget {
  const FundamentalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Fundamentals')),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('fundamentals_folders')
            .doc('fundamentals')
            .collection('lessons')
            .orderBy('title')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load fundamentals.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data!.docs;

          if (items.isEmpty) {
            return const Center(child: Text('No fundamentals are available.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final data = item.data();
              final title = data['title'] as String? ?? item.id;
              final type = data['type'] as String?;
              final isLesson = type == 'lesson';
              final isExercise = type == 'exercise';

              return Card(
                child: ListTile(
                  leading: Icon(
                    isLesson
                        ? Icons.menu_book_outlined
                        : isExercise
                        ? Icons.music_note_outlined
                        : Icons.help_outline,
                  ),
                  title: Text(title),
                  subtitle: Text(
                    isLesson
                        ? 'Lesson'
                        : isExercise
                        ? 'Exercise'
                        : 'Unsupported item',
                  ),
                  onTap: () {
                    if (!isLesson && !isExercise) {
                      return;
                    }

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => isLesson
                            ? SelectedFundamentalLessonScreen(
                                title: title,
                                slides: _slidesFrom(data['slides']),
                              )
                            : FundamentalExerciseScreen(
                                title: title,
                                scoreDocumentPath:
                                    'fundamentals_folders/fundamentals/lessons/${item.id}',
                                pdfUrl: data['pdfUrl'] as String? ?? '',
                                pdfFileName:
                                    data['pdfFileName'] as String? ?? '',
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

  static List<Map<String, dynamic>> _slidesFrom(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((slide) => Map<String, dynamic>.from(slide))
        .toList(growable: false);
  }
}
