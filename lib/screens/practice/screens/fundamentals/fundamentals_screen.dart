import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'fundamental_lessons_screen.dart';

class FundamentalScreen extends StatelessWidget {
  const FundamentalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Music Fundamentals')),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('fundamentals_folders')
            .get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load fundamentals.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final folders = snapshot.data!.docs;

          if (folders.isEmpty) {
            return const Center(child: Text('No fundamentals are available.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              final data = folder.data();
              final title = data['title'] as String? ?? folder.id;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(title),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FundamentalLessonsScreen(
                          folderId: folder.id,
                          folderTitle: title,
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
