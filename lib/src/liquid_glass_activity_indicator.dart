import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/liquid_glass_route_suppression.dart';
import 'utils/native_liquid_glass_utils.dart';

/// Style of the native iOS activity indicator.
enum LiquidGlassActivityIndicatorStyle {
  /// Medium-sized spinner (default).
  medium,

  /// Large spinner.
  large,
}

/// A native iOS activity indicator (UIActivityIndicatorView) with Liquid Glass
/// effects on iOS 26+.
///
/// On iOS, this renders a native `UIActivityIndicatorView` through `UiKitView`.
/// On non-iOS platforms, falls back to Flutter's [CircularProgressIndicator].
class LiquidGlassActivityIndicator extends StatefulWidget {
  /// Whether the indicator is animating.
  final bool animating;

  /// Whether the view is hidden when stopped. Defaults to true.
  final bool hidesWhenStopped;

  /// Style of the indicator.
  final LiquidGlassActivityIndicatorStyle style;

  /// Optional color override.
  final Color? color;

  /// Size of the widget area. Defaults to 44.
  final double size;

  const LiquidGlassActivityIndicator({
    super.key,
    this.animating = true,
    this.hidesWhenStopped = true,
    this.style = LiquidGlassActivityIndicatorStyle.medium,
    this.color,
    this.size = 44,
  }) : assert(size > 0, 'size must be > 0.');

  @override
  State<LiquidGlassActivityIndicator> createState() =>
      _LiquidGlassActivityIndicatorState();
}

class _LiquidGlassActivityIndicatorState
    extends State<LiquidGlassActivityIndicator> with LiquidGlassRouteSuppression {
  MethodChannel? _nativeChannel;
  @override MethodChannel? get suppressionChannel => _nativeChannel;
  bool? _lastAnimating;
  int? _lastColor;

  @override
  void didUpdateWidget(covariant LiquidGlassActivityIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPropsToNativeIfNeeded();
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    if (_lastAnimating != widget.animating) {
      await ch.invokeMethod('setAnimating', {'animating': widget.animating});
      _lastAnimating = widget.animating;
    }
    final color = widget.color?.toARGB32();
    if (_lastColor != color) {
      await ch.invokeMethod('setColor', {'color': color});
      _lastColor = color;
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-activity-indicator-view/$viewId');
    _nativeChannel = channel;
    _lastAnimating = widget.animating;
    _lastColor = widget.color?.toARGB32();
    syncGlassRouteVisibility();
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  Map<String, Object?> _buildCreationParams() {
    return <String, Object?>{
      'animating': widget.animating,
      'hidesWhenStopped': widget.hidesWhenStopped,
      'style': widget.style.name,
      'color': widget.color?.toARGB32(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: UiKitView(
          viewType: 'liquid-glass-activity-indicator-view',
          creationParams: _buildCreationParams(),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    }

    if (!widget.animating && widget.hidesWhenStopped) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CircularProgressIndicator.adaptive(
          valueColor: widget.color != null
              ? AlwaysStoppedAnimation<Color>(widget.color!)
              : null,
        ),
      ),
    );
  }
}
