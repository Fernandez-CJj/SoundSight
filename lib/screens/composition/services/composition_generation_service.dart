import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/services/processing_job_service.dart';

class CompositionGenerationService {
  Future<ProcessingJob> generateCompositionFiles(Composition composition) =>
      ProcessingJobService().submit(
        '/compositions/${Uri.encodeComponent(composition.id)}/generate',
      );
}
