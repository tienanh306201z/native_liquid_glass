import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/native_liquid_glass_utils.dart';

/// Controller for [LiquidGlassSlider].
class LiquidGlassSliderController extends ChangeNotifier {
  MethodChannel? _channel;

  /// Set the slider value programmatically.
  Future<void> setValue(double value, {bool animated = false}) async {
    await _channel?.invokeMethod<void>('setValue', {'value': value, 'animated': animated});
  }

  /// Update the slider range.
  Future<void> setRange({required double min, required double max}) async {
    await _channel?.invokeMethod<void>('setRange', {'min': min, 'max': max});
  }

  /// Enable or disable the slider.
  Future<void> setEnabled(bool enabled) async {
    await _channel?.invokeMethod<void>('setEnabled', {'enabled': enabled});
  }
}

/// A native iOS slider (UISlider) with Liquid Glass effects on iOS 26+.
///
/// On iOS, this renders a native `UISlider` through `UiKitView`.
/// On iOS 26+, the slider automatically receives glass effects during drag
/// interaction. On non-iOS platforms, it falls back to [Slider.adaptive].
class LiquidGlassSlider extends StatefulWidget {
  /// Current slider value.
  final double value;

  /// Called when the slider value changes.
  final ValueChanged<double> onChanged;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Optional discrete step value.
  final double? step;

  /// Whether the slider is interactive.
  final bool enabled;

  /// Optional tint color for the filled track.
  final Color? color;

  /// Optional thumb tint color.
  final Color? thumbColor;

  /// Optional track tint color.
  final Color? trackColor;

  /// Optional background track tint color.
  final Color? trackBackgroundColor;

  /// Height of the slider area. Defaults to 44.
  final double height;

  /// Optional controller for imperative updates.
  final LiquidGlassSliderController? controller;

  const LiquidGlassSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.step,
    this.enabled = true,
    this.color,
    this.thumbColor,
    this.trackColor,
    this.trackBackgroundColor,
    this.height = 44,
    this.controller,
  }) : assert(min < max, 'min must be less than max.'),
       assert(value >= min && value <= max, 'value must be within [min, max].'),
       assert(step == null || step > 0, 'step must be > 0 when provided.');

  @override
  State<LiquidGlassSlider> createState() => _LiquidGlassSliderState();
}

class _LiquidGlassSliderState extends State<LiquidGlassSlider> {
  MethodChannel? _nativeChannel;
  double? _lastValue;
  double? _lastMin;
  double? _lastMax;
  double? _lastStep;
  bool? _lastEnabled;
  int? _lastColor;
  int? _lastThumbColor;
  int? _lastTrackColor;
  int? _lastTrackBgColor;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassSlider oldWidget) {
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
      await ch.invokeMethod('setValue', {'value': widget.value, 'animated': false});
      _lastValue = widget.value;
    }
    if (_lastMin != widget.min || _lastMax != widget.max) {
      await ch.invokeMethod('setRange', {'min': widget.min, 'max': widget.max});
      _lastMin = widget.min;
      _lastMax = widget.max;
    }
    if (_lastStep != widget.step) {
      await ch.invokeMethod('setStep', {'step': widget.step});
      _lastStep = widget.step;
    }
    if (_lastEnabled != widget.enabled) {
      await ch.invokeMethod('setEnabled', {'enabled': widget.enabled});
      _lastEnabled = widget.enabled;
    }
    final color = widget.color?.toARGB32();
    final thumbColor = widget.thumbColor?.toARGB32();
    final trackColor = widget.trackColor?.toARGB32();
    final trackBgColor = widget.trackBackgroundColor?.toARGB32();
    if (_lastColor != color || _lastThumbColor != thumbColor || _lastTrackColor != trackColor || _lastTrackBgColor != trackBgColor) {
      await ch.invokeMethod('setStyle', {'color': color, 'thumbColor': thumbColor, 'trackColor': trackColor, 'trackBackgroundColor': trackBgColor});
      _lastColor = color;
      _lastThumbColor = thumbColor;
      _lastTrackColor = trackColor;
      _lastTrackBgColor = trackBgColor;
    }
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'valueChanged') {
      final value = (call.arguments as num).toDouble();
      widget.onChanged(value);
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-slider-view/$viewId');
    channel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeChannel = channel;
    widget.controller?._channel = channel;
    _lastValue = widget.value;
    _lastMin = widget.min;
    _lastMax = widget.max;
    _lastStep = widget.step;
    _lastEnabled = widget.enabled;
    _lastColor = widget.color?.toARGB32();
    _lastThumbColor = widget.thumbColor?.toARGB32();
    _lastTrackColor = widget.trackColor?.toARGB32();
    _lastTrackBgColor = widget.trackBackgroundColor?.toARGB32();
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
      'enabled': widget.enabled,
      'color': widget.color?.toARGB32(),
      'thumbColor': widget.thumbColor?.toARGB32(),
      'trackColor': widget.trackColor?.toARGB32(),
      'trackBackgroundColor': widget.trackBackgroundColor?.toARGB32(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return SizedBox(
        height: widget.height,
        child: UiKitView(
          viewType: 'liquid-glass-slider-view',
          creationParams: _buildCreationParams(),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
          },
        ),
      );
    }
    return const SizedBox();
  }
}
