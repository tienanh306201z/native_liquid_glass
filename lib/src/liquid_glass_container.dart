import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shares/liquid_glass_config.dart';
import 'utils/native_liquid_glass_utils.dart';

/// A container widget that applies a native Liquid Glass effect to its child.
///
/// On iOS 26+, the child is rendered inside a native `UIView` with a
/// `UIGlassEffect` overlay. On unsupported platforms, the child is returned
/// unchanged.
class LiquidGlassContainer extends StatefulWidget {
  /// The widget to apply the glass effect to.
  final Widget child;

  /// Glass effect configuration.
  final LiquidGlassConfig config;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  const LiquidGlassContainer({super.key, required this.child, this.config = const LiquidGlassConfig(), this.width, this.height});

  @override
  State<LiquidGlassContainer> createState() => _LiquidGlassContainerState();
}

class _LiquidGlassContainerState extends State<LiquidGlassContainer> {
  MethodChannel? _nativeChannel;
  String? _lastEffect;
  String? _lastShape;
  double? _lastCornerRadius;
  int? _lastTint;
  bool? _lastInteractive;
  String? _lastGlassEffectUnionId;
  String? _lastGlassEffectId;

  @override
  void didUpdateWidget(covariant LiquidGlassContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPropsToNativeIfNeeded();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Force re-sync on hot reload
    _lastEffect = null;
    _syncPropsToNativeIfNeeded();
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    final effect = widget.config.effect.name;
    final shape = widget.config.shape.name;
    final cornerRadius = widget.config.cornerRadius;
    final tint = widget.config.tint?.toARGB32();
    final interactive = widget.config.interactive;
    final unionId = widget.config.glassEffectUnionId;
    final effectId = widget.config.glassEffectId;

    if (_lastEffect != effect ||
        _lastShape != shape ||
        _lastCornerRadius != cornerRadius ||
        _lastTint != tint ||
        _lastInteractive != interactive ||
        _lastGlassEffectUnionId != unionId ||
        _lastGlassEffectId != effectId) {
      await ch.invokeMethod('updateConfig', widget.config.toCreationParams());
      _lastEffect = effect;
      _lastShape = shape;
      _lastCornerRadius = cornerRadius;
      _lastTint = tint;
      _lastInteractive = interactive;
      _lastGlassEffectUnionId = unionId;
      _lastGlassEffectId = effectId;
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-container-view/$viewId');
    _nativeChannel = channel;
    _lastEffect = widget.config.effect.name;
    _lastShape = widget.config.shape.name;
    _lastCornerRadius = widget.config.cornerRadius;
    _lastTint = widget.config.tint?.toARGB32();
    _lastInteractive = widget.config.interactive;
    _lastGlassEffectUnionId = widget.config.glassEffectUnionId;
    _lastGlassEffectId = widget.config.glassEffectId;
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      final nativeView = UiKitView(
        viewType: 'liquid-glass-container-view',
        creationParams: widget.config.toCreationParams(),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );

      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(fit: StackFit.passthrough, children: [nativeView, widget.child]),
      );
    }

    return const SizedBox();
  }
}
