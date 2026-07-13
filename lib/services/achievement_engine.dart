import 'package:isar/isar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/achievement_models.dart';

class AchievementEngine {
  final Isar isar;
  const AchievementEngine(this.isar);

  /// Call this when a student views an AR module for >60 seconds
  Future<void> recordArView(String topicId) async {
    await isar.writeTxn(() async {
      // ✨ FIX: Explicitly target the collection by type to avoid pluralization errors
      final topicCollection = isar.collection<TopicProgress>();

      var progress =
          await topicCollection.filter().topicIdEqualTo(topicId).findFirst() ??
              (TopicProgress()..topicId = topicId);

      if (progress.hasViewedAr) return; // Prevent XP spamming

      progress.hasViewedAr = true;
      progress.arXpEarned = 20; // Base + Observation XP allocation

      // ✨ FIX: Force strict integer math to avoid double-to-int assignment errors
      int xpGained = progress.arXpEarned.toInt();
      if (progress.hasPassedQuiz && !progress.synergyApplied) {
        xpGained +=
            (progress.arXpEarned.toInt() + progress.quizXpEarned.toInt());
        progress.synergyApplied = true;
      }

      await topicCollection.put(progress);
      await _updateGlobalXp(xpGained);
    });
  }

  /// Call this when a student finishes a quiz
  Future<void> recordQuizPass(String topicId,
      {required bool perfectScore}) async {
    await isar.writeTxn(() async {
      final topicCollection = isar.collection<TopicProgress>();

      var progress =
          await topicCollection.filter().topicIdEqualTo(topicId).findFirst() ??
              (TopicProgress()..topicId = topicId);

      if (progress.hasPassedQuiz && !perfectScore) return;

      int newQuizXp = perfectScore ? 50 : 30;
      int xpDifference = newQuizXp - progress.quizXpEarned.toInt();

      progress.hasPassedQuiz = true;
      progress.quizXpEarned = newQuizXp;

      // ✨ FIX: Enforce strict integer conversions during synergy evaluation
      int xpGained = xpDifference;
      if (progress.hasViewedAr && !progress.synergyApplied) {
        xpGained +=
            (progress.arXpEarned.toInt() + progress.quizXpEarned.toInt());
        progress.synergyApplied = true;
      }

      await topicCollection.put(progress);
      await _updateGlobalXp(xpGained);
    });
  }

  /// Internal helper to update overall XP points, update Tiers, and assign Badges
  Future<void> _updateGlobalXp(int xpDelta) async {
    final profileCollection = isar.collection<StudentProfile>();
    var profile =
        await profileCollection.where().findFirst() ?? StudentProfile();

    // Ensure totalXp calculations use clear integer types
    profile.totalXp = (profile.totalXp.toInt() + xpDelta);

    if (profile.totalXp >= 10000) {
      profile.currentTier = 'Gyani';
      _addBadge(profile, 'gyani_diamond');
    } else if (profile.totalXp >= 5000) {
      profile.currentTier = 'Acharya';
      _addBadge(profile, 'acharya_gold');
    } else if (profile.totalXp >= 2000) {
      profile.currentTier = 'Vidwan';
      _addBadge(profile, 'vidwan_spark');
    } else if (profile.totalXp >= 500) {
      profile.currentTier = 'Anveshak';
      _addBadge(profile, 'anveshak_silver');
    } else {
      profile.currentTier = 'Jigyasu';
      _addBadge(profile, 'jigyasu_bronze');
    }

    await profileCollection.put(profile);
  }

  void _addBadge(StudentProfile profile, String badgeId) {
    var badges = List<String>.from(profile.unlockedBadges);
    if (!badges.contains(badgeId)) {
      badges.add(badgeId);
      profile.unlockedBadges = badges;
    }
  }
}

// ═══════════════════════════════════════════════════════
// ✨ GLOBAL RIVERPOD PROVIDER DEFINITION
// ═══════════════════════════════════════════════════════

// Core dependency injection provider for Isar (Ensure your local DB initialization hooks into this)
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError(
      'Initialize Isar in main.dart and override this provider.');
});

// Resolves the 'Undefined name achievementEngineProvider' crash in your UI screens
final achievementEngineProvider = Provider<AchievementEngine>((ref) {
  final isar = ref.watch(isarProvider);
  return AchievementEngine(isar);
});

// ✨ Listens to the local database in real-time. If XP changes, the UI updates instantly!
final studentProfileProvider = StreamProvider<StudentProfile>((ref) {
  final isar = ref.watch(isarProvider);
  return isar
      .collection<StudentProfile>()
      .where()
      .watch(fireImmediately: true)
      .map((profiles) =>
          profiles.isNotEmpty ? profiles.first : StudentProfile());
});
