import '../../ar/models/ar_score_timeline.dart';

class SynthesiaScore {
  const SynthesiaScore({
    required this.title,
    required this.timeline,
    this.audioUrl,
  });

  final String title;
  final ArScoreTimeline timeline;
  final String? audioUrl;
}
