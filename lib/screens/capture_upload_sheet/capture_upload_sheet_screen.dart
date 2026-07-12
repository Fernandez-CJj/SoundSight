import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:soundsight/constants/constant.dart';
import 'package:soundsight/theme/app_theme_colors.dart';
import 'package:soundsight/widgets/drawer.dart';

class CaptureUploadSheetScreen extends StatefulWidget {
  const CaptureUploadSheetScreen({super.key, this.isDarkMode});

  final bool? isDarkMode;

  @override
  State<CaptureUploadSheetScreen> createState() =>
      _CaptureUploadSheetScreenState();
}

class _CaptureUploadSheetScreenState extends State<CaptureUploadSheetScreen> {
  late bool isDarkMode;
  List<PlatformFile> selectedSheets = [];
  bool isPickingFiles = false;
  final ImagePicker imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode ?? false;
    loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.fromDarkMode(isDarkMode);
    final iconBackground = isDarkMode
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.04);
    final cardBorder = isDarkMode
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.07);
    final cardShadow = isDarkMode
        ? Colors.black.withOpacity(0.30)
        : Colors.black.withOpacity(0.08);

    return Scaffold(
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
      ),
      drawer: AppDrawer(
        isDarkMode: isDarkMode,
        activeItem: DrawerItem.captureUpload,
        onDarkModeChanged: (value) {
          setState(() {
            isDarkMode = value;
          });
        },
      ),
      body: Container(
        width: double.infinity,
        color: colors.backgroundColor,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            children: [
              Text(
                'Choose how you want to add your sheet music.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: AppTextSizes.label,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Gap(AppSpacing.xl),
              SizedBox(
                height: 132,
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: colors.surfaceColor,
                  shadowColor: cardShadow,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    side: BorderSide(color: cardBorder),
                  ),
                  child: InkWell(
                    onTap: pickSheets,

                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: iconBackground,
                            child: Icon(
                              Icons.upload_file_outlined,
                              color: colors.primaryColor,
                              size: 34,
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Upload Sheet',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.primaryColor,
                                    fontSize: AppTextSizes.body,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Gap(AppSpacing.xs),
                                Text(
                                  'Import images or PDFs\nfrom your device.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.secondaryTextColor,
                                    fontSize: AppTextSizes.caption,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.primaryColor,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(AppSpacing.lg),
              SizedBox(
                height: 132,
                child: Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: colors.surfaceColor,
                  shadowColor: cardShadow,
                  surfaceTintColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    side: BorderSide(color: cardBorder),
                  ),
                  child: InkWell(
                    onTap: captureSheet,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: iconBackground,
                            child: Icon(
                              Icons.camera_alt_outlined,
                              color: colors.primaryColor,
                              size: 34,
                            ),
                          ),
                          const Gap(AppSpacing.md),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Capture Sheet',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.primaryColor,
                                    fontSize: AppTextSizes.body,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Gap(AppSpacing.xs),
                                Text(
                                  'Take a photo of printed\nsheet music.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: colors.secondaryTextColor,
                                    fontSize: AppTextSizes.caption,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(AppSpacing.sm),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: colors.primaryColor,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (selectedSheets.isNotEmpty) ...[
                const Gap(AppSpacing.xl),

                Text(
                  'Selected Files',
                  style: TextStyle(
                    color: colors.primaryColor,
                    fontSize: AppTextSizes.body,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const Gap(AppSpacing.sm),

                ...List.generate(selectedSheets.length, (index) {
                  final file = selectedSheets[index];
                  final isPdf = file.extension?.toLowerCase() == 'pdf';

                  return Dismissible(
                    key: ValueKey('${file.name}-$index'),
                    direction: DismissDirection.startToEnd,

                    background: Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.only(left: AppSpacing.md),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                      ),
                    ),

                    confirmDismiss: (direction) async {
                      final shouldDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: colors.surfaceColor,
                            title: Text(
                              'Remove file?',
                              style: TextStyle(
                                color: colors.primaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            content: Text(
                              'Do you want to remove ${file.name}?',
                              style: TextStyle(
                                color: colors.secondaryTextColor,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false);
                                },
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: colors.secondaryTextColor,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                child: const Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        },
                      );

                      return shouldDelete ?? false;
                    },

                    onDismissed: (direction) {
                      setState(() {
                        selectedSheets.removeAt(index);
                      });
                    },

                    child: Card(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      color: colors.surfaceColor,
                      surfaceTintColor: Colors.transparent,
                      child: ListTile(
                        onTap: () {
                          viewSelectedSheet(file);
                        },
                        leading: Icon(
                          isPdf
                              ? Icons.picture_as_pdf_outlined
                              : Icons.image_outlined,
                          color: colors.primaryColor,
                        ),
                        title: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.primaryColor,
                            fontSize: AppTextSizes.label,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${(file.size / 1024).toStringAsFixed(1)} KB',
                          style: TextStyle(
                            color: colors.secondaryTextColor,
                            fontSize: AppTextSizes.caption,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
              const Gap(AppSpacing.xl),
              Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: colors.primaryColor,
                    size: 22,
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    'For better results',
                    style: TextStyle(
                      color: colors.primaryColor,
                      fontSize: AppTextSizes.label,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const Gap(AppSpacing.md),
              Row(
                children: [
                  Icon(
                    Icons.wb_sunny_outlined,
                    color: colors.secondaryTextColor,
                    size: 17,
                  ),
                  const Gap(AppSpacing.sm),
                  Text(
                    'Use good, even lighting.',
                    style: TextStyle(
                      color: colors.secondaryTextColor,
                      fontSize: AppTextSizes.caption,
                    ),
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.table_bar_outlined,
                    color: colors.secondaryTextColor,
                    size: 17,
                  ),
                  const Gap(AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Place the sheet music flat on a surface.',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.center_focus_strong_outlined,
                    color: colors.secondaryTextColor,
                    size: 17,
                  ),
                  const Gap(AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Ensure the entire page is visible and clear.',
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: AppTextSizes.caption,
                      ),
                    ),
                  ),
                ],
              ),
            ],
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

  Future<void> pickSheets() async {
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

      const int maxFileSize = 20 * 1024 * 1024;

      final validFiles = result.files.where((file) {
        return file.size <= maxFileSize;
      }).toList();

      final oversizedFiles = result.files.where((file) {
        return file.size > maxFileSize;
      }).toList();

      if (oversizedFiles.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${oversizedFiles.length} file/s were too large. Max file size is 20 MB.',
            ),
          ),
        );
      }
      setState(() {
        selectedSheets = validFiles;
      });
    } finally {
      if (mounted) {
        setState(() {
          isPickingFiles = false;
        });
      }
    }
  }

  void viewSelectedSheet(PlatformFile file) {
    final isPdf = file.extension?.toLowerCase() == 'pdf';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: AppTextSizes.body,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),

                const Gap(AppSpacing.md),

                if (isPdf && file.bytes != null)
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    width: double.infinity,
                    child: PdfViewer.data(file.bytes!, sourceName: file.name),
                  )
                else if (file.bytes != null)
                  SizedBox(
                    height: 400,
                    child: InteractiveViewer(
                      child: Image.memory(file.bytes!, fit: BoxFit.contain),
                    ),
                  )
                else
                  const Text('Preview is not available.'),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> captureSheet() async {
    final image = await imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (image == null) return;

    final bytes = await image.readAsBytes();

    final capturedFile = PlatformFile(
      name: image.name,
      size: bytes.length,
      bytes: bytes,
      path: image.path,
    );

    setState(() {
      selectedSheets.add(capturedFile);
    });
  }
}
