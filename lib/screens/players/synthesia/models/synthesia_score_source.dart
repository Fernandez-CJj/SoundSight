import 'package:soundsight/screens/composition/models/composition.dart';
import 'package:soundsight/screens/composition/models/published_composition.dart';

sealed class SynthesiaScoreSource {
  const SynthesiaScoreSource();
}

class SynthesiaCompositionSource extends SynthesiaScoreSource {
  const SynthesiaCompositionSource(this.composition);

  final Composition composition;
}

class SynthesiaPublishedCompositionSource extends SynthesiaScoreSource {
  const SynthesiaPublishedCompositionSource(this.composition);

  final PublishedComposition composition;
}

class SynthesiaDocumentSource extends SynthesiaScoreSource {
  const SynthesiaDocumentSource({
    required this.documentPath,
    required this.fallbackTitle,
  });

  final String documentPath;
  final String fallbackTitle;
}
