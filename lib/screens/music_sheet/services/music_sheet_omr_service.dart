import 'package:soundsight/services/processing_job_service.dart';

class MusicSheetOmrService {
  Future<ProcessingJob> recognizeMusicSheet({required String sheetId}) =>
      ProcessingJobService().submit(
        '/music-sheets/${Uri.encodeComponent(sheetId)}/recognize',
      );
}
