// ═══════════════════════════════════════════════════════
// MITRA Offline Queue — Riverpod + Hive (HARDENED)
// ═══════════════════════════════════════════════════════
//
// New fixes in this pass (on top of the previous version):
//
//  BUGS FIXED
//  1. Startup race: enqueue() could write to `_box` before Hive finished
//     opening (LateInitializationError). Now gated by a readiness Completer.
//  2. False "online" at launch: isOnline defaulted to `true` until the first
//     connectivity *change* event fired. Now checked explicitly on init.
//  3. Corrupted Hive box could crash app startup forever. Now caught once,
//     box is reset, app continues (losing only the unsynced queue, not
//     crash-looping the whole app).
//  4. enqueue() updated in-memory state even if the Hive write failed or the
//     payload wasn't JSON-encodable, leaving memory and disk out of sync.
//     Now validated/persisted *before* the in-memory state changes.
//
//  IMPROVEMENTS
//  5. Exponential backoff per item (nextRetryAt) instead of retrying
//     instantly in a tight loop — kinder to battery and flaky networks.
//  6. Non-retryable HTTP errors (4xx, except 408/429) drop immediately
//     instead of burning 3 retries on a request that will never succeed.
//  7. Periodic flush timer catches items whose backoff has expired even if
//     no new connectivity event fires.
//  8. Optional dispatcher injection for unit tests, without forcing a
//     refactor of your existing ApiService/Dio singleton.
// ═══════════════════════════════════════════════════════

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart'; // only used for DioException status-code check below
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../services/api_service.dart'; // Dio singleton: api

// ── Constants ──────────────────────────────────────────
const _kBoxName = 'offline_queue';
const _kMaxRetries = 3;
const _kMaxQueue = 100;
const _kTtlDays = 7;
const _kBaseBackoffSeconds = 2;
const _kMaxBackoffSeconds = 60;
const _kPeriodicFlushInterval = Duration(seconds: 30);

// ── Queue Item ─────────────────────────────────────────
class QueuedRequest {
  final String id;
  final String endpoint;
  final String method;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retries;
  final DateTime? nextRetryAt; // ✅ Add: backoff gate

  const QueuedRequest({
    required this.id,
    required this.endpoint,
    required this.method,
    required this.payload,
    required this.createdAt,
    this.retries = 0,
    this.nextRetryAt,
  });

  bool get isExpired =>
      DateTime.now().difference(createdAt).inDays >= _kTtlDays;
  bool get hasMaxedOutRetries => retries >= _kMaxRetries;

  // ✅ Add: true once the backoff window has passed (or there isn't one yet)
  bool get isDueForRetry =>
      nextRetryAt == null || !DateTime.now().isBefore(nextRetryAt!);

  Map<String, dynamic> toJson() => {
        'id': id,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retries': retries,
        'nextRetryAt': nextRetryAt?.toIso8601String(),
      };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
        id: json['id'] as String,
        endpoint: json['endpoint'] as String,
        method: json['method'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        createdAt: DateTime.parse(json['createdAt'] as String),
        retries: (json['retries'] as int?) ?? 0,
        nextRetryAt: json['nextRetryAt'] != null
            ? DateTime.parse(json['nextRetryAt'] as String)
            : null,
      );

  QueuedRequest copyWith({
    int? retries,
    DateTime? nextRetryAt,
  }) =>
      QueuedRequest(
        id: id,
        endpoint: endpoint,
        method: method,
        payload: payload,
        createdAt: createdAt,
        retries: retries ?? this.retries,
        nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      );
}

// ── Sync Status ────────────────────────────────────────
enum SyncStatus { idle, syncing, error }

// ── Offline State ──────────────────────────────────────
class OfflineState {
  final bool isOnline;
  final List<QueuedRequest> queue;
  final bool isLoaded;
  final SyncStatus syncStatus;
  final String? lastError;

  const OfflineState({
    this.isOnline = true,
    this.queue = const [],
    this.isLoaded = false,
    this.syncStatus = SyncStatus.idle,
    this.lastError,
  });

  OfflineState copyWith({
    bool? isOnline,
    List<QueuedRequest>? queue,
    bool? isLoaded,
    SyncStatus? syncStatus,
    String? lastError,
  }) =>
      OfflineState(
        isOnline: isOnline ?? this.isOnline,
        queue: queue ?? this.queue,
        isLoaded: isLoaded ?? this.isLoaded,
        syncStatus: syncStatus ?? this.syncStatus,
        lastError: lastError ?? this.lastError,
      );

  String get statusLabel {
    if (!isLoaded) return 'Loading…';
    if (syncStatus == SyncStatus.syncing) return 'Syncing…';
    if (queue.isEmpty) return 'All synced ✓';
    return '${queue.length} pending';
  }
}

// ✅ Add: dispatcher is a plain function type so tests can inject a fake
//    without touching your ApiService class at all. Production code never
//    has to pass this — it defaults to the real Dio `api` singleton.
typedef RequestDispatcher = Future<void> Function(
  String endpoint,
  String method,
  Map<String, dynamic> payload,
);

Future<void> _defaultDispatcher(
  String endpoint,
  String method,
  Map<String, dynamic> payload,
) async {
  switch (method) {
    case 'POST':
      await api.post(endpoint, data: payload);
      break;
    case 'PUT':
      await api.put(endpoint, data: payload);
      break;
    default:
      throw UnsupportedError('Unknown method: $method');
  }
}

// ── Offline Notifier ───────────────────────────────────
class OfflineNotifier extends StateNotifier<OfflineState> {
  late Box<String> _box;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicFlushTimer;
  bool _isFlushing = false;

  // ✅ Add: readiness gate. enqueue() awaits this before touching `_box`,
  //    which removes the startup race where a request could be enqueued
  //    before Hive.openBox() finished.
  final Completer<void> _ready = Completer<void>();

  final RequestDispatcher _dispatch;

  static const _uuid = Uuid();

  OfflineNotifier({RequestDispatcher? dispatcher})
      : _dispatch = dispatcher ?? _defaultDispatcher,
        super(const OfflineState()) {
    _initialize();
  }

  // ── Initialization ─────────────────────────────────

  Future<void> _initialize() async {
    try {
      // ✅ FIX: check real connectivity at launch instead of assuming
      //    `isOnline: true` until the first change event fires. On a phone
      //    that opens the app in airplane mode, the old code would attempt
      //    (and fail) a flush before ever learning it was offline.
      final initial = await Connectivity().checkConnectivity();
      final initiallyOnline = !initial.contains(ConnectivityResult.none);

      _box = await _openBoxSafely();
      await _loadFromHive();

      state = state.copyWith(isOnline: initiallyOnline);
      _listenConnectivity();
      _startPeriodicFlush();

      if (initiallyOnline && state.queue.isNotEmpty) {
        await _flushQueue();
      }
    } catch (e, st) {
      dev.log('Init failed', error: e, stackTrace: st, name: 'OfflineQueue');
      state = state.copyWith(isLoaded: true, lastError: e.toString());
    } finally {
      if (!_ready.isCompleted) _ready.complete();
    }
  }

  // ✅ FIX: a corrupted Hive box (e.g. app killed mid-write, OS-level
  //    storage corruption) used to throw inside _initialize and leave the
  //    queue permanently stuck in "Loading…". Now it's caught once, the box
  //    is wiped, and the app continues with an empty queue. Losing a few
  //    unsynced offline writes is an acceptable trade-off against bricking
  //    the feature for that user forever.
  Future<Box<String>> _openBoxSafely() async {
    try {
      return await Hive.openBox<String>(_kBoxName);
    } catch (e, st) {
      dev.log(
        'Hive box corrupted, resetting',
        error: e,
        stackTrace: st,
        name: 'OfflineQueue',
      );
      await Hive.deleteBoxFromDisk(_kBoxName);
      return Hive.openBox<String>(_kBoxName);
    }
  }

  Future<void> _loadFromHive() async {
    final loaded = <QueuedRequest>[];
    final staleKeys = <String>[];

    for (final key in _box.keys) {
      final raw = _box.get(key as String);
      if (raw == null) continue;

      try {
        final item = QueuedRequest.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
        );

        if (item.isExpired || item.hasMaxedOutRetries) {
          staleKeys.add(key);
          dev.log('Pruning stale item ${item.id}', name: 'OfflineQueue');
        } else {
          loaded.add(item);
        }
      } catch (e) {
        staleKeys.add(key);
        dev.log('Removing corrupted entry at key $key', name: 'OfflineQueue');
      }
    }

    if (staleKeys.isNotEmpty) await _box.deleteAll(staleKeys);

    state = state.copyWith(queue: loaded, isLoaded: true);
    dev.log('Loaded ${loaded.length} items', name: 'OfflineQueue');
  }

  // ── Connectivity ────────────────────────────────────

  void _listenConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (results) async {
        final online = !results.contains(ConnectivityResult.none);

        if (online != state.isOnline) {
          state = state.copyWith(isOnline: online);
          dev.log(online ? '🌐 Online' : '📡 Offline', name: 'OfflineQueue');
        }

        if (online && state.queue.isNotEmpty) {
          await _flushQueue();
        }
      },
      onError: (Object e) =>
          dev.log('Connectivity error: $e', name: 'OfflineQueue'),
    );
  }

  // ✅ Add: catches two cases connectivity events alone miss —
  //    (a) an item whose exponential backoff has just expired, and
  //    (b) a connectivity-change event that the OS silently dropped.
  void _startPeriodicFlush() {
    _periodicFlushTimer = Timer.periodic(_kPeriodicFlushInterval, (_) {
      if (state.isOnline && state.queue.isNotEmpty && !_isFlushing) {
        unawaited(_flushQueue());
      }
    });
  }

  // ── Flush ───────────────────────────────────────────

  Future<void> _flushQueue() async {
    if (_isFlushing || !state.isOnline || state.queue.isEmpty) return;

    _isFlushing = true;
    state = state.copyWith(syncStatus: SyncStatus.syncing);

    try {
      for (final item in List<QueuedRequest>.from(state.queue)) {
        if (!state.isOnline) break;

        if (item.isExpired || item.hasMaxedOutRetries) {
          dev.log('Dropping ${item.id} (expired/maxed)', name: 'OfflineQueue');
          await _dequeue(item.id);
          continue;
        }

        // ✅ Add: skip items still inside their backoff window instead of
        //    hammering a server that just rejected them seconds ago.
        if (!item.isDueForRetry) continue;

        try {
          await _dispatch(item.endpoint, item.method, item.payload);
          await _dequeue(item.id);
          dev.log('✅ Synced ${item.endpoint}', name: 'OfflineQueue');
        } catch (e) {
          if (_isNonRetryable(e)) {
            // ✅ Add: a 4xx validation/auth error will fail identically on
            //    every retry — burning 3 attempts just delays the user
            //    finding out their request was rejected.
            dev.log(
              'Non-retryable error for ${item.endpoint}, dropping: $e',
              name: 'OfflineQueue',
            );
            state = state.copyWith(lastError: e.toString());
            await _dequeue(item.id);
          } else {
            await _incrementRetry(item.id);
            dev.log(
              '⚠️ Retry ${item.retries + 1}/$_kMaxRetries scheduled for ${item.endpoint}',
              name: 'OfflineQueue',
            );
          }
        }
      }
    } finally {
      _isFlushing = false;
      state = state.copyWith(syncStatus: SyncStatus.idle);
    }
  }

  // ✅ Add: distinguishes "will never succeed" from "try again later".
  //    Assumes Dio (matches your `api` singleton). If you're not on Dio,
  //    replace this with your HTTP client's equivalent status-code check —
  //    worst case without it, every failure just retries up to 3 times,
  //    which is still correct, just less efficient.
  bool _isNonRetryable(Object e) {
    if (e is DioException) {
      final status = e.response?.statusCode;
      if (status == null) return false; // timeout/no connection — retryable
      if (status == 408 || status == 429) return false; // transient — retry
      return status >= 400 && status < 500; // bad request/auth/validation
    }
    return false;
  }

  Duration _backoffFor(int retryCount) {
    final seconds = _kBaseBackoffSeconds * (1 << retryCount); // 2s, 4s, 8s...
    return Duration(
      seconds: seconds > _kMaxBackoffSeconds ? _kMaxBackoffSeconds : seconds,
    );
  }

  // ── Public API ──────────────────────────────────────

  Future<bool> enqueue({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
  }) async {
    final normalised = method.toUpperCase();
    if (!{'POST', 'PUT'}.contains(normalised)) {
      throw ArgumentError('Unsupported HTTP method: $method');
    }

    if (state.queue.length >= _kMaxQueue) {
      dev.log('⚠️ Queue full, dropping request', name: 'OfflineQueue');
      return false;
    }

    final item = QueuedRequest(
      id: _uuid.v4(),
      endpoint: endpoint,
      method: normalised,
      payload: payload,
      createdAt: DateTime.now(),
    );

    // ✅ FIX: validate the payload is actually JSON-encodable *before*
    // touching in-memory state. Previously, a non-serialisable payload
    // (e.g. containing a DateTime or custom object) would update `state`
    // successfully, then throw on the Hive write — leaving the item visible
    // in the UI as "pending" forever while silently absent from disk.
    final String encoded;
    try {
      encoded = jsonEncode(item.toJson());
    } catch (e, st) {
      dev.log(
        'Payload not JSON-encodable, refusing to queue',
        error: e,
        stackTrace: st,
        name: 'OfflineQueue',
      );
      rethrow;
    }

    // ✅ FIX: wait for Hive to finish opening before writing. Without this,
    // calling enqueue() in the first few milliseconds of app launch (e.g.
    // from a widget's initState) could throw LateInitializationError on
    // `_box`.
    await _ready.future;

    try {
      await _box.put(item.id, encoded);
    } catch (e, st) {
      dev.log(
        'Failed to persist queued item, dropping',
        error: e,
        stackTrace: st,
        name: 'OfflineQueue',
      );
      return false;
    }

    // Only update in-memory state once the write to disk has succeeded —
    // keeps "what the UI shows" and "what's actually durable" in sync.
    state = state.copyWith(queue: [...state.queue, item]);

    dev.log(
      '📥 Queued $endpoint (total: ${state.queue.length})',
      name: 'OfflineQueue',
    );

    if (state.isOnline && !_isFlushing) {
      unawaited(_flushQueue());
    }

    return true;
  }

  Future<void> retryNow() async {
    if (state.isOnline && !_isFlushing) await _flushQueue();
  }

  Future<void> clearQueue() async {
    state = state.copyWith(queue: []);
    await _box.clear();
  }

  // ── Private Hive helpers ────────────────────────────

  Future<void> _dequeue(String id) async {
    state = state.copyWith(
      queue: state.queue.where((r) => r.id != id).toList(),
    );
    try {
      await _box.delete(id);
    } catch (e, st) {
      dev.log('Failed to delete $id from box',
          error: e, stackTrace: st, name: 'OfflineQueue');
    }
  }

  Future<void> _incrementRetry(String id) async {
    QueuedRequest? changed;

    final updated = state.queue.map((r) {
      if (r.id != id) return r;
      final newRetries = r.retries + 1;
      changed = r.copyWith(
        retries: newRetries,
        nextRetryAt: DateTime.now().add(_backoffFor(newRetries)),
      );
      return changed!;
    }).toList();

    state = state.copyWith(queue: updated);

    if (changed == null)
      return; // item was removed concurrently; nothing to persist

    try {
      await _box.put(id, jsonEncode(changed!.toJson()));
    } catch (e, st) {
      dev.log('Failed to persist retry count for $id',
          error: e, stackTrace: st, name: 'OfflineQueue');
    }
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _periodicFlushTimer?.cancel();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────
final offlineProvider = StateNotifierProvider<OfflineNotifier, OfflineState>(
  (ref) => OfflineNotifier(),
);
