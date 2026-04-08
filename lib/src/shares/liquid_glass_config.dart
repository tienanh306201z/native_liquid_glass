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
  ///
  /// When multiple glass views share the same [glassEffectUnionId], they will
  /// be combined into a single unified Liquid Glass effect.
  /// Only applies on iOS 26+.
  final String? glassEffectUnionId;

  /// Optional ID for glass effect morphing transitions.
  ///
  /// When a glass view with a [glassEffectId] appears or disappears, it will
  /// morph into/out of other views with the same ID.
  /// Only applies on iOS 26+.
  final String? glassEffectId;

  const LiquidGlassConfig({
    this.effect = LiquidGlassEffect.regular,
    this.shape = LiquidGlassEffectShape.rect,
    this.cornerRadius,
    this.tint,
    this.interactive = false,
    this.glassEffectUnionId,
    this.glassEffectId,
  });

  Map<String, Object?> toCreationParams() {
    return <String, Object?>{
      'effect': effect.name,
      'shape': shape.name,
      'cornerRadius': cornerRadius,
      'tint': tint?.toARGB32(),
      'interactive': interactive,
      'glassEffectUnionId': glassEffectUnionId,
      'glassEffectId': glassEffectId,
    };
  }
}
