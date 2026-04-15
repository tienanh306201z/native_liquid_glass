import 'package:flutter/painting.dart';

/// A visible stroke that follows a Liquid Glass widget's shape.
///
/// The stroke traces the same path that the glass material fills —
/// capsule, rounded rectangle, circle, or custom path — so a
/// `LiquidGlassBorder` on a capsule renders as a pill outline, on a
/// circle as a ring, and so on.
///
/// Usage:
/// ```dart
/// LiquidGlassContainer(
///   config: LiquidGlassConfig(
///     shape: LiquidGlassEffectShape.capsule,
///     border: LiquidGlassBorder(
///       color: Color(0x33FFFFFF),
///       width: 1,
///     ),
///   ),
///   child: ...,
/// );
/// ```
class LiquidGlassBorder {
  /// Stroke color (ARGB). A fully-transparent color renders no
  /// visible stroke — handy for conditionally hiding the border
  /// without churning the widget tree.
  final Color color;

  /// Stroke width in logical pixels. `0` renders no stroke.
  final double width;

  const LiquidGlassBorder({
    required this.color,
    this.width = 1.0,
  }) : assert(width >= 0, 'width must be >= 0.');

  /// Serialises to the platform-channel payload shape shared by every
  /// widget that accepts a border.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'borderColor': color.toARGB32(),
      'borderWidth': width,
    };
  }

  /// A stable integer derived from the border's fields, suitable for
  /// widget-state change detection (e.g. inside `_computeConfigHash`).
  int get signature => Object.hash(color.toARGB32(), width);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiquidGlassBorder &&
          color.toARGB32() == other.color.toARGB32() &&
          width == other.width;

  @override
  int get hashCode => signature;
}
