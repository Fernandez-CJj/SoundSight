import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/screens/capture_upload_sheet/capture_tips_container.dart';
import 'package:soundsight/screens/capture_upload_sheet/capture_upload_dialogs.dart';
import 'package:soundsight/screens/capture_upload_sheet/capture_upload_header.dart';
import 'package:soundsight/screens/capture_upload_sheet/music_sheet_upload_service.dart';
import 'package:soundsight/screens/capture_upload_sheet/save_sheet_container.dart';
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
  List<PlatformFile> selectedSheets = [];
  int? selectedPdfPageCount;
  bool isPickingFiles = false;
  bool isSavingSheet = false;
  double uploadProgress = 0;

  final ImagePicker imagePicker = ImagePicker();
  final MusicSheetUploadService uploadService = MusicSheetUploadService();

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
            'Add Sheet',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: AppTextSizes.sectionTitle,
            ),
          ),
          actions: [
            if (selectedSheets.isNotEmpty)
              IconButton(
                tooltip: 'Delete all selected files',
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
                isSavingSheet: isSavingSheet,
                onUpload: pickSheets,
                onCapture: captureSheet,
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
              Gap(AppSpacing.xl),
              CaptureTipsContainer(colors: colors),
            ],
          ),
        ),
        bottomNavigationBar: selectedSheets.isEmpty
            ? null
            : SaveSheetContainer(
                colors: colors,
                isSavingSheet: isSavingSheet,
                uploadProgress: uploadProgress,
                onSave: isPickingFiles
                    ? null
                    : () => saveSelectedSheets(colors),
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
      showSelectionMessage('You need to sign in before saving a sheet.');
      return;
    }

    final title = await showDialog<String>(
      context: context,
      builder: (_) => SheetTitleDialog(
        colors: colors,
        initialTitle: getInitialSheetTitle(),
      ),
    );

    if (title == null || !mounted) return;

    final files = List<PlatformFile>.from(selectedSheets);
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

  String getInitialSheetTitle() {
    final fileName = selectedSheets.first.name;
    final extensionIndex = fileName.lastIndexOf('.');
    final title = extensionIndex > 0
        ? fileName.substring(0, extensionIndex)
        : fileName;

    if (title.isEmpty) return 'Untitled Sheet';
    return title.length > 80 ? title.substring(0, 80) : title;
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
    if (isSavingSheet) return;

    final hasSelectedPdf = selectedSheets.any((file) {
      return file.extension?.toLowerCase() == 'pdf';
    });

    if (hasSelectedPdf) {
      showSelectionMessage(
        'Remove the selected PDF before adding another file.',
      );
      return;
    }

    if (selectedSheets.length >= maxSheetPages) {
      showSelectionMessage(
        'You already selected the maximum of $maxSheetPages images.',
      );
      return;
    }

    setState(() {
      isPickingFiles = true;
    });

    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        withData: true,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result == null) return;

      final pdfFiles = result.files.where((file) {
        return file.extension?.toLowerCase() == 'pdf';
      }).toList();

      if (pdfFiles.isNotEmpty) {
        await selectPdf(result.files, pdfFiles.singleOrNull);
        return;
      }

      selectImages(result.files);
    } finally {
      if (mounted) {
        setState(() {
          isPickingFiles = false;
        });
      }
    }
  }

  Future<void> selectPdf(
    List<PlatformFile> pickedFiles,
    PlatformFile? pdf,
  ) async {
    if (pickedFiles.length != 1 || pdf == null) {
      showSelectionMessage(
        'Select either 1 PDF or up to $maxSheetPages images. PDFs cannot be mixed with images.',
      );
      return;
    }

    if (selectedSheets.isNotEmpty) {
      showSelectionMessage('Remove the selected images before choosing a PDF.');
      return;
    }

    if (pdf.size > maxPdfFileSize) {
      showSelectionMessage('The PDF must be 20 MB or smaller.');
      return;
    }

    try {
      final pageCount = await getPdfPageCount(pdf);

      if (pageCount < 1) {
        showSelectionMessage('The PDF does not contain any pages.');
        return;
      }

      if (pageCount > maxSheetPages) {
        showSelectionMessage(
          'This PDF has $pageCount pages. The maximum is $maxSheetPages pages.',
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
        'The PDF could not be read. Make sure it is a valid, unlocked PDF.',
      );
    }
  }

  void selectImages(List<PlatformFile> pickedFiles) {
    final oversizedImages = pickedFiles.where((file) {
      return file.size > maxImageFileSize;
    }).toList();
    final allowedImages = pickedFiles.where((file) {
      return file.size <= maxImageFileSize;
    }).toList();
    final newImages = allowedImages.where((file) {
      return !selectedSheets.any((selectedFile) {
        return selectedFile.name == file.name && selectedFile.size == file.size;
      });
    }).toList();
    final remainingSlots = maxSheetPages - selectedSheets.length;
    final imagesToAdd = newImages.take(remainingSlots).toList();
    final duplicateCount = allowedImages.length - newImages.length;
    final messages = <String>[];

    if (oversizedImages.isNotEmpty) {
      messages.add(
        '${oversizedImages.length} image(s) were skipped because each image must be 5 MB or smaller.',
      );
    }

    if (duplicateCount > 0) {
      messages.add('$duplicateCount duplicate image(s) were skipped.');
    }

    if (newImages.length > remainingSlots) {
      messages.add('Only $remainingSlots more image(s) could be added.');
    }

    if (messages.isNotEmpty) {
      showSelectionMessage(messages.join(' '));
    }

    if (imagesToAdd.isEmpty || !mounted) return;

    setState(() {
      selectedSheets.addAll(imagesToAdd);
      selectedPdfPageCount = null;
    });
  }

  Future<int> getPdfPageCount(PlatformFile pdf) async {
    final bytes = pdf.bytes;
    if (bytes == null) throw Exception('PDF data is unavailable.');

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

  void viewSelectedSheet(PlatformFile file, AppThemeColors colors) {
    showDialog<void>(
      context: context,
      builder: (_) => SelectedSheetPreviewDialog(colors: colors, file: file),
    );
  }

  Future<void> captureSheet() async {
    if (isSavingSheet || isPickingFiles) return;

    final hasSelectedPdf = selectedSheets.any((file) {
      return file.extension?.toLowerCase() == 'pdf';
    });

    if (hasSelectedPdf) {
      showSelectionMessage(
        'Remove the selected PDF before adding captured images.',
      );
      return;
    }

    if (selectedSheets.length >= maxSheetPages) {
      showSelectionMessage('You can only add up to $maxSheetPages images.');
      return;
    }

    final image = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    if (bytes.length > maxImageFileSize) {
      showSelectionMessage(
        'The captured image is larger than 5 MB. Try capturing it again.',
      );
      return;
    }

    if (!mounted) return;

    final capturedFile = PlatformFile(
      name: image.name,
      size: bytes.length,
      bytes: bytes,
      path: image.path,
    );

    setState(() {
      selectedSheets.add(capturedFile);
      selectedPdfPageCount = null;
    });
  }

  void showSelectionMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
