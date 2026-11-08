import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/onboarding/tours/feature_tour_catalog.dart';
import 'package:soundsight/widgets/processing_job_card.dart';

/// Counts the next page from its data before that page is opened.
class FeatureTourStepCounts {
  static int musicSheetViewer({
    required String type,
    required List<Map<String, dynamic>> files,
    required Map<String, dynamic> data,
  }) {
    var count = 1; // The Play choices are always present.
    final jobStatus = data['lastJobStatus'] as String?;
    final recognizedPdf = (data['recognizedPdfStoragePath'] as String? ?? '').isNotEmpty;
    if (type == 'audio') {
      if (files.isEmpty || (files.first['storagePath'] as String? ?? '').isEmpty) return count;
      count++; // Listen to the uploaded audio.
      if (ProcessingJobCard.isVisible(jobStatus)) count++;
      final hasScore = data['transcriptionStatus'] == 'completed' && recognizedPdf &&
          ['midiStoragePath', 'musicXmlStoragePath', 'previewAudioStoragePath'].every(
            (key) => (data[key] as String? ?? '').isNotEmpty,
          );
      if (hasScore) count++; // Open the PDF in a bigger window.
      return count;
    }
    if (files.isEmpty && !recognizedPdf) return count;
    final hasAudio = data['omrStatus'] != 'processing' &&
        (data['previewAudioStoragePath'] as String? ?? '').isNotEmpty;
    final hasStatusCard = data['activeJobId'] == null &&
        !{'submitting', 'submissionFailed', 'queued', 'processing'}.contains(jobStatus);
    if (ProcessingJobCard.isVisible(jobStatus) || hasStatusCard || hasAudio) count++;
    if (recognizedPdf) count++; // Original/recognized sheet switch.
    if (recognizedPdf || type == 'pdf' && files.isNotEmpty) count++;
    if (hasAudio) count++;
    return count;
  }

  static int compositionDetails(Composition composition) =>
      featureTourCatalog['composition_details']!.length -
      (composition.hasActiveJob && !composition.generatedFilesAreCurrent ? 1 : 0);

  static int compositionEditor(Composition composition) =>
      composition.creationMethod == Composition.recordingCreationMethod ||
          composition.hasActiveJob
      ? 0 : featureTourCatalog['manual_composition']!.length;

  static int compositionJourney(Composition composition) =>
      compositionDetails(composition) + compositionEditor(composition);
}
