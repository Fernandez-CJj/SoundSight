import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundsight/widgets/delete_swipe_background.dart';
import 'package:soundsight/widgets/app_snack_bar.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/localization/localization_extension.dart';
import 'package:soundsight/screens/capture_upload_sheet/widgets/capture_tips_container.dart';
import 'package:soundsight/screens/capture_upload_sheet/dialogs/capture_upload_dialogs.dart';
import 'package:soundsight/screens/capture_upload_sheet/dialogs/sheet_music_validation_dialogs.dart';
import 'package:soundsight/screens/capture_upload_sheet/widgets/capture_upload_header.dart';
import 'package:soundsight/screens/capture_upload_sheet/services/music_sheet_upload_service.dart';
import 'package:soundsight/screens/capture_upload_sheet/services/sheet_music_validation_service.dart';
import 'package:soundsight/screens/capture_upload_sheet/services/music_sheet_audio_upload_service.dart';
import 'package:soundsight/screens/capture_upload_sheet/services/music_sheet_video_audio_service.dart';
import 'package:soundsight/screens/capture_upload_sheet/widgets/save_sheet_container.dart';
import 'package:soundsight/screens/capture_upload_sheet/widgets/selected_audio_container.dart';
import 'package:soundsight/screens/capture_upload_sheet/models/selected_audio_file.dart';
import 'package:soundsight/screens/capture_upload_sheet/widgets/selected_video_container.dart';
import 'package:soundsight/screens/capture_upload_sheet/models/selected_video_file.dart';
import 'package:soundsight/screens/capture_upload_sheet/models/selected_sheet_file.dart';
import 'package:soundsight/screens/capture_upload_sheet/dialogs/selected_sheet_preview_dialog.dart';
import 'package:soundsight/screens/capture_upload_sheet/widgets/selected_sheets_container.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';
import 'package:soundsight/screens/onboarding/tours/capture_upload_tour.dart';
import 'package:soundsight/screens/onboarding/widgets/feature_showcase.dart';

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
  late final CaptureUploadTour uploadTour;
  List<SelectedSheetFile> selectedSheets = [];
  SelectedAudioFile? selectedAudio;
  SelectedVideoFile? selectedVideo;
  int? selectedPdfPageCount;
  bool isPickingFiles = false;
  bool isPickingAudio = false;
  bool isPickingVideo = false;
  bool isCapturingSheet = false;
  bool isCheckingSheet = false;
  bool isSavingSheet = false;
  bool isPreparingAudio = false;
  final ValueNotifier<double?> uploadProgress = ValueNotifier<double?>(0);

  final ImagePicker imagePicker = ImagePicker();
  final MusicSheetUploadService uploadService = MusicSheetUploadService();
  final SheetMusicValidationService sheetValidationService =
      SheetMusicValidationService();
  final MusicSheetAudioUploadService audioUploadService =
      MusicSheetAudioUploadService();
  final MusicSheetVideoAudioService videoAudioService =
      MusicSheetVideoAudioService();

  bool get hasSelectedPdf => selectedSheets.any((file) {
    return file.extension?.toLowerCase() == 'pdf';
  });

  bool get hasCapturedImages => selectedSheets.isNotEmpty && !hasSelectedPdf;

  bool get hasSelection =>
      selectedSheets.isNotEmpty ||
      selectedAudio != null ||
      selectedVideo != null;

  bool get isBusy =>
      isPickingFiles ||
      isPickingAudio ||
      isPickingVideo ||
      isCapturingSheet ||
      isCheckingSheet ||
      isSavingSheet ||
      isPreparingAudio;

  @override
  void dispose() {
    uploadTour.dispose();
    uploadProgress.dispose();
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
    uploadTour = CaptureUploadTour(
      context: () => context,
      isMounted: () => mounted,
      isBusy: () => isBusy,
    );
    loadTheme();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      unawaited(prepareUploadTutorial());
    });
  }

  Future<void> prepareUploadTutorial() async {
    try {
      if (widget.initialAction == SheetInputAction.upload) {
        await pickSheets();
      } else if (widget.initialAction == SheetInputAction.capture) {
        await captureSheet();
      }
    } catch (error) {
      debugPrint('Could not open the initial sheet input: $error');
    }
    if (!mounted) return;
    WidgetsBinding.instance.scheduleFrame();
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) await uploadTour.controller.start();
  }

  Widget guide(int index, String title, String description, Widget child) {
    return FeatureShowcase(
      controller: uploadTour.controller,
      stepIndex: index,
      title: title,
      description: description,
      colors: AppThemeColors.fromDarkMode(isDarkMode),
      child: child,
    );
  }

  Widget previewGuide(Widget child) => guide(
    4,
    context.l10n.featureTourUploadPreviewTitle,
    context.l10n.featureTourUploadPreviewBody,
    child,
  );

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);

    return AnimatedBuilder(
      animation: uploadTour.controller,
      builder: (context, _) => PopScope(
        canPop: !isSavingSheet && !uploadTour.controller.isActive,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && uploadTour.controller.isActive) {
            unawaited(uploadTour.controller.cancel());
          }
        },
        child: Scaffold(
          key: uploadTour.scaffoldKey,
          drawerEnableOpenDragGesture: !uploadTour.controller.isActive,
          onDrawerChanged: uploadTour.onDrawerChanged,
          backgroundColor: colors.backgroundColor,
          appBar: AppBar(
            backgroundColor: colors.backgroundColor,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            foregroundColor: colors.primaryColor,
            leading:
                isSavingSheet &&
                    ModalRoute.of(context)?.impliesAppBarDismissal == true
                ? IconButton(
                    onPressed: null,
                    disabledColor: colors.secondaryTextColor,
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    icon: const BackButtonIcon(),
                  )
                : null,
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
                  onPressed: isSavingSheet || uploadTour.controller.isActive
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
                  onReplayTutorial: isBusy
                      ? null
                      : () => unawaited(
                          uploadTour.controller.start(replay: true),
                        ),
                  onDarkModeChanged: (value) {
                    setState(() {
                      isDarkMode = value;
                    });
                  },
                ),
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: uploadTour.controller.isActive,
              child: SingleChildScrollView(
                controller: uploadTour.scrollController,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CaptureUploadHeader(
                      colors: colors,
                      isPickingFiles: isPickingFiles,
                      isPickingAudio: isPickingAudio,
                      isPickingVideo: isPickingVideo,
                      isSavingSheet:
                          isSavingSheet ||
                          isCapturingSheet ||
                          isCheckingSheet ||
                          uploadTour.controller.isActive,
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
                      pdfGuideBuilder: (child) => guide(
                        0,
                        context.l10n.uploadPdf,
                        context.l10n.featureTourUploadPdfBody,
                        child,
                      ),
                      captureGuideBuilder: (child) => guide(
                        1,
                        context.l10n.capturePages,
                        context.l10n.featureTourUploadCaptureBody,
                        child,
                      ),
                      recordingGuideBuilder: (child) => guide(
                        2,
                        context.l10n.featureTourUploadRecordingTitle,
                        context.l10n.featureTourUploadRecordingBody,
                        child,
                      ),
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
                        headingBuilder: previewGuide,
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
                          headingBuilder: previewGuide,
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
                          headingBuilder: previewGuide,
                        ),
                      ),
                    ],
                    if (!hasSelection && uploadTour.controller.isActive) ...[
                      Gap(AppSpacing.xl),
                      previewGuide(
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: colors.surfaceColor,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: colors.borderColor),
                          ),
                          child: Text(
                            context.l10n.featureTourUploadPreviewEmpty,
                            style: TextStyle(color: colors.secondaryTextColor),
                          ),
                        ),
                      ),
                    ],
                    Gap(AppSpacing.xl),
                    CaptureTipsContainer(
                      colors: colors,
                      headingBuilder: (child) => guide(
                        3,
                        context.l10n.captureTips,
                        context.l10n.featureTourUploadTipsBody,
                        child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: !hasSelection && !uploadTour.controller.isActive
              ? null
              : guide(
                  5,
                  context.l10n.featureTourUploadSaveTitle,
                  context.l10n.featureTourUploadSaveBody,
                  SaveSheetContainer(
                    colors: colors,
                    isSavingSheet: isSavingSheet,
                    isAudio: selectedAudio != null || selectedVideo != null,
                    onSave:
                        isBusy ||
                            !hasSelection ||
                            uploadTour.controller.isActive
                        ? null
                        : () => selectedVideo != null
                              ? saveSelectedVideo(colors)
                              : selectedAudio != null
                              ? saveSelectedAudio(colors)
                              : saveSelectedSheets(colors),
                  ),
                ),
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

  Future<T> withSavingDialog<T>(
    AppThemeColors colors,
    Future<T> Function() save,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValueListenableBuilder<double?>(
        valueListenable: uploadProgress,
        builder: (_, progress, _) =>
            SheetSavingDialog(colors: colors, progress: progress),
      ),
    );
    unawaited(navigator.push(route));
    try {
      return await save();
    } finally {
      if (route.isActive) navigator.removeRoute(route);
    }
  }

  Future<void> saveSelectedSheets(AppThemeColors colors) async {
    if (selectedSheets.isEmpty || isBusy) return;

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
      uploadProgress.value = 0;
    });

    try {
      await withSavingDialog(
        colors,
        () => uploadService.saveSheet(
          ownerId: user.uid,
          title: title,
          files: files,
          pdfPageCount: pdfPageCount,
          onProgress: (progress) {
            if (!mounted) return;

            uploadProgress.value = progress;
          },
        ),
      );

      if (!mounted) return;

      setState(() {
        selectedSheets.clear();
        selectedPdfPageCount = null;
        isSavingSheet = false;
        uploadProgress.value = 0;
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
        uploadProgress.value = 0;
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
    if (isBusy) return;

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
      if (!mounted) return;
      if (pickedFiles.length != 1) {
        showSelectionMessage(context.l10n.selectExactlyOnePdf);
        return;
      }
      final file = pickedFiles.single;
      if (file.extension?.toLowerCase() != 'pdf') {
        showSelectionMessage(context.l10n.onlyPdfFiles);
        return;
      }
      final size = await file.length();
      if (!mounted) return;
      if (size == 0) {
        showSelectionMessage(context.l10n.emptySheetFile);
        return;
      }
      if (size != null && size > maxPdfFileSize) {
        showSelectionMessage(context.l10n.pdfSizeLimit);
        return;
      }
      final pdf = SelectedSheetFile(
        name: file.name,
        bytes: await file.readAsBytes(),
        path: file.path,
      );
      if (!mounted) return;
      await selectPdf([pdf], pdf);
    } catch (_) {
      if (mounted) {
        showSelectionMessage(
          context.l10n.sheetFileReadFailed,
          type: AppSnackBarType.error,
        );
      }
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
    if (pdf.bytes.isEmpty) {
      showSelectionMessage(context.l10n.emptySheetFile);
      return;
    }

    try {
      await pdfrxFlutterInitialize();
      final document = await PdfDocument.openData(pdf.bytes, sourceName: pdf.name);
      try {
      final pageCount = document.pages.length;
      if (!mounted) return;

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

      final accepted = await validateSheetSelection(
        (onProgress, isCancelled) => sheetValidationService.validatePdf(
          document,
          onProgress: onProgress,
          isCancelled: isCancelled,
        ),
      );
      if (!accepted || !mounted) return;

      setState(() {
        selectedSheets = [pdf];
        selectedPdfPageCount = pageCount;
      });
      } finally {
        await document.dispose();
      }
    } catch (_) {
      if (!mounted) return;
      showSelectionMessage(
        context.l10n.pdfReadFailed,
        type: AppSnackBarType.error,
      );
    }
  }

  Future<bool> validateSheetSelection(
    Future<SheetMusicVerdict> Function(
      void Function(int page, int total) onProgress,
      bool Function() isCancelled,
    ) validate,
  ) async {
    if (!mounted || isCheckingSheet) return false;
    setState(() => isCheckingSheet = true);
    final colors = AppThemeColors.fromDarkMode(isDarkMode);
    final progress = ValueNotifier<({int page, int total})>((page: 1, total: 1));
    final navigator = Navigator.of(context, rootNavigator: true);
    var cancelled = false;
    late final DialogRoute<void> route;
    route = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValueListenableBuilder<({int page, int total})>(
        valueListenable: progress,
        builder: (_, status, _) => SheetMusicCheckingDialog(
          colors: colors,
          page: status.page,
          total: status.total,
          onCancel: () {
            cancelled = true;
            if (route.isActive) navigator.removeRoute(route);
          },
        ),
      ),
    );
    unawaited(navigator.push(route));
    try {
      final SheetMusicVerdict verdict;
      try {
        verdict = await validate(
          (page, total) {
            if (mounted && !cancelled) progress.value = (page: page, total: total);
          },
          () => cancelled || !mounted,
        );
      } finally {
        if (route.isActive) navigator.removeRoute(route);
        progress.dispose();
      }
      if (!mounted || cancelled) return false;
      if (verdict == SheetMusicVerdict.likelyMusic) return true;
      return await showDialog<bool>(
        context: context,
        builder: (_) => SheetMusicValidationDialog(
          colors: colors,
          isUncertain: verdict == SheetMusicVerdict.uncertain,
        ),
      ) == true;
    } on SheetMusicValidationCancelled {
      return false;
    } catch (_) {
      if (mounted && !cancelled) {
        showSelectionMessage(
          context.l10n.sheetMusicCheckFailed,
          type: AppSnackBarType.error,
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => isCheckingSheet = false);
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
    if (isBusy) return;
    setState(() => isCapturingSheet = true);
    try {
      await _captureSheet();
    } on PlatformException catch (error) {
      if (!mounted) return;
      final code = error.code.toLowerCase();
      final permissionDenied = code.contains('camera') &&
          (code.contains('denied') || code.contains('restricted') ||
           code.contains('permission'));
      showSelectionMessage(
        permissionDenied
            ? context.l10n.sheetCameraPermissionDenied
            : context.l10n.sheetCaptureFailed,
        type: AppSnackBarType.error,
      );
    } catch (_) {
      if (mounted) {
        showSelectionMessage(
          context.l10n.sheetCaptureFailed,
          type: AppSnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => isCapturingSheet = false);
    }
  }

  Future<void> _captureSheet() async {
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
      maxWidth: 2400,
      maxHeight: 3200,
    );

    if (image == null) return;
    if (!mounted) return;

    final size = await image.length();
    if (!mounted) return;
    if (size > maxImageFileSize) {
      showSelectionMessage(context.l10n.capturedImageSizeLimit);
      return;
    }

    final bytes = await image.readAsBytes();
    if (!mounted) return;
    if (bytes.isEmpty) {
      showSelectionMessage(context.l10n.emptySheetFile);
      return;
    }

    if (bytes.length > maxImageFileSize) {
      showSelectionMessage(context.l10n.capturedImageSizeLimit);
      return;
    }

    if (!mounted) return;

    final accepted = await validateSheetSelection(
      (_, _) => sheetValidationService.validateImage(bytes),
    );
    if (!accepted || !mounted) return;

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
      uploadProgress.value = 0;
    });
    try {
      await withSavingDialog(
        colors,
        () => audioUploadService.saveAudio(
          title: title,
          file: file,
          onProgress: (progress) {
            if (mounted) uploadProgress.value = progress;
          },
        ),
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
        uploadProgress.value = 0;
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
      uploadProgress.value = null;
    });

    SelectedAudioFile? preparedAudio;
    var uploading = false;
    try {
      await withSavingDialog(colors, () async {
        final audio = await videoAudioService.prepareAudio(video);
        preparedAudio = audio;
        if (!mounted) return;
        setState(() => isPreparingAudio = false);
        uploadProgress.value = 0;
        uploading = true;
        await audioUploadService.saveAudio(
          title: title,
          file: audio,
          onProgress: (progress) {
            if (mounted) uploadProgress.value = progress;
          },
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isSavingSheet = false;
        isPreparingAudio = false;
        uploadProgress.value = 0;
      });
      showSelectionMessage(
        uploading
            ? context.l10n.audioSaveFailed
            : context.l10n.videoPreparationFailed,
        type: AppSnackBarType.error,
      );
      return;
    } finally {
      final audioToCleanUp = preparedAudio;
      if (audioToCleanUp != null) {
        try {
          await audioToCleanUp.cleanUp();
        } catch (_) {}
      }
    }

    if (!mounted) return;
    setState(() {
      selectedVideo = null;
      isSavingSheet = false;
      uploadProgress.value = 0;
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
