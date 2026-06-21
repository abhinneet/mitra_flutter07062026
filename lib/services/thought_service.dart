import 'package:flutter/material.dart';

class ThoughtData {
  final String quote;
  final String author;
  final String profession;

  const ThoughtData({
    required this.quote,
    required this.author,
    required this.profession,
  });

  factory ThoughtData.fromJson(Map<String, dynamic> json) {
    return ThoughtData(
      quote: json['quote'] as String? ?? '',
      author: json['author'] as String? ?? '',
      profession: json['profession'] as String? ?? '',
    );
  }
}

class ThoughtService {
  static final ThoughtService _instance = ThoughtService._internal();
  late List<ThoughtData> allThoughts = [];

  ThoughtService._internal();

  factory ThoughtService() {
    return _instance;
  }

  Future<void> init() async {
    await _loadThoughts();
  }

  Future<void> _loadThoughts() async {
    try {
      // TODO: Replace with actual sheet data fetch
      allThoughts = _getSampleThoughts();
      debugPrint('💭 Loaded ${allThoughts.length} thoughts');
    } catch (e) {
      debugPrint('❌ Error loading thoughts: $e');
      allThoughts = _getSampleThoughts();
    }
  }

  List<ThoughtData> _getSampleThoughts() {
    return const [
      ThoughtData(
        quote:
            'Success is not final, failure is not fatal. It is the courage to continue that counts.',
        author: 'Winston Churchill',
        profession: 'Statesman',
      ),
      ThoughtData(
        quote:
            'Your education is a dress rehearsal for a life that is yours to lead.',
        author: 'Nora Ephron',
        profession: 'Writer',
      ),
      ThoughtData(
        quote:
            'Learning is not attainment of knowledge but acquisition of skills.',
        author: 'Unknown',
        profession: 'Educator',
      ),
      ThoughtData(
        quote: 'Excellence is not a destination; it is a continuous journey.',
        author: 'Ralph Marston',
        profession: 'Author',
      ),
      ThoughtData(
        quote: 'The only way to do great work is to love what you do.',
        author: 'Steve Jobs',
        profession: 'Entrepreneur',
      ),
    ];
  }

  /// Get thought of the day (changes daily at 12:00 AM)
  ThoughtData getThoughtOfDay() {
    if (allThoughts.isEmpty) {
      return const ThoughtData(
        quote: 'Every day is a new opportunity to grow.',
        author: 'Unknown',
        profession: 'Mentor',
      );
    }

    // Calculate days since epoch to get consistent daily index
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final epoch = DateTime(1970, 1, 1);
    final daysSinceEpoch = today.difference(epoch).inDays;

    return allThoughts[daysSinceEpoch % allThoughts.length];
  }
}
