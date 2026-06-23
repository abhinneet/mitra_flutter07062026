// ═══════════════════════════════════════════════════════
// BrainSparkService
// Loads facts from assets/data/brain_spark_facts.json
// Serves 2 unique facts per day, rotating daily
// No internet required — fully offline
// ═══════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';

// ── Model ────────────────────────────────────────────────

class BrainSparkFact {
  final int id;
  final String fact;
  final String category;
  final String emoji;

  const BrainSparkFact({
    required this.id,
    required this.fact,
    required this.category,
    required this.emoji,
  });

  factory BrainSparkFact.fromJson(Map<String, dynamic> json) {
    return BrainSparkFact(
      id: json['id'] as int,
      fact: json['fact'] as String,
      category: json['category'] as String,
      emoji: json['emoji'] as String,
    );
  }
}

// ── Slot enum ────────────────────────────────────────────
// Explicit enum beats magic ints (0/1) scattered in logic.

enum BrainSparkSlot {
  morning(label: 'Morning Spark', startHour: 0),
  afternoon(label: 'Afternoon Spark', startHour: 12);

  const BrainSparkSlot({required this.label, required this.startHour});

  final String label;
  final int startHour;

  static BrainSparkSlot forTime(DateTime t) =>
      t.hour < 12 ? BrainSparkSlot.morning : BrainSparkSlot.afternoon;
}

// ── Service ──────────────────────────────────────────────

class BrainSparkService {
  // Singleton
  static final BrainSparkService instance = BrainSparkService._();
  BrainSparkService._();

  List<BrainSparkFact> _facts = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  // ── Init ──────────────────────────────────────────────

  Future<void> init() async {
    if (_loaded) return;

    final raw =
        await rootBundle.loadString('assets/data/brain_spark_facts.json');
    final list = json.decode(raw) as List<dynamic>;

    _facts = list
        .map((e) => BrainSparkFact.fromJson(e as Map<String, dynamic>))
        .toList();

    _loaded = true;
  }

  // ── Fact access ───────────────────────────────────────

  /// Returns the fact for the current time slot (morning or afternoon).
  BrainSparkFact get currentFact => factFor(DateTime.now());

  /// Current slot label ("Morning Spark" / "Afternoon Spark").
  String get currentSlotLabel => BrainSparkSlot.forTime(DateTime.now()).label;

  /// Fact for an arbitrary [DateTime] — useful for testing or previews.
  BrainSparkFact factFor(DateTime time) {
    _requireLoaded();
    final slot = BrainSparkSlot.forTime(time);
    return _factAt(dayOfYear: _dayOfYear(time), slot: slot);
  }

  // ── Next fact time ────────────────────────────────────

  /// When the next slot begins (noon today, or midnight tonight).
  DateTime get nextFactTime {
    final now = DateTime.now();
    return BrainSparkSlot.forTime(now) == BrainSparkSlot.morning
        ? DateTime(now.year, now.month, now.day, 12)
        : DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  // ── Internal helpers ──────────────────────────────────

  BrainSparkFact _factAt(
      {required int dayOfYear, required BrainSparkSlot slot}) {
    // Each calendar day consumes 2 consecutive indices; wraps over total count.
    final index = (dayOfYear * 2 + slot.index) % _facts.length;
    return _facts[index];
  }

  int _dayOfYear(DateTime date) => date.difference(DateTime(date.year)).inDays;

  void _requireLoaded() {
    if (!_loaded) {
      throw StateError(
        'BrainSparkService not initialised. '
        'Call `await BrainSparkService.instance.init()` before use.',
      );
    }
  }

  // ── Test helpers ──────────────────────────────────────

  @visibleForTesting
  void resetForTest() {
    _loaded = false;
    _facts = [];
  }

  @visibleForTesting
  void loadFacts(List<BrainSparkFact> facts) {
    _facts = facts;
    _loaded = true;
  }
}
