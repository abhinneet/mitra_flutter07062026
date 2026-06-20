import 'dart:convert';
import 'package:hive/hive.dart';

/// Persistent local store for telemetry events that failed to write even
/// after Firestore's own offline queue / retry logic gave up (e.g.
/// permission-denied, malformed payload, quota errors — not just
/// "device is offline", which Firestore already handles for us).
///
/// The original implementation caught write failures and only `print()`'d
/// them, which means failed events for a government analytics pipeline
/// were silently and permanently lost. This gives them a second life: a
/// background sweep (e.g. on app foreground, or periodic timer) can call
/// [pending] and attempt to resend, calling [remove] on success.
///
/// Uses Hive because it's lightweight, works offline, and doesn't require
/// a schema migration story the way sqlite would for a single queue table.
/// Swap for any other local KV/db without changing the public API.
class TelemetryDeadLetterQueue {
  static const _boxName = 'telemetry_dead_letter';
  static const _maxEntries = 5000; // bound local storage growth

  Box<String>? _box;

  Future<void> _ensureOpen() async {
    _box ??= await Hive.openBox<String>(_boxName);
  }

  /// Persist a failed write so it can be retried later. [collection] and
  /// [data] mirror the arguments that were passed to the Firestore write
  /// that failed.
  Future<void> enqueue({
    required String collection,
    required Map<String, dynamic> data,
    required String errorMessage,
  }) async {
    await _ensureOpen();
    final box = _box!;

    if (box.length >= _maxEntries) {
      // Drop oldest entry rather than growing unboundedly. We'd rather
      // lose the oldest low-priority screen_view than crash on disk
      // pressure on a budget rural-deployment device.
      final oldestKey = box.keys.first;
      await box.delete(oldestKey);
    }

    final entry = {
      'collection': collection,
      'data': data,
      'error': errorMessage,
      'enqueued_at': DateTime.now().toIso8601String(),
      'attempts': 0,
    };
    final key = '${DateTime.now().microsecondsSinceEpoch}';
    await box.put(key, jsonEncode(entry));
  }

  /// All entries currently queued, keyed by their internal storage key
  /// (needed for [remove] / [recordAttempt]).
  Future<Map<String, DeadLetterEntry>> pending() async {
    await _ensureOpen();
    final box = _box!;
    return {
      for (final key in box.keys.cast<String>())
        key: DeadLetterEntry.fromJson(jsonDecode(box.get(key)!) as Map<String, dynamic>),
    };
  }

  Future<void> remove(String key) async {
    await _ensureOpen();
    await _box!.delete(key);
  }

  /// Bump the attempt counter without removing — call this on a retry
  /// failure so entries that fail repeatedly (e.g. permanently malformed
  /// payload) can eventually be given up on by the caller's own policy
  /// (e.g. drop after 10 attempts).
  Future<void> recordAttempt(String key, DeadLetterEntry entry) async {
    await _ensureOpen();
    final updated = {
      'collection': entry.collection,
      'data': entry.data,
      'error': entry.errorMessage,
      'enqueued_at': entry.enqueuedAt.toIso8601String(),
      'attempts': entry.attempts + 1,
    };
    await _box!.put(key, jsonEncode(updated));
  }

  Future<int> length() async {
    await _ensureOpen();
    return _box!.length;
  }
}

class DeadLetterEntry {
  final String collection;
  final Map<String, dynamic> data;
  final String errorMessage;
  final DateTime enqueuedAt;
  final int attempts;

  const DeadLetterEntry({
    required this.collection,
    required this.data,
    required this.errorMessage,
    required this.enqueuedAt,
    required this.attempts,
  });

  factory DeadLetterEntry.fromJson(Map<String, dynamic> json) => DeadLetterEntry(
        collection: json['collection'] as String,
        data: Map<String, dynamic>.from(json['data'] as Map),
        errorMessage: json['error'] as String,
        enqueuedAt: DateTime.parse(json['enqueued_at'] as String),
        attempts: json['attempts'] as int,
      );
}
