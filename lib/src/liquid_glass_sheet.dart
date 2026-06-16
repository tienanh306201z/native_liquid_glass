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

  /// Live sheet handles keyed by request id. The shared presenter channel is
  /// used by alert/sheet/popover at once, so a single persistent handler
  /// routes dismiss events by id instead of clobbering the handler per-show.
  static final Map<int, LiquidGlassSheetHandle> _live = <int, LiquidGlassSheetHandle>{};
  static bool _handlerInstalled = false;

  LiquidGlassSheet._();

  /// Install the shared method-call handler exactly once.
  static void _ensureHandlerInstalled() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _presenterChannel.setMethodCallHandler((call) async {
      if (call.method == 'sheetDismissed') {
        final args = call.arguments as Map?;
        final id = args?['id'] as int?;
        if (id == null) return;
        final handle = _live.remove(id);
        handle?._sheetId = null;
      }
    });
  }

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
      _ensureHandlerInstalled();

      final id = _nextId++;
      handle._sheetId = id;
      _live[id] = handle;

      _presenterChannel.invokeMethod<void>('showSheet', {
        'id': id,
        'title': title,
        'message': message,
        'detents': detents.map((d) => d.name).toList(),
        'prefersGrabberVisible': prefersGrabberVisible,
        'isModal': isModal,
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
    final id = _sheetId;
    if (id != null) {
      LiquidGlassSheet._live.remove(id);
      _sheetId = null;
      await _presenterChannel.invokeMethod<void>('dismissSheet', {'id': id});
    }
  }
}
