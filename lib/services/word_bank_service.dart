import 'dart:convert';
import 'package:flutter/material.dart';
import '../screens/student/home_screen.dart';
import 'background_dictionary_loader.dart';

class WordBankService {
  static final WordBankService _instance = WordBankService._internal();
  List<WordData> allWords = [];
  bool _isLoaded = false;

  WordBankService._internal();

  factory WordBankService() {
    return _instance;
  }

  Future<void> init() async {
    if (_isLoaded) return;
    await _loadWords();
  }

  Future<void> _loadWords() async {
    try {
      final loader = BackgroundDictionaryLoader();
      final jsonString = await loader.loadDictionary();

      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('⚠️ Dictionary not available yet, using sample words');
        allWords = _getSampleWords();
        return;
      }

      final dynamic decoded = jsonDecode(jsonString);
      allWords = [];

      // Handle different JSON formats
      if (decoded is List) {
        // Format: [{"word": "...", "meanings": [...]}]
        for (var item in decoded) {
          try {
            final wordMap = item as Map<String, dynamic>;
            final word = _parseWord(wordMap);
            if (word != null) allWords.add(word);
          } catch (e) {
            // Skip invalid entries
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        // Format: {"word1": "definition1", "word2": "definition2"}
        decoded.forEach((key, value) {
          allWords.add(WordData(
            word: key,
            meaning: value.toString(),
            usage: '',
            partOfSpeech: 'Unknown',
            difficulty: 'intermediate',
          ));
        });
      }

      _isLoaded = true;
      debugPrint('📚 Loaded ${allWords.length} words from dictionary');
    } catch (e) {
      debugPrint('❌ Error loading dictionary: $e');
      allWords = _getSampleWords();
    }
  }

  WordData? _parseWord(Map<String, dynamic> json) {
    final word = json['word'] as String? ?? '';
    if (word.isEmpty) return null;

    // Try different field structures
    final meanings = json['meanings'] as List<dynamic>? ?? [];

    String definition = '';
    String example = '';
    String partOfSpeech = 'Unknown';

    if (meanings.isNotEmpty) {
      final firstMeaning = meanings[0] as Map<String, dynamic>;
      partOfSpeech = firstMeaning['partOfSpeech'] as String? ?? 'Unknown';

      final definitions = firstMeaning['definitions'] as List<dynamic>? ?? [];
      if (definitions.isNotEmpty) {
        final firstDef = definitions[0] as Map<String, dynamic>;
        definition = firstDef['definition'] as String? ?? '';
        example = firstDef['example'] as String? ?? '';
      }
    } else {
      // Simple format fallback
      definition =
          json['meaning'] as String? ?? json['definition'] as String? ?? '';
      example = json['usage'] as String? ?? json['example'] as String? ?? '';
      partOfSpeech = json['partOfSpeech'] as String? ?? 'Unknown';
    }

    return WordData(
      word: word,
      meaning: definition,
      usage: example,
      partOfSpeech: partOfSpeech,
      difficulty: _getDifficulty(word.length),
    );
  }

  String _getDifficulty(int length) {
    if (length < 6) return 'beginner';
    if (length < 10) return 'intermediate';
    return 'advanced';
  }

  List<WordData> _getSampleWords() {
    return [
      WordData(
        word: 'Able',
        meaning: 'Having power, skill, or means to do something',
        usage: 'She is able to speak five languages',
        partOfSpeech: 'Adjective',
        difficulty: 'beginner',
      ),
      WordData(
        word: 'Serendipity',
        meaning: 'The occurrence of events by chance in a happy way',
        usage: 'It was pure serendipity that we met',
        partOfSpeech: 'Noun',
        difficulty: 'advanced',
      ),
      WordData(
        word: 'Eloquent',
        meaning: 'Fluent or persuasive in speaking or writing',
        usage: 'The speaker gave an eloquent speech',
        partOfSpeech: 'Adjective',
        difficulty: 'intermediate',
      ),
    ];
  }

  WordData getWordOfDay() {
    if (allWords.isEmpty) {
      return WordData(
        word: 'Dictionary',
        meaning:
            'A book or electronic resource that lists words and their meanings',
        usage: 'I use a dictionary to find word meanings',
        partOfSpeech: 'Noun',
        difficulty: 'beginner',
      );
    }
    return allWords[DateTime.now().day % allWords.length];
  }

  List<WordData> searchWords(String query) {
    if (query.isEmpty || allWords.isEmpty) return [];
    return allWords
        .where((w) => w.word.toLowerCase().startsWith(query.toLowerCase()))
        .take(20)
        .toList();
  }

  /// Reload dictionary after download completes
  Future<void> reload() async {
    _isLoaded = false;
    await _loadWords();
  }
}
