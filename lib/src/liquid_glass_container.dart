import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shares/liquid_glass_config.dart';
import 'utils/liquid_glass_spring.dart';
import 'utils/native_liquid_glass_utils.dart';

/// A container widget that applies a native Liquid Glass effect to its child.
///
/// On iOS 26+, the child is rendered inside a native `UIView` with a
/// `UIGlassEffect` overlay. On unsupported platforms, the child is returned
/// unchanged.
///
/// When [config.interactive] is true, the container shows a spring press
/// animation (scale down / bounce back) on tap, matching the feel of
/// [LiquidGlassButton].
///
/// Child widgets receive touch events normally — tapping a button inside
/// the container triggers the button, not the container's [onTap].
class LiquidGlassContainer extends StatefulWidget {
  /// The widget to apply the glass effect to.
  final Widget child;

  /// Glass effect configuration.
  final LiquidGlassConfig config;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  /// When true, config changes (shape, effect, tint, etc.) animate on the
  /// native side with a spring transition instead of snapping instantly.
  final bool animateChanges;

  /// Called when the container itself is tapped (not a child widget).
  ///
  /// Child widgets participate in Flutter's normal gesture arena and take
  /// priority. [onTap] only fires when no child handles the tap.
  final VoidCallback? onTap;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.config = const LiquidGlassConfig(),
    this.width,
    this.height,
    this.animateChanges = false,
    this.onTap,
  });

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
  List<LiquidGlassPathOp>? _lastCustomPath;
  Size? _lastCustomPathSize;
  int? _lastBorderSignature;
  int? _lastBackgroundColor;

  bool _isPressed = false;

  @override
  void didUpdateWidget(covariant LiquidGlassContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPropsToNativeIfNeeded();
  }

  @override
  void reassemble() {
    super.reassemble();
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
    final customPath = widget.config.customPath;
    final customPathSize = widget.config.customPathSize;
    final borderSignature = widget.config.border?.signature;
    final backgroundColor = widget.config.backgroundColor?.toARGB32();

    if (_lastEffect != effect ||
        _lastShape != shape ||
        _lastCornerRadius != cornerRadius ||
        _lastTint != tint ||
        _lastInteractive != interactive ||
        _lastGlassEffectUnionId != unionId ||
        _lastGlassEffectId != effectId ||
        !identical(_lastCustomPath, customPath) ||
        _lastCustomPathSize != customPathSize ||
        _lastBorderSignature != borderSignature ||
        _lastBackgroundColor != backgroundColor) {
      await ch.invokeMethod('updateConfig', {
        ...widget.config.toCreationParams(),
        'animated': widget.animateChanges,
      });
      _lastEffect = effect;
      _lastShape = shape;
      _lastCornerRadius = cornerRadius;
      _lastTint = tint;
      _lastInteractive = interactive;
      _lastGlassEffectUnionId = unionId;
      _lastGlassEffectId = effectId;
      _lastCustomPath = customPath;
      _lastCustomPathSize = customPathSize;
      _lastBorderSignature = borderSignature;
      _lastBackgroundColor = backgroundColor;
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
    _lastCustomPath = widget.config.customPath;
    _lastCustomPathSize = widget.config.customPathSize;
    _lastBorderSignature = widget.config.border?.signature;
    _lastBackgroundColor = widget.config.backgroundColor?.toARGB32();
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!NativeLiquidGlassUtils.supportsLiquidGlass) {
      return const SizedBox();
    }

    final nativeView = UiKitView(
      viewType: 'liquid-glass-container-view',
      creationParams: widget.config.toCreationParams(),
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );

    Widget content = SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(child: IgnorePointer(child: nativeView)),
          widget.child,
        ],
      ),
    );

    // Interactive spring press animation.
    //
    // Scales UP (not down) on press to mirror the "spring out" aesthetic
    // that `LiquidGlassButton` and `LiquidGlassToolbar` get from Apple's
    // native `Glass.regular.interactive()` on iOS 26+. The container
    // can't just use `.interactive()` natively because its `UiKitView`
    // is wrapped in `IgnorePointer` (so Flutter child widgets inside
    // the container can still receive taps) — touches never reach the
    // native glass view, so the press feedback has to be Flutter-side.
    // Matching the spring preset (`LiquidGlassSpring.interactive()`,
    // 150 ms / 0.14 bounce) keeps the timing consistent across widgets.
    if (widget.config.interactive) {
      content = SpringBuilder(
        value: _isPressed ? 1.04 : 1.0,
        spring: LiquidGlassSpring.interactive(),
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: content,
      );
    }

    // Tap handling — children get priority via the default gesture arena.
    // onTapDown fires immediately for visual feedback; onTapCancel fires
    // if a child wins the arena, bouncing the scale back gracefully.
    if (widget.config.interactive || widget.onTap != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap?.call();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: content,
      );
    }

    return content;
  }
}
