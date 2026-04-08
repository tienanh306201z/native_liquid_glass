import 'package:flutter/foundation.dart';

import '../platform/platform_info_stub.dart' if (dart.library.io) '../platform/platform_info_io.dart' as platform_info;

/// Utility helpers for checking native Liquid Glass availability.
final class NativeLiquidGlassUtils {
  NativeLiquidGlassUtils._();

  static int? _cachedIOSVersion;
  static bool _isInitialized = false;

  static void _ensureInitialized() {
    if (_isInitialized) return;
    if (!kIsWeb && platform_info.isIOS) {
      _cachedIOSVersion = _parseMajorVersion(platform_info.operatingSystemVersion);
    }
    _isInitialized = true;
  }

  static int? _parseMajorVersion(String osVersion) {
    final match = RegExp(r'(\d+)').firstMatch(osVersion);
    return match != null ? int.tryParse(match.group(1)!) : null;
  }

  /// The cached iOS major version. `null` on non-iOS or web.
  static int? get iosVersion {
    _ensureInitialized();
    return _cachedIOSVersion;
  }

  /// Returns `true` on iOS 26+. The only platform where Liquid Glass is
  /// currently supported.
  static bool get supportsLiquidGlass {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return false;
    _ensureInitialized();
    return (_cachedIOSVersion ?? 0) >= 26;
  }

  /// Forces a reset of the cached version. Only needed for testing.
  @visibleForTesting
  static void reset() {
    _cachedIOSVersion = null;
    _isInitialized = false;
  }
}
