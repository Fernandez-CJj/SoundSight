import 'package:soundsight/services/processing_job_service.dart';

class MusicSheetTranscriptionService {
  Future<ProcessingJob> transcribeAudio({required String sheetId}) =>
      ProcessingJobService().submit(
        '/music-sheets/${Uri.encodeComponent(sheetId)}/transcribe-audio',
      );
}
