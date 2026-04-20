import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/liquid_glass_route_suppression.dart';
import 'utils/native_liquid_glass_utils.dart';

/// Tap-only gesture claim for the native color picker's `UiKitView`.
///
/// The swatch opens the system color picker on tap; declaring the
/// recognizer up-front avoids Flutter's default lazy forwarding swallowing
/// the touch.
final Set<Factory<OneSequenceGestureRecognizer>> _colorPickerGestureRecognizers =
    <Factory<OneSequenceGestureRecognizer>>{
  Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
};

/// A native iOS color picker (UIColorWell) with Liquid Glass effects on iOS 26+.
///
/// Renders an inline color swatch that auto-opens the system color picker when
/// tapped. On non-iOS platforms, falls back to a simple color grid dialog.
class LiquidGlassColorPicker extends StatefulWidget {
  /// The initially selected color.
  final Color selectedColor;

  /// Called when a color is selected.
  final ValueChanged<Color> onColorChanged;

  /// Optional title shown in the system color picker.
  final String? title;

  /// Whether alpha/opacity selection is supported.
  final bool supportsAlpha;

  /// Size of the color swatch. Defaults to 44.
  final double size;

  const LiquidGlassColorPicker({super.key, required this.selectedColor, required this.onColorChanged, this.title, this.supportsAlpha = true, this.size = 44});

  @override
  State<LiquidGlassColorPicker> createState() => _LiquidGlassColorPickerState();
}

class _LiquidGlassColorPickerState extends State<LiquidGlassColorPicker> with LiquidGlassRouteSuppression {
  MethodChannel? _nativeChannel;
  @override MethodChannel? get suppressionChannel => _nativeChannel;
  int? _lastColor;

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'colorChanged') {
      final argb = call.arguments as int;
      widget.onColorChanged(Color(argb));
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-color-picker-view/$viewId');
    channel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeChannel = channel;
    _lastColor = widget.selectedColor.toARGB32();
    syncGlassRouteVisibility();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPropsToNativeIfNeeded();
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    final color = widget.selectedColor.toARGB32();
    if (color != _lastColor) {
      await ch.invokeMethod('setColor', {'color': color});
      _lastColor = color;
    }
  }

  Map<String, Object?> _buildCreationParams() {
    return <String, Object?>{'color': widget.selectedColor.toARGB32(), 'title': widget.title, 'supportsAlpha': widget.supportsAlpha};
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: UiKitView(
          viewType: 'liquid-glass-color-picker-view',
          creationParams: _buildCreationParams(),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: _colorPickerGestureRecognizers,
        ),
      );
    }

    return const SizedBox();
  }
}
