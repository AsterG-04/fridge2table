import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode, debugPrint;
import 'dart:io' show Platform;

/// Single place the backend's base URL is decided, instead of every screen
/// hardcoding an address.
///
/// The root problem this solves: "http://10.0.2.2:8000" is a special NAT
/// alias that only exists inside the Android *emulator* — it means nothing
/// on real hardware, where every request to it just hangs until it times
/// out. A real device reaches the dev machine differently depending on how
/// it's connected:
///
///   - USB + `adb reverse tcp:8000 tcp:8000` (recommended for local dev):
///     forwards the device's own "localhost:8000" to the host's, so the
///     device can use plain "http://localhost:8000".
///   - Same WiFi network, no cable: needs the dev machine's actual LAN IP,
///     which can't be auto-detected reliably, so pass it explicitly:
///       flutter run --dart-define=API_BASE_URL=http://192.168.1.129:8000
///     (find it with `ipconfig` / `ifconfig`; also make sure the backend
///     is started with `--host 0.0.0.0`, not `127.0.0.1`, and that your
///     firewall allows inbound connections on port 8000).
///
/// [initialize] must be awaited once at app startup (before runApp) so it
/// can ask device_info_plus whether this is a real device or an emulator
/// -- that's async, so the result is cached and [baseUrl] stays a plain
/// synchronous getter for every call site that already assumed one.
class ApiConfig {
  static const String _override = String.fromEnvironment("API_BASE_URL");

  /// The deployed backend's public URL -- reachable over the internet, no
  /// USB/adb needed. Used automatically for release builds so the app works
  /// standalone after install (plug in once to install, then unplug).
  /// Update this if the Render service's actual assigned URL differs from
  /// this (e.g. the name "fridge2table-backend" was taken and Render
  /// appended a suffix) -- check the URL shown on the service's Render
  /// dashboard page after deploying.
  static const String _productionUrl = "https://fridge2table-backend.onrender.com";

  static String? _resolved;

  /// True only when [baseUrl] was resolved to the "physical device via
  /// adb reverse" address -- i.e. a request failing to connect at all
  /// almost certainly means `adb reverse tcp:8000 tcp:8000` was never run
  /// (or the backend isn't running), not a generic network problem. Lets
  /// ApiService give a precise, actionable error instead of a vague one.
  static bool _viaAdbReverse = false;
  static bool get usingAdbReverse => _viaAdbReverse;

  static Future<void> initialize() async {
    if (_override.isNotEmpty) {
      _resolved = _override;
      _viaAdbReverse = false;
      debugPrint("[ApiConfig] Using API_BASE_URL override: $_resolved");
      return;
    }

    if (kReleaseMode) {
      // A real installed release build (what "flutter build apk --release"
      // produces, and what a user actually installs) should work standalone
      // without USB -- point at the deployed backend instead of a
      // localhost/emulator address that only ever exists during `flutter
      // run` development. The dart-define override above still wins over
      // this, for testing a release build against a local backend.
      _resolved = _productionUrl;
      _viaAdbReverse = false;
      debugPrint("[ApiConfig] Release build -> baseUrl=$_resolved");
      return;
    }

    if (kIsWeb) {
      _resolved = "http://localhost:8000";
      return;
    }

    if (!Platform.isAndroid) {
      _resolved = "http://localhost:8000"; // iOS simulator / desktop
      return;
    }

    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      // Real devices reach the host via `adb reverse tcp:8000 tcp:8000`,
      // which forwards the device's own localhost:8000 to the host's.
      // Emulators use the special 10.0.2.2 NAT alias instead.
      _viaAdbReverse = androidInfo.isPhysicalDevice;
      _resolved = androidInfo.isPhysicalDevice
          ? "http://localhost:8000"
          : "http://10.0.2.2:8000";
      debugPrint(
        "[ApiConfig] Android isPhysicalDevice=${androidInfo.isPhysicalDevice} -> baseUrl=$_resolved",
      );
    } catch (e) {
      // device_info_plus itself failed for some reason -- fall back to the
      // emulator address rather than leaving baseUrl unset.
      debugPrint("[ApiConfig] Device detection failed ($e), defaulting to emulator address");
      _resolved = "http://10.0.2.2:8000";
    }
  }

  static String get baseUrl {
    final resolved = _resolved;
    if (resolved == null) {
      throw StateError(
        "ApiConfig.initialize() must be awaited before baseUrl is used "
        "(call it in main() before runApp()).",
      );
    }
    return resolved;
  }
}
