import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/native_liquid_glass_utils.dart';

/// A native iOS segmented control (UISegmentedControl) with Liquid Glass
/// effects on iOS 26+.
///
/// On iOS, this renders a native `UISegmentedControl` through `UiKitView`.
/// On non-iOS platforms, it falls back to a Flutter [SegmentedButton].
class LiquidGlassSegmentedControl extends StatefulWidget {
  /// Labels for each segment.
  final List<String> labels;

  /// Currently selected segment index.
  final int selectedIndex;

  /// Called when the selected segment changes.
  final ValueChanged<int> onValueChanged;

  /// Whether the control is interactive.
  final bool enabled;

  /// Optional tint color.
  final Color? color;

  /// Height of the control. Defaults to 32.
  final double height;

  const LiquidGlassSegmentedControl({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onValueChanged,
    this.enabled = true,
    this.color,
    this.height = 32,
  }) : assert(labels.length > 0, 'At least one label is required.'),
       assert(selectedIndex >= 0 && selectedIndex < labels.length, 'selectedIndex must be within [0, labels.length).');

  @override
  State<LiquidGlassSegmentedControl> createState() => _LiquidGlassSegmentedControlState();
}

class _LiquidGlassSegmentedControlState extends State<LiquidGlassSegmentedControl> {
  MethodChannel? _nativeChannel;

  // Incremental prop tracking
  int? _lastSelectedIndex;
  bool? _lastEnabled;
  int? _lastColor;

  @override
  void didUpdateWidget(covariant LiquidGlassSegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.labels, oldWidget.labels)) {
      _syncSegmentsToNative();
    }
    _syncPropsToNativeIfNeeded();
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  // ─── Native sync helpers ──────────────────────────────────────────────────────

  Future<void> _syncSegmentsToNative() async {
    final ch = _nativeChannel;
    if (ch == null) return;
    await ch.invokeMethod('updateSegments', _buildSegmentParams());
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    if (_lastSelectedIndex != widget.selectedIndex) {
      await ch.invokeMethod('setSelectedIndex', {'index': widget.selectedIndex, 'animated': true});
      _lastSelectedIndex = widget.selectedIndex;
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
      final index = call.arguments as int;
      widget.onValueChanged(index);
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-segmented-control-view/$viewId');
    channel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeChannel = channel;
    _lastSelectedIndex = widget.selectedIndex;
    _lastEnabled = widget.enabled;
    _lastColor = widget.color?.toARGB32();
  }

  // ─── Params builders ──────────────────────────────────────────────────────────

  Map<String, Object?> _buildSegmentParams() {
    return <String, Object?>{'labels': widget.labels};
  }

  Map<String, Object?> _buildCreationParams() {
    return <String, Object?>{..._buildSegmentParams(), 'selectedIndex': widget.selectedIndex, 'enabled': widget.enabled, 'color': widget.color?.toARGB32()};
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return SizedBox(
        height: widget.height,
        child: UiKitView(
          viewType: 'liquid-glass-segmented-control-view',
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
