import 'package:isar/isar.dart';

part 'achievement_models.g.dart';

@Collection()
class StudentProfile {
  Id id = Isar.autoIncrement;

  int totalXp = 0;
  String currentTier = 'Jigyasu';
  List<String> unlockedBadges = const ['jigyasu_bronze'];
}

@Collection()
class TopicProgress {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String topicId;

  bool hasViewedAr = false;
  bool hasPassedQuiz = false;

  int arXpEarned = 0;
  int quizXpEarned = 0;
  bool synergyApplied = false;
}
