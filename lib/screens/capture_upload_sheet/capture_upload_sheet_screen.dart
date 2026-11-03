import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:soundsight/widgets/delete_swipe_background.dart';
import 'package:soundsight/widgets/app_snack_bar.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/capture_upload_sheet/capture_tips_container.dart';
import 'package:soundsight/screens/capture_upload_sheet/capture_upload_dialogs.dart';
import 'package:soundsight/screens/capture_upload_sheet/capture_upload_header.dart';
import 'package:soundsight/screens/capture_upload_sheet/music_sheet_upload_service.dart';
import 'package:soundsight/screens/capture_upload_sheet/music_sheet_audio_upload_service.dart';
import 'package:soundsight/screens/capture_upload_sheet/music_sheet_video_audio_service.dart';
import 'package:soundsight/screens/capture_upload_sheet/save_sheet_container.dart';
import 'package:soundsight/screens/capture_upload_sheet/selected_audio_container.dart';
import 'package:soundsight/screens/capture_upload_sheet/selected_audio_file.dart';
import 'package:soundsight/screens/capture_upload_sheet/selected_video_container.dart';
import 'package:soundsight/screens/capture_upload_sheet/selected_video_file.dart';
import 'package:soundsight/screens/capture_upload_sheet/selected_sheet_file.dart';
import 'package:soundsight/screens/capture_upload_sheet/selected_sheet_preview_dialog.dart';
import 'package:soundsight/screens/capture_upload_sheet/selected_sheets_container.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';

enum SheetInputAction { none, upload, capture }

class CaptureUploadSheetScreen extends StatefulWidget {
  const CaptureUploadSheetScreen({
    super.key,
    this.isDarkMode,
    this.initialAction = SheetInputAction.none,
  });

  final bool? isDarkMode;
  final SheetInputAction initialAction;

  @override
  State<CaptureUploadSheetScreen> createState() =>
      _CaptureUploadSheetScreenState();
}

class _CaptureUploadSheetScreenState extends State<CaptureUploadSheetScreen> {
  static const int maxSheetPages = MusicSheetUploadService.maxSheetPages;
  static const int maxImageFileSize = MusicSheetUploadService.maxImageFileSize;
  static const int maxPdfFileSize = MusicSheetUploadService.maxPdfFileSize;

  late bool isDarkMode;
  List<SelectedSheetFile> selectedSheets = [];
  SelectedAudioFile? selectedAudio;
  SelectedVideoFile? selectedVideo;
  int? selectedPdfPageCount;
  bool isPickingFiles = false;
  bool isPickingAudio = false;
  bool isPickingVideo = false;
  bool isSavingSheet = false;
  bool isPreparingAudio = false;
  double uploadProgress = 0;

  final ImagePicker imagePicker = ImagePicker();
  final MusicSheetUploadService uploadService = MusicSheetUploadService();
  final MusicSheetAudioUploadService audioUploadService =
      MusicSheetAudioUploadService();
  final MusicSheetVideoAudioService videoAudioService =
      MusicSheetVideoAudioService();

  bool get hasSelectedPdf => selectedSheets.any((file) {
    return file.extension?.toLowerCase() == 'pdf';
  });

  bool get hasCapturedImages => selectedSheets.isNotEmpty && !hasSelectedPdf;

  @override
  void dispose() {
    final audio = selectedAudio;
    if (audio != null) unawaited(audio.cleanUp());
    final video = selectedVideo;
    if (video != null) unawaited(video.cleanUp());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode ?? false;
    loadTheme();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (widget.initialAction == SheetInputAction.upload) {
        pickSheets();
      } else if (widget.initialAction == SheetInputAction.capture) {
        captureSheet();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);

    return PopScope(
      canPop: !isSavingSheet,
      child: Scaffold(
        backgroundColor: colors.backgroundColor,
        appBar: AppBar(
          backgroundColor: colors.backgroundColor,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: colors.primaryColor,
          centerTitle: true,
          title: Text(
            context.l10n.addSheet,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppTextSizes.sectionTitle,
            ),
          ),
          actions: [
            if (selectedSheets.isNotEmpty)
              IconButton(
                tooltip: context.l10n.deleteAllSelectedFilesTooltip,
                onPressed: isSavingSheet
                    ? null
                    : () => confirmDeleteAllSelectedFiles(colors),
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  color: isSavingSheet
                      ? colors.secondaryTextColor
                      : const Color(0xFFDC2626),
                ),
              ),
          ],
        ),
        drawer: isSavingSheet
            ? null
            : AppDrawer(
                isDarkMode: isDarkMode,
                activeItem: DrawerItem.captureUpload,
                onDarkModeChanged: (value) {
                  setState(() {
                    isDarkMode = value;
                  });
                },
              ),
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            children: [
              CaptureUploadHeader(
                colors: colors,
                isPickingFiles: isPickingFiles,
                isPickingAudio: isPickingAudio,
                isPickingVideo: isPickingVideo,
                isSavingSheet: isSavingSheet,
                isUploadLocked:
                    selectedSheets.isNotEmpty ||
                    selectedAudio != null ||
                    selectedVideo != null,
                isCaptureLocked:
                    selectedAudio != null ||
                    selectedVideo != null ||
                    hasSelectedPdf ||
                    selectedSheets.length >= maxSheetPages,
                isAudioLocked:
                    selectedSheets.isNotEmpty ||
                    selectedAudio != null ||
                    selectedVideo != null,
                isVideoLocked:
                    selectedSheets.isNotEmpty ||
                    selectedAudio != null ||
                    selectedVideo != null,
                onUpload: handleUploadPressed,
                onCapture: handleCapturePressed,
                onAudio: pickAudio,
                onVideo: pickVideo,
              ),
              if (selectedSheets.isNotEmpty) ...[
                Gap(AppSpacing.xl),
                SelectedSheetsContainer(
                  colors: colors,
                  selectedSheets: selectedSheets,
                  selectedPdfPageCount: selectedPdfPageCount,
                  isSavingSheet: isSavingSheet,
                  onView: (file) => viewSelectedSheet(file, colors),
                  onRemove: removeSelectedSheet,
                ),
              ],
              if (selectedAudio != null) ...[
                Gap(AppSpacing.xl),
                Dismissible(
                  key: ValueKey(selectedAudio!.path),
                  direction: isSavingSheet
                      ? DismissDirection.none
                      : DismissDirection.startToEnd,
                  background: DeleteSwipeBackground(
                    colors: colors,
                    label: context.l10n.remove,
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (_) => RemoveSelectedSheetDialog(
                            colors: colors,
                            fileName: selectedAudio!.name,
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) => removeSelectedAudio(),
                  child: SelectedAudioContainer(
                    colors: colors,
                    file: selectedAudio!,
                    isSaving: isSavingSheet,
                  ),
                ),
              ],
              if (selectedVideo != null) ...[
                Gap(AppSpacing.xl),
                Dismissible(
                  key: ValueKey(selectedVideo!.path),
                  direction: isSavingSheet
                      ? DismissDirection.none
                      : DismissDirection.startToEnd,
                  background: DeleteSwipeBackground(
                    colors: colors,
                    label: context.l10n.remove,
                  ),
                  confirmDismiss: (_) async {
                    return await showDialog<bool>(
                          context: context,
                          builder: (_) => RemoveSelectedSheetDialog(
                            colors: colors,
                            fileName: selectedVideo!.name,
                          ),
                        ) ??
                        false;
                  },
                  onDismissed: (_) => removeSelectedVideo(),
                  child: SelectedVideoContainer(
                    colors: colors,
                    file: selectedVideo!,
                    isSaving: isSavingSheet,
                  ),
                ),
              ],
              Gap(AppSpacing.xl),
              CaptureTipsContainer(colors: colors),
            ],
          ),
        ),
        bottomNavigationBar:
            selectedSheets.isEmpty &&
                selectedAudio == null &&
                selectedVideo == null
            ? null
            : SaveSheetContainer(
                colors: colors,
                isSavingSheet: isSavingSheet,
                uploadProgress: uploadProgress,
                isAudio: selectedAudio != null || selectedVideo != null,
                isPreparingAudio: isPreparingAudio,
                onSave: isPickingFiles
                    ? null
                    : () => selectedVideo != null
                          ? saveSelectedVideo(colors)
                          : selectedAudio != null
                          ? saveSelectedAudio(colors)
                          : saveSelectedSheets(colors),
              ),
      ),
    );
  }

  Future<void> loadTheme() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final theme = userDoc.data()?['theme'] ?? 'light';

    if (!mounted) return;

    setState(() {
      isDarkMode = theme == 'dark';
    });
  }

  Future<void> saveSelectedSheets(AppThemeColors colors) async {
    if (selectedSheets.isEmpty || isSavingSheet || isPickingFiles) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showSelectionMessage(context.l10n.signInBeforeSaving);
      return;
    }

    final title = await showDialog<String>(
      context: context,
      builder: (_) => SheetTitleDialog(colors: colors),
    );

    if (title == null || !mounted) return;

    final files = List<SelectedSheetFile>.from(selectedSheets);
    final pdfPageCount = selectedPdfPageCount;

    setState(() {
      isSavingSheet = true;
      uploadProgress = 0;
    });

    try {
      await uploadService.saveSheet(
        ownerId: user.uid,
        title: title,
        files: files,
        pdfPageCount: pdfPageCount,
        onProgress: (progress) {
          if (!mounted) return;

          setState(() {
            uploadProgress = progress;
          });
        },
      );

      if (!mounted) return;

      setState(() {
        selectedSheets.clear();
        selectedPdfPageCount = null;
        isSavingSheet = false;
        uploadProgress = 0;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => SheetSaveResultDialog(
          colors: colors,
          isSuccessful: true,
          sheetTitle: title,
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        isSavingSheet = false;
        uploadProgress = 0;
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            SheetSaveResultDialog(colors: colors, isSuccessful: false),
      );
    }
  }

  Future<void> confirmDeleteAllSelectedFiles(AppThemeColors colors) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteSelectedSheetsDialog(
        colors: colors,
        fileCount: selectedSheets.length,
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() {
      selectedSheets.clear();
      selectedPdfPageCount = null;
    });
  }

  Future<void> pickSheets() async {
    if (isSavingSheet || isPickingFiles) return;

    if (selectedVideo != null) {
      showSelectionMessage(context.l10n.removeSelectedFileBeforeSwitch);
      return;
    }
    if (selectedAudio != null) {
      showSelectionMessage(context.l10n.removeAudioBeforeOtherSource);
      return;
    }

    if (hasSelectedPdf) {
      showSelectionMessage(context.l10n.onlyOnePdf);
      return;
    }

    if (hasCapturedImages) {
      showSelectionMessage(context.l10n.deleteImagesBeforePdf);
      return;
    }

    setState(() {
      isPickingFiles = true;
    });

    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (pickedFiles.isEmpty) return;

      final files = await Future.wait(
        pickedFiles.map((file) async {
          return SelectedSheetFile(
            name: file.name,
            bytes: await file.readAsBytes(),
            path: file.path,
          );
        }),
      );

      final pdf = files.length == 1 ? files.single : null;
      await selectPdf(files, pdf);
    } finally {
      if (mounted) {
        setState(() {
          isPickingFiles = false;
        });
      }
    }
  }

  Future<void> selectPdf(
    List<SelectedSheetFile> pickedFiles,
    SelectedSheetFile? pdf,
  ) async {
    if (pickedFiles.length != 1 || pdf == null) {
      showSelectionMessage(context.l10n.selectExactlyOnePdf);
      return;
    }

    if (pdf.extension?.toLowerCase() != 'pdf') {
      showSelectionMessage(context.l10n.onlyPdfFiles);
      return;
    }

    if (selectedSheets.isNotEmpty) {
      showSelectionMessage(
        hasSelectedPdf
            ? context.l10n.onlyOnePdf
            : context.l10n.deleteImagesBeforePdf,
      );
      return;
    }

    if (pdf.size > maxPdfFileSize) {
      showSelectionMessage(context.l10n.pdfSizeLimit);
      return;
    }

    try {
      final pageCount = await getPdfPageCount(pdf);

      if (pageCount < 1) {
        showSelectionMessage(context.l10n.pdfHasNoPages);
        return;
      }

      if (pageCount > maxSheetPages) {
        showSelectionMessage(
          context.l10n.pdfPageLimit(pageCount, maxSheetPages),
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        selectedSheets = [pdf];
        selectedPdfPageCount = pageCount;
      });
    } catch (_) {
      showSelectionMessage(
        context.l10n.pdfReadFailed,
        type: AppSnackBarType.error,
      );
    }
  }

  Future<int> getPdfPageCount(SelectedSheetFile pdf) async {
    final bytes = pdf.bytes;

    await pdfrxFlutterInitialize();
    final document = await PdfDocument.openData(bytes, sourceName: pdf.name);

    try {
      return document.pages.length;
    } finally {
      await document.dispose();
    }
  }

  void removeSelectedSheet(int index) {
    setState(() {
      selectedSheets.removeAt(index);
      if (selectedSheets.isEmpty) {
        selectedPdfPageCount = null;
      }
    });
  }

  void viewSelectedSheet(SelectedSheetFile file, AppThemeColors colors) {
    showDialog<void>(
      context: context,
      builder: (_) => SelectedSheetPreviewDialog(colors: colors, file: file),
    );
  }

  Future<void> captureSheet() async {
    if (isSavingSheet || isPickingFiles) return;

    if (selectedVideo != null) {
      showSelectionMessage(context.l10n.removeSelectedFileBeforeSwitch);
      return;
    }
    if (selectedAudio != null) {
      showSelectionMessage(context.l10n.removeAudioBeforeOtherSource);
      return;
    }

    if (hasSelectedPdf) {
      showSelectionMessage(context.l10n.deletePdfBeforeCapture);
      return;
    }

    if (selectedSheets.length >= maxSheetPages) {
      showSelectionMessage(context.l10n.imageCountLimit(maxSheetPages));
      return;
    }

    final image = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    if (bytes.length > maxImageFileSize) {
      showSelectionMessage(context.l10n.capturedImageSizeLimit);
      return;
    }

    if (!mounted) return;

    final capturedFile = SelectedSheetFile(
      name: image.name,
      bytes: bytes,
      path: image.path,
    );

    setState(() {
      selectedSheets.add(capturedFile);
      selectedPdfPageCount = null;
    });
  }

  void handleUploadPressed() {
    if (isSavingSheet || isPickingFiles) return;

    if (selectedVideo != null) {
      showSelectionMessage(context.l10n.removeSelectedFileBeforeSwitch);
      return;
    }
    if (selectedAudio != null) {
      showSelectionMessage(context.l10n.removeAudioBeforeOtherSource);
      return;
    }

    if (hasSelectedPdf) {
      showSelectionMessage(context.l10n.onlyOnePdf);
      return;
    }

    if (hasCapturedImages) {
      showSelectionMessage(context.l10n.deleteImagesBeforePdf);
      return;
    }

    pickSheets();
  }

  void handleCapturePressed() {
    if (isSavingSheet || isPickingFiles) return;

    if (selectedVideo != null) {
      showSelectionMessage(context.l10n.removeSelectedFileBeforeSwitch);
      return;
    }
    if (selectedAudio != null) {
      showSelectionMessage(context.l10n.removeAudioBeforeOtherSource);
      return;
    }

    if (hasSelectedPdf) {
      showSelectionMessage(context.l10n.deletePdfBeforeCapture);
      return;
    }

    if (selectedSheets.length >= maxSheetPages) {
      showSelectionMessage(context.l10n.imageCountLimit(maxSheetPages));
      return;
    }

    captureSheet();
  }

  Future<void> pickAudio() async {
    if (isSavingSheet || isPickingFiles) return;
    if (selectedAudio != null) return;
    if (selectedVideo != null) {
      showSelectionMessage(context.l10n.removeSelectedFileBeforeSwitch);
      return;
    }
    if (selectedSheets.isNotEmpty) {
      showSelectionMessage(context.l10n.removeSheetsBeforeAudio);
      return;
    }
    setState(() {
      isPickingFiles = true;
      isPickingAudio = true;
    });
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp3'],
      );
      if (picked == null) return;
      final next = await SelectedAudioFile.fromPickedFile(picked);
      if (!mounted) {
        await next.cleanUp();
        return;
      }
      setState(() => selectedAudio = next);
    } on AudioSelectionException catch (error) {
      if (!mounted) return;
      final message = switch (error.failure) {
        AudioSelectionFailure.unsupported => context.l10n.audioUnsupported,
        AudioSelectionFailure.empty => context.l10n.audioEmpty,
        AudioSelectionFailure.tooLarge => context.l10n.audioTooLarge,
        AudioSelectionFailure.tooLong => context.l10n.audioTooLong,
        AudioSelectionFailure.unreadable => context.l10n.audioUnreadable,
      };
      showSelectionMessage(message);
    } catch (_) {
      if (mounted) {
        showSelectionMessage(
          context.l10n.audioUnreadable,
          type: AppSnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPickingFiles = false;
          isPickingAudio = false;
        });
      }
    }
  }

  Future<void> pickVideo() async {
    if (isSavingSheet || isPickingFiles || selectedVideo != null) return;
    if (selectedSheets.isNotEmpty || selectedAudio != null) {
      showSelectionMessage(context.l10n.removeSelectedFileBeforeSwitch);
      return;
    }
    setState(() {
      isPickingFiles = true;
      isPickingVideo = true;
    });
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp4'],
      );
      if (picked == null) return;
      final next = await SelectedVideoFile.fromPickedFile(picked);
      if (!mounted) {
        await next.cleanUp();
        return;
      }
      setState(() => selectedVideo = next);
    } on VideoSelectionException catch (error) {
      if (!mounted) return;
      final message = switch (error.failure) {
        VideoSelectionFailure.unsupported => context.l10n.videoUnsupported,
        VideoSelectionFailure.empty => context.l10n.videoEmpty,
        VideoSelectionFailure.tooLarge => context.l10n.videoTooLarge,
        VideoSelectionFailure.tooLong => context.l10n.videoTooLong,
        VideoSelectionFailure.noAudio => context.l10n.videoNoAudio,
        VideoSelectionFailure.unreadable => context.l10n.videoUnreadable,
      };
      showSelectionMessage(message);
    } catch (_) {
      if (mounted) {
        showSelectionMessage(
          context.l10n.videoUnreadable,
          type: AppSnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isPickingFiles = false;
          isPickingVideo = false;
        });
      }
    }
  }

  void removeSelectedAudio() {
    final previous = selectedAudio;
    if (previous == null || isSavingSheet) return;
    setState(() => selectedAudio = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(previous.cleanUp());
    });
  }

  void removeSelectedVideo() {
    final previous = selectedVideo;
    if (previous == null || isSavingSheet) return;
    setState(() => selectedVideo = null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(previous.cleanUp());
    });
  }

  Future<void> saveSelectedAudio(AppThemeColors colors) async {
    final file = selectedAudio;
    if (file == null || isSavingSheet || isPickingFiles) return;
    final title = await showDialog<String>(
      context: context,
      builder: (_) => SheetTitleDialog(colors: colors),
    );
    if (title == null || !mounted) return;
    setState(() {
      isSavingSheet = true;
      uploadProgress = 0;
    });
    try {
      await audioUploadService.saveAudio(
        title: title,
        file: file,
        onProgress: (progress) {
          if (mounted) setState(() => uploadProgress = progress);
        },
      );
      if (!mounted) return;
      setState(() {
        selectedAudio = null;
        isSavingSheet = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(file.cleanUp());
      });
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => SheetSaveResultDialog(
          colors: colors,
          isSuccessful: true,
          sheetTitle: title,
          isAudio: true,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isSavingSheet = false;
        uploadProgress = 0;
      });
      showSelectionMessage(
        context.l10n.audioSaveFailed,
        type: AppSnackBarType.error,
      );
    }
  }

  Future<void> saveSelectedVideo(AppThemeColors colors) async {
    final video = selectedVideo;
    if (video == null || isSavingSheet || isPickingFiles) return;
    final title = await showDialog<String>(
      context: context,
      builder: (_) => SheetTitleDialog(colors: colors),
    );
    if (title == null || !mounted) return;

    setState(() {
      isSavingSheet = true;
      isPreparingAudio = true;
      uploadProgress = 0;
    });

    SelectedAudioFile? preparedAudio;
    var uploading = false;
    try {
      preparedAudio = await videoAudioService.prepareAudio(video);
      if (!mounted) return;
      setState(() => isPreparingAudio = false);
      uploading = true;
      await audioUploadService.saveAudio(
        title: title,
        file: preparedAudio,
        onProgress: (progress) {
          if (mounted) setState(() => uploadProgress = progress);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isSavingSheet = false;
        isPreparingAudio = false;
        uploadProgress = 0;
      });
      showSelectionMessage(
        uploading
            ? context.l10n.audioSaveFailed
            : context.l10n.videoPreparationFailed,
        type: AppSnackBarType.error,
      );
      return;
    } finally {
      if (preparedAudio != null) {
        try {
          await preparedAudio.cleanUp();
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() {
      selectedVideo = null;
      isSavingSheet = false;
      uploadProgress = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(video.cleanUp());
    });
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SheetSaveResultDialog(
        colors: colors,
        isSuccessful: true,
        sheetTitle: title,
        isAudio: true,
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  void showSelectionMessage(
    String message, {
    AppSnackBarType type = AppSnackBarType.warning,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showLatestSnackBar(
      appSnackBar(
        colors: AppThemeColors.fromDarkMode(isDarkMode),
        message: message,
        type: type,
      ),
    );
  }
}
