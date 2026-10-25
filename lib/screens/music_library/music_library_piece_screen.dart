import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/music_sheet/widgets/music_sheet_audio_preview.dart';
import 'package:soundsight/screens/players/ar/ar_practice_screen.dart';
import 'package:soundsight/screens/players/sight_reading/music_sheet_reading_screen.dart';
import 'package:soundsight/screens/players/synthesia/models/synthesia_score_source.dart';
import 'package:soundsight/screens/players/synthesia/synthesia_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class MusicLibraryPieceScreen extends StatefulWidget {
  const MusicLibraryPieceScreen({
    super.key,
    required this.pieceId,
    required this.colors,
  });

  final String pieceId;
  final AppThemeColors colors;

  @override
  State<MusicLibraryPieceScreen> createState() =>
      _MusicLibraryPieceScreenState();
}

class _MusicLibraryPieceScreenState extends State<MusicLibraryPieceScreen> {
  static const int _maximumPdfSize = 20 * 1024 * 1024;

  final MusicSheetAudioPreviewController _audioController =
      MusicSheetAudioPreviewController();
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _pieceStream;
  String? _pdfLocation;
  Future<Uint8List?>? _pdfFuture;

  String get _documentPath => 'available_pieces/${widget.pieceId}';

  @override
  void initState() {
    super.initState();
    _pieceStream = FirebaseFirestore.instance
        .collection('available_pieces')
        .doc(widget.pieceId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _pieceStream,
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final title = _title(data);

        return Scaffold(
          backgroundColor: colors.backgroundColor,
          appBar: AppBar(
            backgroundColor: colors.backgroundColor,
            foregroundColor: colors.primaryColor,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                context.l10n.musicLibrary,
                style: const TextStyle(
                  fontSize: AppTextSizes.sectionTitle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: snapshot.hasError || data == null
              ? null
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: FloatingActionButton.extended(
                      onPressed: () => _showPlayModeDialog(data, title),
                      backgroundColor: colors.primaryColor,
                      foregroundColor: colors.backgroundColor,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(context.l10n.play),
                    ),
                  ),
                ),
          body: snapshot.hasError
              ? _message(context.l10n.musicLibraryLoadError)
              : !snapshot.hasData
              ? Center(
                  child: CircularProgressIndicator(color: colors.primaryColor),
                )
              : data == null
              ? _message(context.l10n.libraryPieceMissing)
              : _buildPiece(data, title),
        );
      },
    );
  }

  Widget _buildPiece(Map<String, dynamic> data, String title) {
    final colors = widget.colors;
    final pdfLocation = _location(data, 'pdf');
    final audioLocation = _location(data, 'mp3');

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.borderColor),
          ),
          child: Row(
            children: [
              Icon(Icons.library_music_outlined, color: colors.primaryColor),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.sectionTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (audioLocation.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              0,
            ),
            child: MusicSheetAudioPreview(
              colors: colors,
              storagePath: audioLocation,
              controller: _audioController,
            ),
          ),
        Expanded(child: _buildPdf(pdfLocation, title)),
      ],
    );
  }

  Widget _buildPdf(String location, String title) {
    final colors = widget.colors;
    if (location.isEmpty) {
      return _message(context.l10n.fileLoadFailed);
    }

    if (_pdfLocation != location) {
      _pdfLocation = location;
      _pdfFuture = _loadPdf(location);
    }

    return FutureBuilder<Uint8List?>(
      future: _pdfFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colors.primaryColor),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return _message(
            context.l10n.fileLoadFailed,
            action: TextButton.icon(
              onPressed: () => setState(() => _pdfFuture = _loadPdf(location)),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            88,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: PdfViewer.data(
              snapshot.data!,
              sourceName: title,
              params: PdfViewerParams(
                margin: AppSpacing.sm,
                backgroundColor: colors.backgroundColor,
                sizeDelegateProvider: const PdfViewerSizeDelegateProviderSmart(
                  smartMaxScale: 2,
                  maxPagesVisible: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List?> _loadPdf(String location) {
    final storage = FirebaseStorage.instance;
    final uri = Uri.tryParse(location);
    final reference = uri != null && uri.hasScheme
        ? storage.refFromURL(location)
        : storage.ref(location);
    return reference.getData(_maximumPdfSize);
  }

  Future<void> _showPlayModeDialog(
    Map<String, dynamic> data,
    String title,
  ) async {
    final selectedMode = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: widget.colors.surfaceColor,
        title: Text(
          context.l10n.choosePlayMode,
          style: TextStyle(color: widget.colors.primaryColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _modeTile(dialogContext, 'sightReading', Icons.music_note_rounded,
                context.l10n.sightReading),
            _modeTile(dialogContext, 'synthesia', Icons.piano_rounded,
                context.l10n.synthesia),
            _modeTile(dialogContext, 'ar', Icons.view_in_ar_rounded,
                context.l10n.arPractice),
          ],
        ),
      ),
    );

    if (!mounted || selectedMode == null) return;

    final midiLocation = _location(data, 'midi');
    final musicXmlLocation = _location(data, 'musicXml');
    final mp3Location = _location(data, 'mp3');
    if (midiLocation.isEmpty ||
        (selectedMode == 'sightReading' &&
            (musicXmlLocation.isEmpty || mp3Location.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.libraryPracticeFilesMissing)),
      );
      return;
    }

    await _audioController.stop();
    if (!mounted) return;

    final screen = switch (selectedMode) {
      'sightReading' => MusicSheetReadingScreen(
          scoreDocumentPath: _documentPath,
          source: SightReadingSource.musicLibrary,
          colors: widget.colors,
        ),
      'synthesia' => SynthesiaScreen(
          colors: widget.colors,
          source: SynthesiaLibraryPieceSource(
            documentPath: _documentPath,
            fallbackTitle: title,
          ),
        ),
      _ => ArPracticeScreen(
          colors: widget.colors,
          scoreDocumentPath: _documentPath,
        ),
    };
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Widget _modeTile(
    BuildContext dialogContext,
    String mode,
    IconData icon,
    String label,
  ) {
    return ListTile(
      leading: Icon(icon, color: widget.colors.primaryColor),
      title: Text(label, style: TextStyle(color: widget.colors.primaryColor)),
      onTap: () => Navigator.of(dialogContext).pop(mode),
    );
  }

  String _location(Map<String, dynamic> data, String kind) {
    final path = data['${kind}StoragePath'];
    if (path is String && path.trim().isNotEmpty) return path.trim();
    final url = data['${kind}Url'];
    return url is String ? url.trim() : '';
  }

  String _title(Map<String, dynamic>? data) {
    final value = data?['title'];
    return value is String && value.trim().isNotEmpty
        ? value.trim()
        : context.l10n.untitledPiece;
  }

  Widget _message(String message, {Widget? action}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: widget.colors.secondaryTextColor),
            ),
            if (action != null) action,
          ],
        ),
      ),
    );
  }
}
