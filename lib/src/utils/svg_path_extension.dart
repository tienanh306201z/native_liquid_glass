import 'package:flutter/widgets.dart';
import 'package:path_parsing/path_parsing.dart';

import '../shares/liquid_glass_config.dart';

/// Convenience extensions for turning an SVG path data string
/// (e.g. the `d` attribute of an `<path>` element) into a Flutter [Path]
/// or a `LiquidGlassConfig.customPath`.
///
/// Works with any valid SVG path data, including paths with quadratic
/// Béziers (those get normalized to cubic Béziers — matching the same
/// behavior used by iOS's path rendering).
///
/// Usage:
/// ```dart
/// LiquidGlassContainer(
///   config: LiquidGlassConfig(
///     shape: LiquidGlassEffectShape.custom,
///     customPath: 'M10 10 L20 20 Z'.toLiquidGlassPath(),
///     customPathSize: const Size(30, 30),
///   ),
///   child: ...,
/// );
/// ```
extension SvgPathExtension on String {
  /// Parses this SVG path data string (`"M10 10 L20 20 Z"`) into a Flutter [Path].
  Path toPath() => _parseSvgPathData(this);

  /// Parses this SVG path and scales it from [viewBox] space to [target] space.
  Path toPathScaled({required Size viewBox, required Size target}) {
    final path = _parseSvgPathData(this);
    final scaleX = target.width / viewBox.width;
    final scaleY = target.height / viewBox.height;
    final matrix = Matrix4.identity()..scaleByDouble(scaleX, scaleY, 1.0, 1.0);
    return path.transform(matrix.storage);
  }

  /// Parses this SVG path data string into a list of [LiquidGlassPathOp]s for
  /// the `customPath` field of [LiquidGlassConfig].
  ///
  /// Coordinates remain in the original SVG path space — pass the SVG viewBox
  /// as `customPathSize` on [LiquidGlassConfig] so the native side can scale.
  ///
  /// Usage:
  /// ```dart
  /// LiquidGlassConfig(
  ///   shape: LiquidGlassEffectShape.custom,
  ///   customPath: 'M10 10 L20 20 Z'.toLiquidGlassPath(),
  ///   customPathSize: const Size(30, 30),
  /// )
  /// ```
  ///
  /// Quadratic Béziers in the source SVG are normalized to cubic Béziers
  /// (matches `path_parsing`'s behavior).
  List<LiquidGlassPathOp> toLiquidGlassPath() {
    // Strip any leading characters until the first M/m. Handles paths with
    // leading whitespace, newlines, BOMs, comments, or stray characters from
    // copy/paste that would otherwise trip SvgPathNormalizer.
    final firstMove = indexOf(RegExp('[Mm]'));
    if (firstMove < 0) return const [];
    final cleaned = substring(firstMove);

    final proxy = _LiquidGlassPathProxy();
    final parser = SvgPathStringSource(cleaned);
    final normalizer = SvgPathNormalizer();
    for (final segment in parser.parseSegments()) {
      normalizer.emitSegment(segment, proxy);
    }
    return proxy.ops;
  }

  /// Like [toLiquidGlassPath] but maps every coordinate from the SVG
  /// [viewBox] (an arbitrary [Rect], so non-zero origin is handled) to
  /// [target] space. Use this when the SVG viewBox is e.g. `"1 0 24 226"`
  /// instead of `"0 0 24 226"`.
  ///
  /// Pass [viewBox] as `Rect.fromLTWH(minX, minY, width, height)` from the
  /// SVG's `viewBox` attribute.
  List<LiquidGlassPathOp> toLiquidGlassPathScaled({
    required Rect viewBox,
    required Size target,
  }) {
    final ops = toLiquidGlassPath();
    final sx = target.width / viewBox.width;
    final sy = target.height / viewBox.height;
    final tx = -viewBox.left;
    final ty = -viewBox.top;
    return ops
        .map((op) => _transformOp(op, tx, ty, sx, sy))
        .toList(growable: false);
  }
}

/// Parses an SVG path data string into a Flutter [Path].
///
/// Uses `path_parsing` directly so we don't need to take on a
/// `path_drawing` dependency just for this helper.
Path _parseSvgPathData(String svgData) {
  // Strip any leading characters until the first M/m (see `toLiquidGlassPath`).
  final firstMove = svgData.indexOf(RegExp('[Mm]'));
  if (firstMove < 0) return Path();
  final cleaned = svgData.substring(firstMove);

  final proxy = _UiPathProxy();
  final parser = SvgPathStringSource(cleaned);
  final normalizer = SvgPathNormalizer();
  for (final segment in parser.parseSegments()) {
    normalizer.emitSegment(segment, proxy);
  }
  return proxy.path;
}

/// Applies translate-then-scale to every coordinate of [op].
///
/// Translation is applied first (to move the viewBox origin to (0,0)),
/// then scaling.
LiquidGlassPathOp _transformOp(
  LiquidGlassPathOp op,
  double tx,
  double ty,
  double sx,
  double sy,
) {
  // Re-encode → re-build because LiquidGlassPathOp's internal classes are private.
  double mapX(Object v) => ((v as double) + tx) * sx;
  double mapY(Object v) => ((v as double) + ty) * sy;

  final encoded = op.encode();
  switch (encoded[0] as String) {
    case 'moveTo':
      return LiquidGlassPathOp.moveTo(mapX(encoded[1]), mapY(encoded[2]));
    case 'lineTo':
      return LiquidGlassPathOp.lineTo(mapX(encoded[1]), mapY(encoded[2]));
    case 'cubicTo':
      return LiquidGlassPathOp.cubicTo(
        mapX(encoded[1]), mapY(encoded[2]),
        mapX(encoded[3]), mapY(encoded[4]),
        mapX(encoded[5]), mapY(encoded[6]),
      );
    case 'quadTo':
      return LiquidGlassPathOp.quadTo(
        mapX(encoded[1]), mapY(encoded[2]),
        mapX(encoded[3]), mapY(encoded[4]),
      );
    case 'close':
    default:
      return op;
  }
}

class _LiquidGlassPathProxy extends PathProxy {
  final List<LiquidGlassPathOp> ops = [];

  @override
  void moveTo(double x, double y) => ops.add(LiquidGlassPathOp.moveTo(x, y));

  @override
  void lineTo(double x, double y) => ops.add(LiquidGlassPathOp.lineTo(x, y));

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => ops.add(LiquidGlassPathOp.cubicTo(x1, y1, x2, y2, x3, y3));

  @override
  void close() => ops.add(const LiquidGlassPathOp.close());
}

class _UiPathProxy extends PathProxy {
  final Path path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}
