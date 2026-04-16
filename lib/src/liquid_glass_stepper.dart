import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/liquid_glass_route_suppression.dart';
import 'utils/native_liquid_glass_utils.dart';

/// Controller for [LiquidGlassStepper].
class LiquidGlassStepperController extends ChangeNotifier {
  MethodChannel? _channel;

  /// Set the stepper value programmatically.
  Future<void> setValue(double value) async {
    await _channel?.invokeMethod<void>('setValue', {'value': value});
  }

  /// Enable or disable the stepper.
  Future<void> setEnabled(bool enabled) async {
    await _channel?.invokeMethod<void>('setEnabled', {'enabled': enabled});
  }
}

/// A native iOS stepper (UIStepper) with Liquid Glass effects on iOS 26+.
///
/// On iOS, this renders a native `UIStepper` through `UiKitView`.
/// On non-iOS platforms, falls back to a Flutter [Row] with +/− [IconButton]s.
class LiquidGlassStepper extends StatefulWidget {
  /// Current stepper value.
  final double value;

  /// Called when the stepper value changes.
  final ValueChanged<double> onChanged;

  /// Minimum value. Defaults to 0.
  final double min;

  /// Maximum value. Defaults to 100.
  final double max;

  /// Increment/decrement step size. Defaults to 1.
  final double step;

  /// Whether the stepper wraps around at min/max boundaries.
  final bool wraps;

  /// Whether the stepper is interactive.
  final bool enabled;

  /// Optional tint color applied to the stepper control.
  final Color? color;

  /// Height of the stepper area. Defaults to 44.
  final double height;

  /// Width of the stepper area. Defaults to 94 (native UIStepper intrinsic width).
  ///
  /// Must be set explicitly when placing [LiquidGlassStepper] inside a [Row]
  /// without an [Expanded] wrapper, otherwise [UiKitView] receives unbounded
  /// width constraints and the layout will fail.
  final double width;

  /// Optional controller for imperative updates.
  final LiquidGlassStepperController? controller;

  const LiquidGlassStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.wraps = false,
    this.enabled = true,
    this.color,
    this.height = 44,
    this.width = 94,
    this.controller,
  }) : assert(min < max, 'min must be less than max.'),
       assert(value >= min && value <= max, 'value must be within [min, max].'),
       assert(step > 0, 'step must be > 0.');

  @override
  State<LiquidGlassStepper> createState() => _LiquidGlassStepperState();
}

class _LiquidGlassStepperState extends State<LiquidGlassStepper> with LiquidGlassRouteSuppression {
  MethodChannel? _nativeChannel;
  @override MethodChannel? get suppressionChannel => _nativeChannel;
  double? _lastValue;
  double? _lastMin;
  double? _lastMax;
  double? _lastStep;
  bool? _lastWraps;
  bool? _lastEnabled;
  int? _lastColor;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassStepper oldWidget) {
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
      await ch.invokeMethod('setValue', {'value': widget.value});
      _lastValue = widget.value;
    }
    if (_lastMin != widget.min || _lastMax != widget.max || _lastStep != widget.step) {
      await ch.invokeMethod('setRange', {'min': widget.min, 'max': widget.max, 'step': widget.step});
      _lastMin = widget.min;
      _lastMax = widget.max;
      _lastStep = widget.step;
    }
    if (_lastWraps != widget.wraps) {
      await ch.invokeMethod('setWraps', {'wraps': widget.wraps});
      _lastWraps = widget.wraps;
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
      final value = (call.arguments as num).toDouble();
      // Record the native value before calling onChanged so that the
      // subsequent didUpdateWidget→_syncPropsToNativeIfNeeded does not
      // echo the value back unnecessarily.
      _lastValue = value;
      widget.onChanged(value);
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-stepper-view/$viewId');
    channel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeChannel = channel;
    widget.controller?._channel = channel;
    _lastValue = widget.value;
    _lastMin = widget.min;
    _lastMax = widget.max;
    _lastStep = widget.step;
    _lastWraps = widget.wraps;
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
    return <String, Object?>{
      'value': widget.value,
      'min': widget.min,
      'max': widget.max,
      'step': widget.step,
      'wraps': widget.wraps,
      'enabled': widget.enabled,
      'color': widget.color?.toARGB32(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: UiKitView(
          viewType: 'liquid-glass-stepper-view',
          creationParams: _buildCreationParams(),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{Factory<TapGestureRecognizer>(() => TapGestureRecognizer())},
        ),
      );
    }

    // Flutter fallback
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: widget.enabled && widget.value > widget.min ? () => widget.onChanged((widget.value - widget.step).clamp(widget.min, widget.max)) : null,
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(widget.value.toStringAsFixed(widget.step < 1 ? 1 : 0))),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: widget.enabled && widget.value < widget.max ? () => widget.onChanged((widget.value + widget.step).clamp(widget.min, widget.max)) : null,
          ),
        ],
      ),
    );
  }
}
