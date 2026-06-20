import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

/// Result of probing the current device for telemetry purposes.
class DeviceProbeResult {
  final String? deviceModel;
  final String? osVersion;
  final bool? isArCapable;

  const DeviceProbeResult({this.deviceModel, this.osVersion, this.isArCapable});

  static const unknown = DeviceProbeResult();
}

/// Isolates platform/device probing from TelemetryService so the service
/// itself doesn't need direct dart:io / device_info_plus dependencies and
/// can be unit tested with a fake probe.
///
/// Also fixes a correctness bug from the original: `isArCapable` was
/// previously set from `supportedAbis.isNotEmpty` on Android, which is
/// true for virtually every Android device regardless of whether it can
/// actually run ARCore. AR capability needs an actual ARCore availability
/// check (via an ARCore plugin, e.g. `arcore_flutter_plugin`'s
/// `ArCoreController.checkArCoreAvailability()`), not an ABI list.
/// We surface that here as a placeholder hook rather than guessing — silently
/// reporting wrong capability data is worse than admitting we don't know.
class DeviceProbe {
  final DeviceInfoPlugin _deviceInfo;

  DeviceProbe({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  Future<DeviceProbeResult> probe() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return DeviceProbeResult(
          deviceModel: info.model,
          osVersion: 'Android ${info.version.release}',
          // NOTE: replace with a real ARCore availability check, e.g.
          //   final availability = await ArCoreController.checkArCoreAvailability();
          //   isArCapable: availability == ArCoreAvailability.SupportedInstalled;
          // Left null (unknown) rather than the old always-true heuristic.
          isArCapable: null,
        );
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return DeviceProbeResult(
          deviceModel: info.utsname.machine,
          osVersion: 'iOS ${info.systemVersion}',
          // ARKit requires A9 chip or later (iPhone 6s+). A real check
          // should inspect device identifier against a support list, e.g.
          // via `ARConfiguration.isSupported` through an ARKit plugin.
          isArCapable: null,
        );
      }
    } catch (_) {
      // Device info genuinely unavailable (e.g. emulator quirks, plugin
      // not registered). Caller decides whether this blocks init.
    }
    return DeviceProbeResult.unknown;
  }
}
