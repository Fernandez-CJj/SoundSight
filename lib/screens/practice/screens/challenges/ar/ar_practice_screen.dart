import 'package:flutter/material.dart';

import '../../../../piano_calibration/models/piano_calibration_summary.dart';
import '../../../../piano_calibration/piano_calibration_screen.dart';
import '../../../../piano_calibration/services/piano_calibration_firestore_service.dart';
import '../../../../piano_calibration/models/saved_piano_calibration.dart';
import 'models/ar_score_timeline.dart';
import 'services/ar_score_timeline_loader.dart';

/// Entry screen for choosing which saved keyboard calibration to use in AR.
///
/// [scoreDocumentPath] identifies the selected challenge document whose MIDI
/// timeline will be loaded only after the user chooses a calibration.
class ArPracticeScreen extends StatefulWidget {
  const ArPracticeScreen({super.key, required this.scoreDocumentPath});

  /// Full Firestore document path of the challenge score.
  final String scoreDocumentPath;

  @override
  /// Creates stream, loading, and navigation state for calibration selection.
  State<ArPracticeScreen> createState() {
    return ArPracticeScreenState();
  }
}

/// Watches saved calibrations and prepares the selected score/calibration pair.
class ArPracticeScreenState extends State<ArPracticeScreen> {
  final PianoCalibrationFirestoreService calibrationFirestoreService =
      PianoCalibrationFirestoreService();

  final ArScoreTimelineLoader scoreTimelineLoader = ArScoreTimelineLoader();

  late Stream<List<PianoCalibrationSummary>> calibrationSummaries;
  String? loadingCalibrationId;

  @override
  /// Starts the user's saved-calibration stream when the screen opens.
  void initState() {
    super.initState();
    loadCalibrationSummaries();
  }

  @override
  /// Builds the calibration picker and new-calibration action.
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AR Practice')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openNewCalibration,
        icon: const Icon(Icons.add),
        label: const Text('New calibration'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Choose a piano calibration',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use a saved keyboard layout, or create a new one for '
                    'this piano and camera position.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),
                  Expanded(child: buildCalibrationList()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds loading, error, empty, or populated states from Firestore snapshots.
  Widget buildCalibrationList() {
    return StreamBuilder<List<PianoCalibrationSummary>>(
      stream: calibrationSummaries,
      builder: (BuildContext context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return buildLoadError();
        }

        List<PianoCalibrationSummary> calibrations = snapshot.data ?? [];

        if (calibrations.isEmpty) {
          return buildEmptyState();
        }

        return ListView.separated(
          itemCount: calibrations.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (BuildContext context, int index) {
            return buildCalibrationCard(calibrations[index]);
          },
        );
      },
    );
  }

  /// Builds one saved-calibration tile and its per-item loading indicator.
  Widget buildCalibrationCard(PianoCalibrationSummary calibration) {
    DateTime? lastSavedAt = calibration.updatedAt ?? calibration.createdAt;

    bool isLoading = loadingCalibrationId == calibration.documentId;
    bool loadingAnotherCalibration = loadingCalibrationId != null && !isLoading;

    return Card(
      child: ListTile(
        enabled: !loadingAnotherCalibration,
        onTap: loadingCalibrationId == null
            ? () {
                openSavedCalibration(calibration);
              }
            : null,
        leading: const CircleAvatar(child: Icon(Icons.piano)),
        title: Text(calibration.name),
        subtitle: Text(buildLastSavedText(lastSavedAt)),
        trailing: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }

  /// Explains how to create the user's first keyboard mapping.
  Widget buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.piano_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No saved calibrations yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a calibration to map the visible keys on your piano.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: openNewCalibration,
              icon: const Icon(Icons.add),
              label: const Text('Create calibration'),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a retry action when the calibration stream reports an error.
  Widget buildLoadError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load your calibrations.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: retryLoadingCalibrations,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  /// Formats a Firestore timestamp using the device's locale and time zone.
  String buildLastSavedText(DateTime? lastSavedAt) {
    if (lastSavedAt == null) {
      return 'Saved calibration';
    }

    DateTime localTime = lastSavedAt.toLocal();
    MaterialLocalizations localizations = MaterialLocalizations.of(context);
    String date = localizations.formatShortDate(localTime);
    String time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(localTime),
    );

    return 'Last saved $date at $time';
  }

  /// Replaces [calibrationSummaries] with a fresh signed-in-user stream.
  void loadCalibrationSummaries() {
    calibrationSummaries = calibrationFirestoreService
        .watchCalibrationSummaries();
  }

  /// Rebuilds the stream after a loading failure.
  void retryLoadingCalibrations() {
    setState(loadCalibrationSummaries);
  }

  /// Loads full geometry and the score timeline before opening review/practice.
  ///
  /// A loading ID disables duplicate taps while both network operations run.
  Future<void> openSavedCalibration(PianoCalibrationSummary summary) async {
    if (loadingCalibrationId != null) {
      return;
    }

    setState(() {
      loadingCalibrationId = summary.documentId;
    });

    try {
      SavedPianoCalibration savedCalibration = await calibrationFirestoreService
          .loadCalibration(documentId: summary.documentId);

      ArScoreTimeline scoreTimeline = await scoreTimelineLoader.load(
        scoreDocumentPath: widget.scoreDocumentPath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        loadingCalibrationId = null;
      });

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) {
            return PianoCalibrationScreen(
              savedCalibration: savedCalibration,
              scoreTimeline: scoreTimeline,
            );
          },
        ),
      );
    } catch (error) {
      debugPrint('Calibration or score loading failed: $error');

      if (!mounted) {
        return;
      }

      setState(() {
        loadingCalibrationId = null;
      });

      String errorMessage = error is ArScoreTimelineLoadException
          ? error.message
          : 'Could not load the selected calibration.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }

  /// Opens an empty calibration workflow without a practice score.
  Future<void> openNewCalibration() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PianoCalibrationScreen()),
    );
  }

  @override
  /// Closes the timeline loader's owned HTTP client.
  void dispose() {
    scoreTimelineLoader.dispose();
    super.dispose();
  }
}
