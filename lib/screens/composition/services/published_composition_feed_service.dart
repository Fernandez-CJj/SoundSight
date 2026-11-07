import 'dart:async';

import 'package:soundsight/screens/composition/models/published_composition.dart';
import 'package:soundsight/screens/composition/services/published_composition_service.dart';
import 'package:soundsight/screens/composition/services/published_composition_social_service.dart';

class PublishedCompositionFeed {
  PublishedCompositionFeed(
    List<PublishedComposition> compositions,
    Map<String, int> likeCounts,
  ) : compositions = List.unmodifiable(compositions),
      _likeCounts = Map.unmodifiable(likeCounts);

  final List<PublishedComposition> compositions;
  final Map<String, int> _likeCounts;

  static String versionId(PublishedComposition composition) =>
      '${composition.id}/${composition.currentVersion}';

  int likesFor(PublishedComposition composition) =>
      _likeCounts[versionId(composition)] ?? 0;
}

class PublishedCompositionFeedService {
  final PublishedCompositionService compositionService =
      PublishedCompositionService();
  final PublishedCompositionSocialService socialService =
      PublishedCompositionSocialService();

  Stream<PublishedCompositionFeed> watch() {
    late final StreamController<PublishedCompositionFeed> controller;
    StreamSubscription<List<PublishedComposition>>? compositionsSubscription;
    final likeSubscriptions = <String, StreamSubscription<int>>{};
    final likeCounts = <String, int>{};
    final readyVersionIds = <String>{};
    var compositions = <PublishedComposition>[];
    var cancelled = false;

    void emitFeed() {
      if (cancelled ||
          !readyVersionIds.containsAll(
            compositions.map(PublishedCompositionFeed.versionId),
          )) {
        return;
      }
      controller.add(PublishedCompositionFeed(compositions, likeCounts));
    }

    void reportError(Object error, StackTrace stackTrace) {
      if (!cancelled) controller.addError(error, stackTrace);
    }

    controller = StreamController<PublishedCompositionFeed>(
      onListen: () {
        compositionsSubscription = compositionService
            .getPublishedCompositions()
            .listen((updatedCompositions) {
              if (cancelled) return;
              compositions = updatedCompositions;
              final activeVersionIds = compositions
                  .map(PublishedCompositionFeed.versionId)
                  .toSet();

              for (final versionId in likeSubscriptions.keys.toList()) {
                if (activeVersionIds.contains(versionId)) continue;
                unawaited(likeSubscriptions.remove(versionId)!.cancel());
                likeCounts.remove(versionId);
                readyVersionIds.remove(versionId);
              }

              for (final composition in compositions) {
                final versionId = PublishedCompositionFeed.versionId(composition);
                if (likeSubscriptions.containsKey(versionId)) continue;
                likeSubscriptions[versionId] = socialService
                    .getLikeCount(composition.id, composition.currentVersion)
                    .listen((count) {
                      if (cancelled || !activeVersionIds.contains(versionId)) {
                        return;
                      }
                      likeCounts[versionId] = count;
                      readyVersionIds.add(versionId);
                      emitFeed();
                    }, onError: reportError);
              }

              emitFeed();
            }, onError: reportError);
      },
      onCancel: () async {
        cancelled = true;
        await compositionsSubscription?.cancel();
        await Future.wait(
          likeSubscriptions.values.map((subscription) => subscription.cancel()),
        );
        likeSubscriptions.clear();
      },
    );

    return controller.stream;
  }
}
