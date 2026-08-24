import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'selected_fundamental_lesson_screen.dart';

class FundamentalLessonsScreen extends StatelessWidget {
  const FundamentalLessonsScreen({
    super.key,
    required this.folderId,
    required this.folderTitle,
  });

  final String folderId;
  final String folderTitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(folderTitle)),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('fundamentals_folders')
            .doc(folderId)
            .collection('lessons')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load lessons.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final lessons = snapshot.data!.docs;

          if (lessons.isEmpty) {
            return const Center(child: Text('No lessons are available.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lessons.length,
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              final data = lesson.data();
              final title = data['title'] as String? ?? lesson.id;

              return Card(
                child: ListTile(
                  title: Text(title),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            SelectedFundamentalLessonScreen(
                              folderId: folderId,
                              lessonId: lesson.id,
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
}
