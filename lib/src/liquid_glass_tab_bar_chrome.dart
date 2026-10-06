import 'package:flutter/foundation.dart';

/// Native tab bar layout reported from iOS (e.g. iPhone Duo vertical column).
@immutable
class LiquidGlassTabBarChromeInsets {
  const LiquidGlassTabBarChromeInsets({
    required this.isVertical,
    this.edge = LiquidGlassTabBarVerticalEdge.none,
    this.contentPaddingLeft = 0,
    this.contentPaddingRight = 0,
    this.contentPaddingBottom = 0,
    this.hitTargetWidth = 0,
    this.hitTargetHeight = 0,
  });

  const LiquidGlassTabBarChromeInsets.horizontal({
    double bottomPadding = 0,
  }) : this(
          isVertical: false,
          contentPaddingBottom: bottomPadding,
        );

  static const zero = LiquidGlassTabBarChromeInsets(isVertical: false);

  /// Matches iOS `LiquidGlassTabBarChromeLayout.defaultVerticalHitWidth`.
  static const defaultVerticalHitWidth = 112.0;

  final bool isVertical;
  final LiquidGlassTabBarVerticalEdge edge;
  final double contentPaddingLeft;
  final double contentPaddingRight;
  final double contentPaddingBottom;
  final double hitTargetWidth;
  final double hitTargetHeight;

  factory LiquidGlassTabBarChromeInsets.fromPlatform(Object? raw) {
    if (raw is! Map) {
      return LiquidGlassTabBarChromeInsets.zero;
    }
    final map = raw.cast<Object?, Object?>();
    bool boolFor(Object? key) => map[key] == true;
    double doubleFor(Object? key) {
      final value = map[key];
      if (value is num) return value.toDouble();
      return 0;
    }

    final edgeRaw = map['edge'];
    final edge = switch (edgeRaw) {
      'leading' => LiquidGlassTabBarVerticalEdge.leading,
      'trailing' => LiquidGlassTabBarVerticalEdge.trailing,
      _ => LiquidGlassTabBarVerticalEdge.none,
    };

    return LiquidGlassTabBarChromeInsets(
      isVertical: boolFor('isVertical'),
      edge: edge,
      contentPaddingLeft: doubleFor('contentPaddingLeft'),
      contentPaddingRight: doubleFor('contentPaddingRight'),
      contentPaddingBottom: doubleFor('contentPaddingBottom'),
      hitTargetWidth: doubleFor('hitTargetWidth'),
      hitTargetHeight: doubleFor('hitTargetHeight'),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is LiquidGlassTabBarChromeInsets &&
        other.isVertical == isVertical &&
        other.edge == edge &&
        other.contentPaddingLeft == contentPaddingLeft &&
        other.contentPaddingRight == contentPaddingRight &&
        other.contentPaddingBottom == contentPaddingBottom &&
        other.hitTargetWidth == hitTargetWidth &&
        other.hitTargetHeight == hitTargetHeight;
  }

  @override
  int get hashCode => Object.hash(
        isVertical,
        edge,
        contentPaddingLeft,
        contentPaddingRight,
        contentPaddingBottom,
        hitTargetWidth,
        hitTargetHeight,
      );
}

enum LiquidGlassTabBarVerticalEdge { none, leading, trailing }
