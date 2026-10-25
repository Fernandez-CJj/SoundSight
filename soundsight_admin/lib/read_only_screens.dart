import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin_theme.dart';

String _text(dynamic value, [String fallback = 'Not available']) {
  final text = value is String ? value.trim() : '';
  return text.isEmpty ? fallback : text;
}

String _number(dynamic value) => value is num ? value.toInt().toString() : 'Not available';

DateTime? _date(dynamic value) => value is Timestamp ? value.toDate() : null;

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _search = '';
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      title: 'Users',
      description: 'Registered SoundSight players',
      searchHint: 'Search username or email',
      onSearch: (value) => setState(() => _search = value.trim().toLowerCase()),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        key: ValueKey(_generation),
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AdminMessage(
              icon: Icons.error_outline,
              message: 'Could not load users. Check your access and connection.',
              onRetry: () => setState(() => _generation++),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            return _text(data['username'], '').toLowerCase().contains(_search) ||
                _text(data['email'], '').toLowerCase().contains(_search);
          }).toList()
            ..sort((a, b) => _text(a.data()['username'])
                .toLowerCase()
                .compareTo(_text(b.data()['username']).toLowerCase()));
          if (users.isEmpty) {
            return AdminMessage(
              icon: Icons.people_outline,
              message: _search.isEmpty ? 'No users yet.' : 'No users match your search.',
            );
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data();
              final colors = AdminPalette.of(context);
              final imageUrl = _text(data['profileImageUrl'], '');
              return AdminPanel(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colors.background,
                    foregroundColor: colors.foreground,
                    backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
                    child: imageUrl.isEmpty ? const Icon(Icons.person_outline) : null,
                  ),
                  title: Text(_text(data['username'], 'Unnamed user'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(_text(data['email'])),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => _UserDetail(id: user.id, data: data),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _UserDetail extends StatelessWidget {
  const _UserDetail({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final colors = AdminPalette.of(context);
    final imageUrl = _text(data['profileImageUrl'], '');
    return _DetailDialog(
      title: _text(data['username'], 'Unnamed user'),
      subtitle: 'User profile',
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: colors.background,
            backgroundImage: imageUrl.isEmpty ? null : NetworkImage(imageUrl),
            child: imageUrl.isEmpty ? const Icon(Icons.person, size: 32) : null,
          ),
        ),
        const SizedBox(height: 16),
        _DetailField('Email', _text(data['email'])),
        _DetailField('User ID', id),
        _DetailField('Skill level', _text(data['skillLevel'])),
        _DetailField('Practice level', _number(data['practiceLevel'])),
        _DetailField('Experience points', _number(data['experiencePoints'])),
        _DetailField('Account status', _text(data['accountStatus'])),
        _DetailField('Created', adminDate(_date(data['createdAt']))),
      ],
    );
  }
}

class CompositionsScreen extends StatefulWidget {
  const CompositionsScreen({super.key});

  @override
  State<CompositionsScreen> createState() => _CompositionsScreenState();
}

class _CompositionsScreenState extends State<CompositionsScreen> {
  String _search = '';
  int _generation = 0;

  @override
  Widget build(BuildContext context) {
    return _PageLayout(
      title: 'Published compositions',
      description: 'Music published by SoundSight players',
      searchHint: 'Search title or author',
      onSearch: (value) => setState(() => _search = value.trim().toLowerCase()),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        key: ValueKey(_generation),
        stream: FirebaseFirestore.instance.collection('compositionPosts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AdminMessage(
              icon: Icons.error_outline,
              message: 'Could not load published compositions. Check your access and connection.',
              onRetry: () => setState(() => _generation++),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final posts = snapshot.data!.docs.where((doc) {
            final data = doc.data();
            return _text(data['title'], '').toLowerCase().contains(_search) ||
                _text(data['authorName'], '').toLowerCase().contains(_search);
          }).toList()
            ..sort((a, b) {
              final first = _date(a.data()['publishedAt']);
              final second = _date(b.data()['publishedAt']);
              if (first == null) return second == null ? 0 : 1;
              if (second == null) return -1;
              return second.compareTo(first);
            });
          if (posts.isEmpty) {
            return AdminMessage(
              icon: Icons.music_note_outlined,
              message: _search.isEmpty
                  ? 'No published compositions yet.'
                  : 'No compositions match your search.',
            );
          }
          return ListView.separated(
            itemCount: posts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final post = posts[index];
              final data = post.data();
              return AdminPanel(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.music_note)),
                  title: Text(_text(data['title'], 'Untitled composition'),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(
                    '${_text(data['authorName'], 'Unknown author')} · ${adminDate(_date(data['publishedAt']))}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (_) => _CompositionDetail(id: post.id, data: data),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CompositionDetail extends StatelessWidget {
  const _CompositionDetail({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;

  Future<void> _openFile(BuildContext context, String path) async {
    try {
      final url = await FirebaseStorage.instance.ref(path).getDownloadURL();
      final opened = await launchUrl(Uri.parse(url));
      if (!opened) throw StateError('Could not open file');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this file.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final version = data['versionNumber'] ?? data['currentVersion'];
    final beats = _number(data['beatsPerMeasure']);
    final beatUnit = _number(data['beatUnit']);
    final files = <(String, String)>[
      ('PDF', _text(data['pdfStoragePath'], '')),
      ('MusicXML', _text(data['musicXmlStoragePath'], '')),
      ('MIDI', _text(data['midiStoragePath'], '')),
      ('MP3', _text(data['mp3StoragePath'], '')),
    ];
    return _DetailDialog(
      title: _text(data['title'], 'Untitled composition'),
      subtitle: 'Published composition details',
      children: [
        _DetailField('Author', _text(data['authorName'])),
        _DetailField('Author ID', _text(data['ownerId'])),
        _DetailField('Post ID', id),
        _DetailField('Published', adminDate(_date(data['publishedAt']))),
        _DetailField('Version', _number(version)),
        _DetailField('Tempo', '${_number(data['tempo'])} BPM'),
        _DetailField('Key', _text(data['key'])),
        _DetailField('Time signature', '$beats/$beatUnit'),
        _DetailField('Measures', _number(data['measureCount'])),
        _DetailField('Notes', _number(data['noteCount'])),
        const SizedBox(height: 12),
        const Text('Generated files', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        for (final file in files)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(file.$1),
            subtitle: Text(file.$2.isEmpty ? 'Not available' : file.$2,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: file.$2.isEmpty
                ? null
                : OutlinedButton.icon(
                    onPressed: () => _openFile(context, file.$2),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open'),
                  ),
          ),
      ],
    );
  }
}

class _PageLayout extends StatelessWidget {
  const _PageLayout({
    required this.title,
    required this.description,
    required this.searchHint,
    required this.onSearch,
    required this.child,
  });

  final String title;
  final String description;
  final String searchHint;
  final ValueChanged<String> onSearch;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AdminPalette.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(color: colors.muted)),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.surface,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _DetailDialog extends StatelessWidget {
  const _DetailDialog({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AdminDialogFrame(
      title: title,
      subtitle: subtitle,
      maxWidth: 720,
      preferredHeight: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AdminPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: colors.muted, fontSize: 12)),
          const SizedBox(height: 3),
          SelectableText(value),
        ],
      ),
    );
  }
}
