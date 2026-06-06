// ═══════════════════════════════════════════════════════
// MITRA Offline Queue — Riverpod + connectivity_plus
// Mirrors store/useOfflineStore.ts + hooks/useOfflineQueue.ts
// ═══════════════════════════════════════════════════════

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// ── Queue Item ─────────────────────────────────────────
class QueuedRequest {
  final String id;
  final String endpoint;
  final String method; // 'POST' | 'PUT'
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retries;

  QueuedRequest({
    required this.id,
    required this.endpoint,
    required this.method,
    required this.payload,
    required this.createdAt,
    this.retries = 0,
  });

  QueuedRequest copyWith({int? retries}) => QueuedRequest(
        id:        id,
        endpoint:  endpoint,
        method:    method,
        payload:   payload,
        createdAt: createdAt,
        retries:   retries ?? this.retries,
      );
}

// ── Offline State ──────────────────────────────────────
class OfflineState {
  final bool isOnline;
  final List<QueuedRequest> queue;

  const OfflineState({this.isOnline = true, this.queue = const []});

  OfflineState copyWith({bool? isOnline, List<QueuedRequest>? queue}) =>
      OfflineState(isOnline: isOnline ?? this.isOnline, queue: queue ?? this.queue);
}

// ── Offline Notifier ───────────────────────────────────
class OfflineNotifier extends StateNotifier<OfflineState> {
  OfflineNotifier() : super(const OfflineState()) {
    _listenConnectivity();
  }

  StreamSubscription? _sub;

  void _listenConnectivity() {
    _sub = Connectivity().onConnectivityChanged.listen((result) async {
      final online = result != ConnectivityResult.none;
      state = state.copyWith(isOnline: online);

      if (online && state.queue.isNotEmpty) {
        await _flushQueue();
      }
    });
  }

  Future<void> _flushQueue() async {
    for (final item in List.from(state.queue)) {
      if (item.retries >= 3) {
        _dequeue(item.id);
        continue;
      }
      try {
        if (item.method == 'POST') {
          await api.post(item.endpoint, data: item.payload);
        } else {
          await api.put(item.endpoint, data: item.payload);
        }
        _dequeue(item.id);
      } catch (_) {
        _incrementRetry(item.id);
      }
    }
  }

  void enqueue({
    required String endpoint,
    required String method,
    required Map<String, dynamic> payload,
  }) {
    final item = QueuedRequest(
      id:        '${DateTime.now().millisecondsSinceEpoch}-${payload.hashCode}',
      endpoint:  endpoint,
      method:    method,
      payload:   payload,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(queue: [...state.queue, item]);
  }

  void _dequeue(String id) {
    state = state.copyWith(queue: state.queue.where((r) => r.id != id).toList());
  }

  void _incrementRetry(String id) {
    state = state.copyWith(
      queue: state.queue.map((r) => r.id == id ? r.copyWith(retries: r.retries + 1) : r).toList(),
    );
  }

  void clearQueue() => state = state.copyWith(queue: []);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────
final offlineProvider = StateNotifierProvider<OfflineNotifier, OfflineState>(
  (ref) => OfflineNotifier(),
);
