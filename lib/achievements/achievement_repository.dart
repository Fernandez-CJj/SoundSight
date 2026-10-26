import 'package:cloud_firestore/cloud_firestore.dart';
import 'achievement_badge.dart';

class AchievementRepository {
  AchievementRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> forUser(String userId) =>
      _firestore.collection('users').doc(userId).collection('achievements');

  static Map<String, dynamic> awardData({
    bool migrated = false,
    String? sourceId,
  }) {
    final data = <String, dynamic>{
      'earnedAt': FieldValue.serverTimestamp(),
      'source': migrated ? 'migration' : 'earned',
    };
    if (sourceId != null) data['sourceId'] = sourceId;
    return data;
  }

  /// Copies progress saved by older app versions once, then Profile only needs
  /// the achievements collection. New awards are written at their source.
  Future<void> migrateExistingProgress(String userId) async {
    final profile = _firestore.collection('users').doc(userId);
    final user = await profile.get(const GetOptions(source: Source.server));
    if (!user.exists || user.data()?['achievementsMigrated'] == true) return;

    final data = user.data() ?? const <String, dynamic>{};
    final results = await Future.wait<dynamic>([
      profile
          .collection('assessment')
          .doc('current')
          .get(const GetOptions(source: Source.server)),
      profile
          .collection('musicSheets')
          .limit(1)
          .get(const GetOptions(source: Source.server)),
      profile
          .collection('compositions')
          .limit(1)
          .get(const GetOptions(source: Source.server)),
    ]);
    final assessment = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final sheets = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final compositions = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final candidates = <AchievementBadge>{};

    if (assessment.data()?['status'] == 'completed') {
      candidates.add(AchievementBadge.firstMeasure);
    }
    if (data['hasUploadedMusicSheet'] == true || sheets.docs.isNotEmpty) {
      candidates.add(AchievementBadge.sheetCollector);
    }
    if (data['hasCreatedComposition'] == true || compositions.docs.isNotEmpty) {
      candidates.add(AchievementBadge.firstComposer);
    }
    final level = (data['practiceLevel'] as num?)?.toInt() ?? 1;
    for (final stage in const [3, 6, 9, 12, 15, 16]) {
      if (level > stage) {
        candidates.add(AchievementBadge.forCompletedStage(stage)!);
      }
    }

    await _firestore.runTransaction<void>((transaction) async {
      final currentUser = await transaction.get(profile);
      if (!currentUser.exists ||
          currentUser.data()?['achievementsMigrated'] == true) {
        return;
      }
      final missing = <AchievementBadge>[];
      for (final badge in candidates) {
        final reference = forUser(userId).doc(badge.id);
        if (!(await transaction.get(reference)).exists) missing.add(badge);
      }
      for (final badge in missing) {
        transaction.set(
          forUser(userId).doc(badge.id),
          awardData(migrated: true),
        );
      }
      transaction.update(profile, {'achievementsMigrated': true});
    });
  }
}
