import 'package:flutter/foundation.dart';

/// Application environment configuration.
///
/// Debug builds (flutter run)        -> DEV  (local XAMPP network IP)
/// Release builds (flutter build)   -> PROD (HTTPS production server)
///
/// To change the DEV IP: edit [devApiUrl] below.
/// To set the PROD URL: replace [prodApiUrl] with your real HTTPS API URL before release.
/// Until a production domain is configured, release builds fall back to [devApiUrl].
class AppEnv {
  AppEnv._();

  /// DEV — local XAMPP accessed via your PC's LAN IP.
  /// Update this when your network IP changes.
  static const String devApiUrl = 'http://192.168.100.108/SehatAI%20Pakistan/api';

  /// PROD — set this to your real production HTTPS API URL before release.
  /// Leave empty ('') to fall back to [devApiUrl] (useful during development).
  static const String prodApiUrl = '';

  /// Active base URL resolved at runtime.
  /// [kReleaseMode] is a compile-time constant:
  ///   - false in debug & profile builds  -> DEV
  ///   - true  in release builds          -> PROD (or DEV if PROD not configured)
  static String get apiUrl {
    if (kReleaseMode && prodApiUrl.isNotEmpty) {
      return prodApiUrl;
    }
    return devApiUrl;
  }

  /// `true` when running a release build with a production URL configured.
  static bool get isProduction => kReleaseMode && prodApiUrl.isNotEmpty;
}
