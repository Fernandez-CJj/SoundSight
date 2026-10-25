import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'admin_theme.dart';

String _fileName(String location) {
  final uri = Uri.tryParse(location);
  final lastSegment = uri != null && uri.hasScheme
      ? uri.pathSegments.last
      : location.split('/').last;
  return Uri.decodeComponent(lastSegment).split('/').last;
}

enum PieceFileKind { musicXml, pdf, mp3, midi }

extension PieceFileKindDetails on PieceFileKind {
  String get label => switch (this) {
    PieceFileKind.musicXml => 'MusicXML',
    PieceFileKind.pdf => 'PDF',
    PieceFileKind.mp3 => 'MP3',
    PieceFileKind.midi => 'MIDI',
  };

  String get field => switch (this) {
    PieceFileKind.musicXml => 'musicXmlStoragePath',
    PieceFileKind.pdf => 'pdfStoragePath',
    PieceFileKind.mp3 => 'mp3StoragePath',
    PieceFileKind.midi => 'midiStoragePath',
  };

  String get legacyUrlField => switch (this) {
    PieceFileKind.musicXml => 'musicXmlUrl',
    PieceFileKind.pdf => 'pdfUrl',
    PieceFileKind.mp3 => 'mp3Url',
    PieceFileKind.midi => 'midiUrl',
  };

  List<String> get extensions => switch (this) {
    PieceFileKind.musicXml => ['xml', 'musicxml'],
    PieceFileKind.pdf => ['pdf'],
    PieceFileKind.mp3 => ['mp3'],
    PieceFileKind.midi => ['mid', 'midi'],
  };

  String get contentType => switch (this) {
    PieceFileKind.musicXml => 'application/vnd.recordare.musicxml+xml',
    PieceFileKind.pdf => 'application/pdf',
    PieceFileKind.mp3 => 'audio/mpeg',
    PieceFileKind.midi => 'audio/midi',
  };
}

class MusicPiece {
  const MusicPiece({
    required this.id,
    required this.title,
    required this.paths,
    required this.legacyUrls,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final Map<PieceFileKind, String> paths;
  final Map<PieceFileKind, String> legacyUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String fileLocation(PieceFileKind kind) {
    final path = paths[kind] ?? '';
    return path.isNotEmpty ? path : legacyUrls[kind] ?? '';
  }

  factory MusicPiece.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return MusicPiece(
      id: doc.id,
      title: (data['title'] as String?)?.trim().isNotEmpty == true
          ? (data['title'] as String).trim()
          : 'Untitled piece',
      paths: {
        for (final kind in PieceFileKind.values)
          kind: (data[kind.field] as String?) ?? '',
      },
      legacyUrls: {
        for (final kind in PieceFileKind.values)
          kind: (data[kind.legacyUrlField] as String?) ?? '',
      },
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class PieceRepository {
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  Reference _referenceFor(String location) {
    final scheme = Uri.tryParse(location)?.scheme;
    if (scheme == 'gs' || scheme == 'http' || scheme == 'https') {
      return _storage.refFromURL(location);
    }
    return _storage.ref(location);
  }

  Future<String> downloadUrl(String location) {
    return _referenceFor(location).getDownloadURL();
  }

  Future<int> save({
    required String title,
    required Map<PieceFileKind, PlatformFile> selectedFiles,
    required void Function(double progress, String activity) onProgress,
    required void Function(PieceFileKind kind) onFileUploaded,
    MusicPiece? existing,
  }) async {
    final document = _firestore
        .collection('available_pieces')
        .doc(existing?.id);
    final paths = <PieceFileKind, String>{
      for (final kind in PieceFileKind.values)
        kind: existing?.paths[kind] ?? '',
    };
    final newPaths = <String>[];
    final oldPaths = <String>[];
    var saved = false;
    try {
      var completed = 0;
      for (final kind in PieceFileKind.values) {
        final file = selectedFiles[kind];
        if (file == null) continue;
        final bytes = await file.readAsBytes();
        if (bytes.isEmpty) {
          throw StateError('${kind.label} file could not be read.');
        }
        final extension = file.name.split('.').last.toLowerCase();
        final path =
            'pieces/${document.id}/'
            '${DateTime.now().microsecondsSinceEpoch}_${kind.name}.$extension';
        final reference = _storage.ref(path);
        newPaths.add(path);
        onProgress(
          completed / selectedFiles.length,
          'Uploading ${kind.label}…',
        );
        final task = reference.putData(
          bytes,
          SettableMetadata(contentType: kind.contentType),
        );
        final subscription = task.snapshotEvents.listen((snapshot) {
          if (snapshot.totalBytes > 0) {
            onProgress(
              (completed + snapshot.bytesTransferred / snapshot.totalBytes) /
                  selectedFiles.length,
              'Uploading ${kind.label}…',
            );
          }
        });
        try {
          await task;
        } finally {
          await subscription.cancel();
        }
        onFileUploaded(kind);
        for (final previous in [
          paths[kind] ?? '',
          existing?.legacyUrls[kind] ?? '',
        ]) {
          if (previous.isNotEmpty && previous != path) oldPaths.add(previous);
        }
        paths[kind] = path;
        completed++;
      }

      onProgress(1, 'Saving piece…');
      final data = <String, dynamic>{
        'title': title.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
      for (final kind in PieceFileKind.values) {
        final path = paths[kind] ?? '';
        if (path.isNotEmpty) data[kind.field] = path;
        if (selectedFiles.containsKey(kind) &&
            (existing?.legacyUrls[kind] ?? '').isNotEmpty) {
          data[kind.legacyUrlField] = FieldValue.delete();
        }
      }
      if (existing == null) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['uploadedBy'] = FirebaseAuth.instance.currentUser!.uid;
        await document.set(data);
      } else {
        await document.update(data);
      }
      saved = true;
      var cleanupFailures = 0;
      for (final path in oldPaths.toSet()) {
        try {
          await _referenceFor(path).delete();
        } on FirebaseException catch (error) {
          if (error.code != 'object-not-found') cleanupFailures++;
        } catch (_) {
          cleanupFailures++;
        }
      }
      return cleanupFailures;
    } catch (_) {
      if (!saved) {
        for (final path in newPaths) {
          try {
            await _storage.ref(path).delete();
          } catch (_) {
            // The previous Firestore document remains intact.
          }
        }
      }
      rethrow;
    }
  }

  Future<void> _collectFiles(
    Reference folder,
    Map<String, Reference> references,
  ) async {
    final result = await folder.listAll();
    for (final file in result.items) {
      references[file.fullPath] = file;
    }
    for (final childFolder in result.prefixes) {
      await _collectFiles(childFolder, references);
    }
  }

  Future<void> delete(MusicPiece piece) async {
    final document = _firestore.collection('available_pieces').doc(piece.id);
    final data = (await document.get()).data();
    if (data == null) return;
    final references = <String, Reference>{};
    for (final kind in PieceFileKind.values) {
      for (final field in [kind.field, kind.legacyUrlField]) {
        final location = data[field];
        if (location is String && location.isNotEmpty) {
          final reference = _referenceFor(location);
          references[reference.fullPath] = reference;
        }
      }
    }
    await _collectFiles(_storage.ref('pieces/${piece.id}'), references);
    for (final reference in references.values) {
      try {
        await reference.delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }
    }
    await document.delete();
  }
}

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _repository = PieceRepository();
  String _search = '';
  int _generation = 0;
  String? _deletingId;

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit([MusicPiece? piece]) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PieceFormDialog(existing: piece, repository: _repository),
    );
    if (result != null && mounted) _message(result);
  }

  Future<void> _delete(MusicPiece piece) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AdminDialogFrame(
        title: 'Delete music piece?',
        subtitle: 'Its stored files will be removed too. This cannot be undone.',
        maxWidth: 520,
        preferredHeight: 300,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: AdminPalette.of(context).danger,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'Remove “${piece.title}” from the library?',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFB91C1C)
                  : AdminPalette.of(context).danger,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deletingId = piece.id);
    try {
      await _repository.delete(piece);
      if (mounted) _message('Piece and stored files deleted.');
    } catch (_) {
      if (mounted) {
        _message('Deletion was incomplete. The piece remains so you can retry.');
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  Future<void> _openFile(PieceFileKind kind, String location) async {
    try {
      final url = await _repository.downloadUrl(location);
      if (!await launchUrl(Uri.parse(url)))
        throw StateError('Could not open file');
    } catch (_) {
      if (mounted) _message('Could not open the ${kind.label} file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AdminPalette.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Music library',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              FilledButton.icon(
                onPressed: () => _edit(),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Upload piece'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Manage pieces available to SoundSight players',
            style: TextStyle(color: colors.muted),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _search = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search title',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.surface,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              key: ValueKey(_generation),
              stream: FirebaseFirestore.instance
                  .collection('available_pieces')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AdminMessage(
                    icon: Icons.error_outline,
                    message:
                        'Could not load music pieces. Check your access and connection.',
                    onRetry: () => setState(() => _generation++),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final pieces =
                    snapshot.data!.docs
                        .map(MusicPiece.fromDocument)
                        .where(
                          (piece) =>
                              piece.title.toLowerCase().contains(_search),
                        )
                        .toList()
                      ..sort(
                        (a, b) => a.title.toLowerCase().compareTo(
                          b.title.toLowerCase(),
                        ),
                      );
                if (pieces.isEmpty) {
                  return AdminMessage(
                    icon: Icons.library_music_outlined,
                    message: _search.isEmpty
                        ? 'No music pieces yet. Upload the first one.'
                        : 'No pieces match your search.',
                  );
                }
                return ListView.separated(
                  itemCount: pieces.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final piece = pieces[index];
                    return AdminPanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                piece.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Added ${adminDate(piece.createdAt)}',
                                style: TextStyle(
                                  color: colors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final kind in PieceFileKind.values)
                                ActionChip(
                                  avatar: const Icon(
                                    Icons.insert_drive_file_outlined,
                                    size: 16,
                                  ),
                                  label: Text(kind.label),
                                  onPressed: piece.fileLocation(kind).isEmpty
                                      ? null
                                      : () =>
                                            _openFile(kind, piece.fileLocation(kind)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _deletingId == null
                                    ? () => _edit(piece)
                                    : null,
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                              OutlinedButton.icon(
                                onPressed: _deletingId == null
                                    ? () => _delete(piece)
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colors.danger,
                                  side: BorderSide(color: colors.danger),
                                ),
                                icon: _deletingId == piece.id
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colors.danger,
                                        ),
                                      )
                                    : const Icon(Icons.delete_outline),
                                label: const Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PieceFormDialog extends StatefulWidget {
  const PieceFormDialog({super.key, required this.repository, this.existing});

  final PieceRepository repository;
  final MusicPiece? existing;

  @override
  State<PieceFormDialog> createState() => _PieceFormDialogState();
}

class _PieceFormDialogState extends State<PieceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _selected = <PieceFileKind, PlatformFile>{};
  final _uploadedInAttempt = <PieceFileKind>{};
  bool _saving = false;
  double _progress = 0;
  String? _activity;
  String? _error;
  String? _resultMessage;
  bool _cleanupWarning = false;

  @override
  void initState() {
    super.initState();
    _title.text = widget.existing?.title ?? '';
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick(PieceFileKind kind) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: kind.extensions,
      );
      if (file == null || !mounted) return;
      final extension = file.name.split('.').last.toLowerCase();
      final length = await file.length();
      if (!kind.extensions.contains(extension) ||
          length == null ||
          length == 0) {
        setState(() => _error = 'Choose a readable ${kind.label} file.');
        return;
      }
      setState(() {
        _selected[kind] = file;
        _error = null;
      });
    } catch (_) {
      if (mounted)
        setState(() => _error = 'Could not read the ${kind.label} file.');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    for (final kind in PieceFileKind.values) {
      if (_selected[kind] == null &&
          (widget.existing?.fileLocation(kind) ?? '').isEmpty) {
        setState(
          () => _error =
              'Choose a ${kind.label} file. All four files are required.',
        );
        return;
      }
    }
    setState(() {
      _saving = true;
      _progress = 0;
      _activity = 'Preparing upload…';
      _error = null;
      _uploadedInAttempt.clear();
    });
    try {
      final leftovers = await widget.repository.save(
        title: _title.text,
        selectedFiles: _selected,
        existing: widget.existing,
        onProgress: (progress, activity) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _activity = activity;
            });
          }
        },
        onFileUploaded: (kind) {
          if (mounted) setState(() => _uploadedInAttempt.add(kind));
        },
      );
      if (mounted) {
        setState(() {
          _cleanupWarning = leftovers > 0;
          _resultMessage = leftovers == 0
              ? widget.existing == null
                    ? 'Piece uploaded successfully.'
                    : 'Changes saved successfully.'
              : 'Piece saved, but $leftovers old file(s) could not be removed.';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _uploadedInAttempt.clear();
          _error = error is StateError
              ? error.message.toString()
              : 'Could not save the piece. Please try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _selectionSummary(AdminPalette colors) {
    final isEditing = widget.existing != null;
    final readyCount = _selected.length;
    final blue = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2563EB);
    final heading = _saving
        ? _activity ?? 'Saving piece…'
        : isEditing
        ? readyCount == 0
              ? 'Current files are stored'
              : '$readyCount replacement file${readyCount == 1 ? '' : 's'} selected'
        : '$readyCount of 4 files ready to upload';
    final explanation = _saving
        ? 'Please keep this dialog open while the files are saved to Firebase.'
        : isEditing
            ? 'Selected replacements are still on your computer until you save.'
            : 'Selected files are still on your computer. Press Upload piece to store them.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.alphaBlend(blue.withAlpha(16), colors.surface),
        border: Border.all(color: blue.withAlpha(70)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_saving ? Icons.cloud_upload_outlined : Icons.info_outline,
              color: blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(heading, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(explanation, style: TextStyle(color: colors.muted)),
                if (_saving) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: _progress),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fileRow(PieceFileKind kind, AdminPalette colors) {
    final selected = _selected[kind];
    final storedLocation = widget.existing?.fileLocation(kind) ?? '';
    final stored = selected == null && storedLocation.isNotEmpty;
    final transferred = _uploadedInAttempt.contains(kind);
    final uploading = _saving && !transferred &&
        (_activity?.startsWith('Uploading ${kind.label}') ?? false);
    final blue = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2563EB);
    final green = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4ADE80)
        : const Color(0xFF15803D);
    final accent = stored ? green : selected == null ? colors.muted : blue;
    late final String status;
    if (transferred) {
      status = 'Transferred · Finishing save';
    } else if (uploading) {
      status = 'Uploading now…';
    } else if (selected != null) {
      status = _saving ? 'Waiting to upload' : 'Ready to upload · Not saved yet';
    } else if (stored) {
      status = 'Already stored in library';
    } else {
      status = 'Required · No file selected';
    }
    final fileName = selected?.name ??
        (stored ? _fileName(storedLocation) : kind.extensions.join(', '));
    final label = selected != null ? 'Change' : stored ? 'Replace' : 'Choose';
    final fileInfo = Row(
      children: [
        Icon(
          stored ? Icons.check_circle : selected == null
              ? Icons.upload_file_outlined : Icons.schedule_outlined,
          color: accent,
          size: 28,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kind.label,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(status,
                  style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.muted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
    final chooseButton = OutlinedButton(
      onPressed: _saving ? null : () => _pick(kind),
      child: Text(label),
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected != null || stored
            ? Color.alphaBlend(accent.withAlpha(12), colors.surface)
            : colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected != null || stored ? accent.withAlpha(90) : colors.border,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 430
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  fileInfo,
                  const SizedBox(height: 12),
                  chooseButton,
                ],
              )
            : Row(
                children: [
                  Expanded(child: fileInfo),
                  const SizedBox(width: 16),
                  chooseButton,
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AdminPalette.of(context);
    if (_resultMessage != null) {
      final successColor = Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF4ADE80)
          : const Color(0xFF15803D);
      return AdminDialogFrame(
        title: _cleanupWarning
            ? 'Piece saved'
            : widget.existing == null
                ? 'Upload complete'
                : 'Changes saved',
        subtitle: _cleanupWarning
            ? 'The library entry is saved, but some old files need attention.'
            : 'Your music library is up to date.',
        maxWidth: 760,
        preferredHeight: 600,
        child: SizedBox(
          height: 300,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _cleanupWarning
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_rounded,
                  size: 72,
                  color: _cleanupWarning ? colors.danger : successColor,
                ),
                const SizedBox(height: 20),
                Text(
                  _title.text.trim(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _resultMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.muted),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, _resultMessage),
            icon: const Icon(Icons.check),
            label: const Text('Done'),
          ),
        ],
      );
    }
    return AdminDialogFrame(
      title: widget.existing == null ? 'Upload music piece' : 'Edit music piece',
      subtitle: widget.existing == null
          ? 'Select all four files, then upload them to the library.'
          : 'Stored files are marked in green. New selections are not saved yet.',
      maxWidth: 760,
      preferredHeight: 700,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _title,
              enabled: !_saving,
              maxLength: 160,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Title is required.'
                  : null,
            ),
            const SizedBox(height: 8),
            _selectionSummary(colors),
            const SizedBox(height: 14),
            for (final kind in PieceFileKind.values) ...[
              _fileRow(kind, colors),
              const SizedBox(height: 10),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: colors.danger)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: Icon(widget.existing == null
              ? Icons.cloud_upload_outlined
              : Icons.save_outlined),
          label: Text(
            _saving ? 'Saving…'
                : widget.existing == null ? 'Upload piece' : 'Save changes',
          ),
        ),
      ],
    );
  }
}
