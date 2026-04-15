import 'package:flutter/painting.dart';

/// Glass effect type used by [LiquidGlassContainer] and related components.
enum LiquidGlassEffect {
  /// Standard glass effect.
  regular,

  /// Clear glass effect with less visual weight.
  clear,
}

/// Shape of the glass effect.
enum LiquidGlassEffectShape {
  /// Rounded rectangle (uses [LiquidGlassConfig.cornerRadius]).
  rect,

  /// Fully rounded capsule (pill shape).
  capsule,

  /// Circle.
  circle,

  /// Custom shape defined by [LiquidGlassConfig.customPath].
  custom,
}

/// A single drawing operation in a custom glass shape path.
///
/// Coordinates are in the original design space defined by
/// [LiquidGlassConfig.customPathSize]. The native side scales them
/// to the actual container bounds automatically.
///
/// ```dart
/// const ops = [
///   LiquidGlassPathOp.moveTo(24, 37.78),
///   LiquidGlassPathOp.cubicTo(24, 31.07, 24, 27.72, 22.69, 25.15),
///   LiquidGlassPathOp.lineTo(0, 0),
///   LiquidGlassPathOp.close(),
/// ];
/// ```
sealed class LiquidGlassPathOp {
  const LiquidGlassPathOp();

  /// Serialises to `['type', ...args]` for the platform channel.
  List<Object> encode();

  /// Move to (x, y).
  const factory LiquidGlassPathOp.moveTo(double x, double y) = _MoveTo;

  /// Line to (x, y).
  const factory LiquidGlassPathOp.lineTo(double x, double y) = _LineTo;

  /// Cubic Bézier to (x, y) with control points (c1x, c1y) and (c2x, c2y).
  const factory LiquidGlassPathOp.cubicTo(
    double c1x, double c1y,
    double c2x, double c2y,
    double x, double y,
  ) = _CubicTo;

  /// Quadratic Bézier to (x, y) with control point (cx, cy).
  const factory LiquidGlassPathOp.quadTo(
    double cx, double cy,
    double x, double y,
  ) = _QuadTo;

  /// Close the current sub-path.
  const factory LiquidGlassPathOp.close() = _Close;
}

class _MoveTo extends LiquidGlassPathOp {
  final double x, y;
  const _MoveTo(this.x, this.y);
  @override
  List<Object> encode() => ['moveTo', x, y];
}

class _LineTo extends LiquidGlassPathOp {
  final double x, y;
  const _LineTo(this.x, this.y);
  @override
  List<Object> encode() => ['lineTo', x, y];
}

class _CubicTo extends LiquidGlassPathOp {
  final double c1x, c1y, c2x, c2y, x, y;
  const _CubicTo(this.c1x, this.c1y, this.c2x, this.c2y, this.x, this.y);
  @override
  List<Object> encode() => ['cubicTo', c1x, c1y, c2x, c2y, x, y];
}

class _QuadTo extends LiquidGlassPathOp {
  final double cx, cy, x, y;
  const _QuadTo(this.cx, this.cy, this.x, this.y);
  @override
  List<Object> encode() => ['quadTo', cx, cy, x, y];
}

class _Close extends LiquidGlassPathOp {
  const _Close();
  @override
  List<Object> encode() => ['close'];
}

/// Configuration for Liquid Glass visual effects.
///
/// Used by [LiquidGlassContainer] and other glass-enabled components.
class LiquidGlassConfig {
  /// Glass effect type.
  final LiquidGlassEffect effect;

  /// Shape of the glass effect.
  final LiquidGlassEffectShape shape;

  /// Corner radius when [shape] is [LiquidGlassEffectShape.rect].
  final double? cornerRadius;

  /// Optional tint color for the glass effect.
  final Color? tint;

  /// Whether the glass effect responds to touch interactions.
  final bool interactive;

  /// Optional ID for glass effect union.
  final String? glassEffectUnionId;

  /// Optional ID for glass effect morphing transitions.
  final String? glassEffectId;

  /// Drawing operations when [shape] is [LiquidGlassEffectShape.custom].
  ///
  /// Coordinates are in the original design space given by [customPathSize].
  final List<LiquidGlassPathOp>? customPath;

  /// The design-space size for [customPath] coordinates.
  ///
  /// The native side scales the path from this size to the actual container
  /// bounds, so you can use your SVG / design coordinates directly.
  final Size? customPathSize;

  const LiquidGlassConfig({
    this.effect = LiquidGlassEffect.regular,
    this.shape = LiquidGlassEffectShape.rect,
    this.cornerRadius,
    this.tint,
    this.interactive = false,
    this.glassEffectUnionId,
    this.glassEffectId,
    this.customPath,
    this.customPathSize,
  }) : assert(
          shape != LiquidGlassEffectShape.custom ||
              (customPath != null && customPathSize != null),
          'customPath and customPathSize are required when shape is custom',
        );

  Map<String, Object?> toCreationParams() {
    return <String, Object?>{
      'effect': effect.name,
      'shape': shape.name,
      'cornerRadius': cornerRadius,
      'tint': tint?.toARGB32(),
      'interactive': interactive,
      'glassEffectUnionId': glassEffectUnionId,
      'glassEffectId': glassEffectId,
      if (shape == LiquidGlassEffectShape.custom && customPath != null)
        'customPath': customPath!.map((op) => op.encode()).toList(),
      if (customPathSize != null) ...{
        'customPathWidth': customPathSize!.width,
        'customPathHeight': customPathSize!.height,
      },
    };
  }
}
