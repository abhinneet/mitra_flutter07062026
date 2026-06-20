import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/telemetry_service.dart';

/// Provider for TelemetryService instance. Initialized after auth succeeds.
///
/// Usage in widgets:
///   final telemetry = ref.watch(telemetryServiceProvider);
///   await telemetry?.logQuizSubmit(...);
final telemetryServiceProvider = StateProvider<TelemetryService?>((ref) {
  return null; // starts null, set by auth flow
});
