import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

// ── Constants ───────────────────────────────────────────
const String _kAssetPath = 'assets/data/quotes.json';

const List<QuoteData> _kFallbackQuotes = [
  QuoteData(
    index: 1,
    quote:
        'Success is not final, failure is not fatal. It is the courage to continue that counts.',
    author: 'Winston Churchill',
    profession: 'Statesman',
  ),
  QuoteData(
    index: 2,
    quote:
        'Your education is a dress rehearsal for a life that is yours to lead.',
    author: 'Nora Ephron',
    profession: 'Writer',
  ),
  QuoteData(
    index: 3,
    quote: 'The only way to do great work is to love what you do.',
    author: 'Steve Jobs',
    profession: 'Entrepreneur',
  ),
];

// ════════════════════════════════════════════════════════
// QUOTE DATA MODEL
// ════════════════════════════════════════════════════════

class QuoteData {
  final int index;
  final String quote;
  final String author;
  final String profession;

  const QuoteData({
    required this.index,
    required this.quote,
    required this.author,
    required this.profession,
  });

  factory QuoteData.fromJson(Map<String, dynamic> j) => QuoteData(
        index: j['index'] as int? ?? 0,
        quote: j['quote'] as String? ?? '',
        author: j['author'] as String? ?? 'Anonymous',
        profession: j['profession'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'index': index,
        'quote': quote,
        'author': author,
        'profession': profession,
      };

  @override
  bool operator ==(Object other) =>
      other is QuoteData && other.index == index && other.quote == quote;

  @override
  int get hashCode => Object.hash(index, quote);

  @override
  String toString() => '$quote — $author ($profession)';
}

// ════════════════════════════════════════════════════════
// QUOTES SERVICE - SINGLETON WITH DISK CACHING
// ════════════════════════════════════════════════════════

class QuotesService {
  QuotesService._();
  static final QuotesService instance = QuotesService._();

  List<QuoteData> _quotes = const [];
  bool _initialized = false;
  Future<void>? _initFuture;
  final _random = Random();

  /// Initialize quotes service (safe for multiple calls)
  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    try {
      // 1. Try disk cache first (fastest)
      final cached = await _loadFromDiskCache();
      if (cached != null && cached.isNotEmpty) {
        _quotes = cached;
        _initialized = true;
        return;
      }

      // 2. Parse from bundled JSON asset
      final jsonStr = await rootBundle.loadString(_kAssetPath);
      final list = jsonDecode(jsonStr) as List<dynamic>;

      final parsed = list
          .map((e) => QuoteData.fromJson(e as Map<String, dynamic>))
          .where((q) => q.quote.isNotEmpty)
          .toList(growable: false);

      _quotes = parsed.isEmpty ? _kFallbackQuotes : List.unmodifiable(parsed);

      // 3. Persist to disk for next launch
      await _saveToDiskCache(_quotes);
    } catch (e, st) {
      _quotes = _kFallbackQuotes;
      assert(() {
        // ignore: avoid_print
        print('QuotesService init failed: $e\n$st');
        return true;
      }());
    } finally {
      _initialized = true;
    }
  }

  // ── Disk Cache ────────────────────────────────────────

  Future<File> get _cacheFile async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/quotes_cache.json');
  }

  Future<List<QuoteData>?> _loadFromDiskCache() async {
    try {
      final file = await _cacheFile;
      if (!await file.exists()) return null;
      final list = jsonDecode(await file.readAsString()) as List<dynamic>;
      return list
          .map((e) => QuoteData.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToDiskCache(List<QuoteData> quotes) async {
    try {
      final file = await _cacheFile;
      await file.writeAsString(
        jsonEncode(quotes.map((q) => q.toJson()).toList()),
      );
    } catch (_) {
      /* best-effort */
    }
  }

  // ── Public API ────────────────────────────────────────

  /// Get quote of the day (rotates daily, cycles through all 1314)
  QuoteData getQuoteOfDay() {
    if (_quotes.isEmpty) return _kFallbackQuotes.first;
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return _quotes[dayOfYear % _quotes.length];
  }

  /// Get quote by index
  QuoteData getQuoteByIndex(int index) =>
      _quotes.isEmpty ? getQuoteOfDay() : _quotes[index % _quotes.length];

  /// Get random quote
  QuoteData getRandomQuote() => _quotes.isEmpty
      ? getQuoteOfDay()
      : _quotes[_random.nextInt(_quotes.length)];

  /// All quotes (immutable)
  List<QuoteData> get allQuotes => List.unmodifiable(_quotes);

  /// Total quote count
  int get quoteCount => _quotes.length;

  /// Is service ready
  bool get isInitialized => _initialized;

  /// Search by keyword
  List<QuoteData> searchQuotes(String keyword) {
    final q = keyword.toLowerCase();
    return _quotes
        .where((x) =>
            x.quote.toLowerCase().contains(q) ||
            x.author.toLowerCase().contains(q))
        .toList(growable: false);
  }

  /// Force re-parse from asset, ignoring disk cache
  Future<void> reload() async {
    _initialized = false;
    _initFuture = null;
    await init();
  }

  /// For unit tests only
  @visibleForTesting
  void clearForTest() {
    _quotes = const [];
    _initialized = false;
    _initFuture = null;
  }
}
