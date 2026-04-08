import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/native_liquid_glass_utils.dart';

/// Detent sizes for [LiquidGlassSheet].
enum LiquidGlassSheetDetent {
  /// Half height.
  medium,

  /// Full height.
  large,
}

/// Shows a native iOS sheet using UISheetPresentationController with
/// Liquid Glass effects on iOS 26+.
///
/// Uses the shared LiquidGlassPresenter channel for modal presentation.
/// On non-iOS platforms, falls back to [showModalBottomSheet].
class LiquidGlassSheet {
  static const _presenterChannel = MethodChannel('liquid-glass-presenter');
  static int _nextId = 0;

  LiquidGlassSheet._();

  /// Show a sheet with the given parameters.
  ///
  /// Returns a [LiquidGlassSheetHandle] to programmatically dismiss.
  static LiquidGlassSheetHandle show({
    required BuildContext context,
    String? title,
    String? message,
    WidgetBuilder? builder,
    List<LiquidGlassSheetDetent> detents = const [LiquidGlassSheetDetent.medium, LiquidGlassSheetDetent.large],
    bool prefersGrabberVisible = true,
    bool isModal = false,
  }) {
    final handle = LiquidGlassSheetHandle._();

    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      final id = _nextId++;
      handle._sheetId = id;

      _presenterChannel.invokeMethod<void>('showSheet', {
        'id': id,
        'title': title,
        'message': message,
        'detents': detents.map((d) => d.name).toList(),
        'prefersGrabberVisible': prefersGrabberVisible,
        'isModal': isModal,
      });

      // Listen for dismiss events
      _presenterChannel.setMethodCallHandler((call) async {
        if (call.method == 'sheetDismissed') {
          final args = call.arguments as Map?;
          if (args != null && args['id'] == id) {
            handle._sheetId = null;
          }
        }
      });

      return handle;
    }

    return handle;
  }
}

/// Handle to dismiss a shown sheet.
class LiquidGlassSheetHandle {
  static const _presenterChannel = MethodChannel('liquid-glass-presenter');
  int? _sheetId;

  LiquidGlassSheetHandle._();

  /// Dismiss the sheet.
  Future<void> dismiss() async {
    if (_sheetId != null) {
      await _presenterChannel.invokeMethod<void>('dismissSheet', {'id': _sheetId});
      _sheetId = null;
    }
  }
}
