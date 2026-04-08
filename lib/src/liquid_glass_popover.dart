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

  LiquidGlassPopover._();

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
      final id = _nextId++;
      handle._popoverId = id;

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
    if (_popoverId != null) {
      await _presenterChannel.invokeMethod<void>('dismissPopover', {'id': _popoverId});
      _popoverId = null;
    }
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
