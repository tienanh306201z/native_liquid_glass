import 'package:flutter_test/flutter_test.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

void main() {
  test('fromPlatform parses vertical chrome payload', () {
    final insets = LiquidGlassTabBarChromeInsets.fromPlatform({
      'isVertical': true,
      'edge': 'trailing',
      'contentPaddingLeft': 0,
      'contentPaddingRight': 112,
      'contentPaddingBottom': 34,
      'hitTargetWidth': 112,
      'hitTargetHeight': 800,
    });

    expect(insets.isVertical, isTrue);
    expect(insets.edge, LiquidGlassTabBarVerticalEdge.trailing);
    expect(insets.contentPaddingRight, 112);
    expect(insets.hitTargetHeight, 800);
  });
}
