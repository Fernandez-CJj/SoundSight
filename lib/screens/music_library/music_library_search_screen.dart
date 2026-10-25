import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/music_library/music_library_piece_screen.dart';
import 'package:soundsight/theme/app_theme_colors.dart';

class MusicLibrarySearchScreen extends StatefulWidget {
  const MusicLibrarySearchScreen({super.key, required this.isDarkMode});

  final bool isDarkMode;

  @override
  State<MusicLibrarySearchScreen> createState() =>
      _MusicLibrarySearchScreenState();
}

class _MusicLibrarySearchScreenState extends State<MusicLibrarySearchScreen> {
  static const int _pageSize = 20;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _browsePieces = [];
  Stream<QuerySnapshot<Map<String, dynamic>>>? _searchStream;
  DocumentSnapshot<Map<String, dynamic>>? _lastBrowseDocument;
  bool _isLoadingPage = false;
  bool _hasMorePages = true;
  Object? _browseError;
  int _browseGeneration = 0;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreIfNeeded);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNextPage());
  }

  void _loadMoreIfNeeded() {
    if (_browseError == null &&
        _scrollController.hasClients &&
        _scrollController.position.extentAfter < 300) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (!mounted ||
        FirebaseAuth.instance.currentUser == null ||
        _query.trim().isNotEmpty ||
        _isLoadingPage ||
        !_hasMorePages) {
      return;
    }

    final generation = _browseGeneration;
    setState(() {
      _isLoadingPage = true;
      _browseError = null;
    });

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('available_pieces')
          .orderBy('title')
          .limit(_pageSize);
      if (_lastBrowseDocument != null) {
        query = query.startAfterDocument(_lastBrowseDocument!);
      }
      final page = await query.get();
      if (!mounted ||
          generation != _browseGeneration ||
          _query.trim().isNotEmpty)
        return;

      setState(() {
        _browsePieces.addAll(page.docs);
        if (page.docs.isNotEmpty) _lastBrowseDocument = page.docs.last;
        _hasMorePages = page.docs.length == _pageSize;
        _isLoadingPage = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMoreIfNeeded();
      });
    } catch (error) {
      if (!mounted ||
          generation != _browseGeneration ||
          _query.trim().isNotEmpty)
        return;
      setState(() {
        _browseError = error;
        _isLoadingPage = false;
      });
    }
  }

  void _resetBrowse() {
    _browseGeneration++;
    setState(() {
      _browsePieces.clear();
      _lastBrowseDocument = null;
      _hasMorePages = true;
      _isLoadingPage = false;
      _browseError = null;
    });
    _loadNextPage();
  }

  void _onSearchChanged(String value) {
    final wasSearching = _query.trim().isNotEmpty;
    final isSearching = value.trim().isNotEmpty;
    setState(() {
      _query = value;
      if (isSearching && !wasSearching) {
        _searchStream = FirebaseFirestore.instance
            .collection('available_pieces')
            .snapshots();
      } else if (!isSearching) {
        _searchStream = null;
      }
    });
    if (wasSearching && !isSearching) _resetBrowse();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(widget.isDarkMode);

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
            context.l10n.searchMusic,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppTextSizes.sectionTitle,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.musicLibrary,
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.screenTitle,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.musicLibraryDescription,
                    style: TextStyle(
                      color: colors.secondaryTextColor,
                      fontSize: AppTextSizes.label,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _searchController,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(color: colors.primaryColor),
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: context.l10n.searchMusicHint,
                      hintStyle: TextStyle(color: colors.secondaryTextColor),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: colors.secondaryTextColor,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: context.l10n.clearSearch,
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                color: colors.secondaryTextColor,
                              ),
                            ),
                      filled: true,
                      fillColor: colors.surfaceColor,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(color: colors.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: BorderSide(
                          color: colors.primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildPieces(colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildPieces(AppThemeColors colors) {
    if (FirebaseAuth.instance.currentUser == null) {
      return _message(
        colors,
        Icons.lock_outline_rounded,
        context.l10n.signInToSearchMusic,
      );
    }

    if (_query.trim().isEmpty) {
      if (_browsePieces.isEmpty && _browseError == null && _hasMorePages) {
        return Center(
          child: CircularProgressIndicator(color: colors.primaryColor),
        );
      }

      if (_browsePieces.isEmpty && _browseError != null) {
        return _message(
          colors,
          Icons.wifi_off_rounded,
          context.l10n.musicLibraryLoadError,
          action: TextButton.icon(
            onPressed: _loadNextPage,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.l10n.retry),
          ),
        );
      }

      if (_browsePieces.isEmpty) {
        return _message(
          colors,
          Icons.library_music_outlined,
          context.l10n.noLibraryPieces,
        );
      }

      return _pieceList(colors, _browsePieces, paged: true);
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _searchStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _message(
            colors,
            Icons.wifi_off_rounded,
            context.l10n.musicLibraryLoadError,
            action: TextButton.icon(
              onPressed: () => setState(() {
                _searchStream = FirebaseFirestore.instance
                    .collection('available_pieces')
                    .snapshots();
              }),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: colors.primaryColor),
          );
        }

        final pieces = snapshot.data!.docs.toList()
          ..sort((first, second) {
            final firstTitle = _title(first.data()).toLowerCase();
            final secondTitle = _title(second.data()).toLowerCase();
            final comparison = firstTitle.compareTo(secondTitle);
            return comparison != 0 ? comparison : first.id.compareTo(second.id);
          });

        final terms = _query.trim().toLowerCase().split(RegExp(r'\s+'));
        final visiblePieces = pieces.where((piece) {
          final title = _title(piece.data()).toLowerCase();
          return terms.every(title.contains);
        }).toList();

        if (visiblePieces.isEmpty) {
          return _message(
            colors,
            Icons.search_off_rounded,
            context.l10n.noMusicSearchResults,
          );
        }

        return _pieceList(colors, visiblePieces);
      },
    );
  }

  Widget _pieceList(
    AppThemeColors colors,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> pieces, {
    bool paged = false,
  }) {
    final hasFooter = paged && (_isLoadingPage || _browseError != null);

    return ListView.separated(
      controller: paged ? _scrollController : null,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.lg,
      ),
      itemCount: pieces.length + (hasFooter ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index == pieces.length) {
          if (_browseError != null) {
            return Center(
              child: TextButton.icon(
                onPressed: _loadNextPage,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(context.l10n.retry),
              ),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(color: colors.primaryColor),
            ),
          );
        }

        final piece = pieces[index];
        final title = _title(piece.data());
        return Semantics(
          button: true,
          label: context.l10n.musicLibraryOpenPiece(title),
          child: Material(
            color: colors.surfaceColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              side: BorderSide(color: colors.borderColor),
            ),
            child: InkWell(
              excludeFromSemantics: true,
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MusicLibraryPieceScreen(
                      pieceId: piece.id,
                      colors: colors,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Icon(Icons.music_note_rounded, color: colors.primaryColor),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: colors.primaryColor,
                          fontSize: AppTextSizes.label,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colors.secondaryTextColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _title(Map<String, dynamic> data) {
    final title = data['title'];
    if (title is String && title.trim().isNotEmpty) return title.trim();
    return context.l10n.untitledPiece;
  }

  Widget _message(
    AppThemeColors colors,
    IconData icon,
    String message, {
    Widget? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: colors.secondaryTextColor),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.secondaryTextColor),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.sm),
              action,
            ],
          ],
        ),
      ),
    );
  }
}
