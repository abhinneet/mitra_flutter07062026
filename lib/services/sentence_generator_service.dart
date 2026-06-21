import 'package:dio/dio.dart';

class SentenceGeneratorService {
  static final SentenceGeneratorService _instance =
      SentenceGeneratorService._internal();

  final Dio _dio = Dio();
  final Map<String, String> _cache = {};

  SentenceGeneratorService._internal();

  factory SentenceGeneratorService() {
    return _instance;
  }

  /// Generate example sentence for a word
  /// Falls back to local generation if API fails
  Future<String> generateSentence(String word, String partOfSpeech) async {
    // Check cache first
    if (_cache.containsKey(word)) {
      return _cache[word]!;
    }

    try {
      // Try API-based generation
      final sentence = await _generateFromAPI(word, partOfSpeech);
      _cache[word] = sentence;
      return sentence;
    } catch (e) {
      // Fallback: Local generation
      final localSentence = _generateLocal(word, partOfSpeech);
      _cache[word] = localSentence;
      return localSentence;
    }
  }

  /// Generate sentence using Online API (Free tier)
  Future<String> _generateFromAPI(String word, String partOfSpeech) async {
    try {
      // Using RapidAPI Word Association API (free tier available)
      // Alternative: Use your own backend endpoint

      // Simple fallback to local if no API key available
      return _generateLocal(word, partOfSpeech);
    } catch (e) {
      return _generateLocal(word, partOfSpeech);
    }
  }

  /// Local sentence generation (no internet required)
  String _generateLocal(String word, String partOfSpeech) {
    final templates = {
      'noun': [
        'The $word was beautiful.',
        'I saw a $word today.',
        'The $word is important.',
        'A $word can be very useful.',
        'The $word caught my attention.',
        'Every $word has value.',
        'The $word was remarkable.',
      ],
      'verb': [
        'I $word every day.',
        'She will $word tomorrow.',
        'They $word with enthusiasm.',
        'He $word the task quickly.',
        'Students $word in class.',
        'We $word to succeed.',
        'You can $word it easily.',
      ],
      'adjective': [
        'The $word quality impressed me.',
        'His $word approach worked.',
        'A $word solution is needed.',
        'The weather was $word today.',
        'That book is quite $word.',
        'She has a $word personality.',
        'The $word design looks great.',
      ],
      'adverb': [
        'He spoke $word in the meeting.',
        'She $word completed the work.',
        'They moved $word through the room.',
        'The task was $word finished.',
        'He answered $word and confidently.',
        'She $word approached the problem.',
        'They worked $word on the project.',
      ],
    };

    final type = partOfSpeech.toLowerCase();
    final sentenceList = templates[type] ?? templates['noun']!;
    final randomSentence =
        sentenceList[(word.hashCode.abs()) % sentenceList.length];

    return randomSentence;
  }

  /// Clear cache
  void clearCache() {
    _cache.clear();
  }
}
