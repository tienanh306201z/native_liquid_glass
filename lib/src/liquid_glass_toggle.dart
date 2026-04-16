import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/liquid_glass_route_suppression.dart';
import 'utils/native_liquid_glass_utils.dart';

/// Controller for [LiquidGlassToggle].
class LiquidGlassToggleController extends ChangeNotifier {
  MethodChannel? _channel;

  /// Set the toggle value programmatically.
  Future<void> setValue(bool value, {bool animated = false}) async {
    await _channel?.invokeMethod<void>('setValue', {'value': value, 'animated': animated});
  }

  /// Enable or disable the toggle.
  Future<void> setEnabled(bool enabled) async {
    await _channel?.invokeMethod<void>('setEnabled', {'enabled': enabled});
  }
}

/// A native iOS toggle (UISwitch) with Liquid Glass effects on iOS 26+.
///
/// On iOS, this renders a native `UISwitch` through `UiKitView`.
/// On iOS 26+, the switch automatically receives glass effects during
/// interaction. On non-iOS platforms, it falls back to [Switch.adaptive].
class LiquidGlassToggle extends StatefulWidget {
  /// Current toggle value.
  final bool value;

  /// Called when the toggle value changes.
  final ValueChanged<bool> onChanged;

  /// Whether the toggle is interactive.
  final bool enabled;

  /// Optional tint color for the on state.
  final Color? color;

  /// Optional height constraint. Defaults to 44.
  final double height;

  /// Optional controller for imperative updates.
  final LiquidGlassToggleController? controller;

  const LiquidGlassToggle({super.key, required this.value, required this.onChanged, this.enabled = true, this.color, this.height = 44, this.controller});

  @override
  State<LiquidGlassToggle> createState() => _LiquidGlassToggleState();
}

class _LiquidGlassToggleState extends State<LiquidGlassToggle> with LiquidGlassRouteSuppression {
  MethodChannel? _nativeChannel;
  @override MethodChannel? get suppressionChannel => _nativeChannel;
  bool? _lastValue;
  bool? _lastEnabled;
  int? _lastColor;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _bindController();
    }
    _syncPropsToNativeIfNeeded();
  }

  void _bindController() {
    widget.controller?._channel = _nativeChannel;
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    if (_lastValue != widget.value) {
      await ch.invokeMethod('setValue', {'value': widget.value, 'animated': true});
      _lastValue = widget.value;
    }
    if (_lastEnabled != widget.enabled) {
      await ch.invokeMethod('setEnabled', {'enabled': widget.enabled});
      _lastEnabled = widget.enabled;
    }
    final color = widget.color?.toARGB32();
    if (_lastColor != color) {
      await ch.invokeMethod('setColor', {'color': color});
      _lastColor = color;
    }
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'valueChanged') {
      final value = call.arguments as bool;
      widget.onChanged(value);
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-toggle-view/$viewId');
    channel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeChannel = channel;
    widget.controller?._channel = channel;
    _lastValue = widget.value;
    _lastEnabled = widget.enabled;
    _lastColor = widget.color?.toARGB32();
    syncGlassRouteVisibility();
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  Map<String, Object?> _buildCreationParams() {
    return <String, Object?>{'value': widget.value, 'enabled': widget.enabled, 'color': widget.color?.toARGB32()};
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return SizedBox(
        width: widget.height * 51.0 / 31.0,
        height: widget.height,
        child: UiKitView(
          viewType: 'liquid-glass-toggle-view',
          creationParams: _buildCreationParams(),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{Factory<TapGestureRecognizer>(() => TapGestureRecognizer())},
        ),
      );
    }

    return const SizedBox();
  }
}
