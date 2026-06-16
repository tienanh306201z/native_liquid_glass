import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/native_liquid_glass_utils.dart';

/// Shows a native iOS popover using UIPopoverPresentationController with
/// Liquid Glass effects on iOS 26+.
///
/// This uses the shared LiquidGlassPresenter channel for modal presentation.
/// On non-iOS platforms, falls back to [OverlayEntry].
class LiquidGlassPopover {
  static const _presenterChannel = MethodChannel('liquid-glass-presenter');
  static int _nextId = 0;

  /// Live popover handles keyed by request id, so the shared presenter
  /// channel's single persistent handler can null out the right handle when
  /// the user dismisses by tapping outside.
  static final Map<int, LiquidGlassPopoverHandle> _live = <int, LiquidGlassPopoverHandle>{};
  static bool _handlerInstalled = false;

  LiquidGlassPopover._();

  /// Install the shared method-call handler exactly once.
  static void _ensureHandlerInstalled() {
    if (_handlerInstalled) return;
    _handlerInstalled = true;
    _presenterChannel.setMethodCallHandler((call) async {
      if (call.method == 'popoverDismissed') {
        final args = call.arguments as Map?;
        final id = args?['id'] as int?;
        if (id == null) return;
        final handle = _live.remove(id);
        handle?._popoverId = null;
      }
    });
  }

  /// Show a popover anchored to [anchorRect] with the given [content] widget
  /// rendered as a Flutter overlay on iOS, or an OverlayEntry on other platforms.
  ///
  /// Returns a [LiquidGlassPopoverHandle] to programmatically dismiss.
  static LiquidGlassPopoverHandle show({
    required BuildContext context,
    required WidgetBuilder builder,
    required Rect anchorRect,
    double preferredWidth = 320,
    double preferredHeight = 200,
    bool barrierDismissible = true,
  }) {
    final handle = LiquidGlassPopoverHandle._();

    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      _ensureHandlerInstalled();

      final id = _nextId++;
      handle._popoverId = id;
      _live[id] = handle;

      _presenterChannel.invokeMethod<void>('showPopover', {
        'id': id,
        'anchorX': anchorRect.left,
        'anchorY': anchorRect.top,
        'anchorWidth': anchorRect.width,
        'anchorHeight': anchorRect.height,
        'preferredWidth': preferredWidth,
        'preferredHeight': preferredHeight,
        'barrierDismissible': barrierDismissible,
      });

      return handle;
    }

    return handle;
  }
}

/// Handle to dismiss a shown popover.
class LiquidGlassPopoverHandle {
  static const _presenterChannel = MethodChannel('liquid-glass-presenter');
  int? _popoverId;
  OverlayEntry? _overlayEntry;

  LiquidGlassPopoverHandle._();

  /// Dismiss the popover.
  Future<void> dismiss() async {
    final id = _popoverId;
    if (id != null) {
      LiquidGlassPopover._live.remove(id);
      _popoverId = null;
      await _presenterChannel.invokeMethod<void>('dismissPopover', {'id': id});
    }
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
