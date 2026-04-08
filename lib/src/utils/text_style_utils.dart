import 'package:flutter/material.dart';

/// Converts a Flutter [TextStyle] to a map that can be passed as a native
/// channel creation parameter (or creation params sub-map).
///
/// Supported properties: [TextStyle.fontSize], [TextStyle.fontWeight],
/// [TextStyle.fontFamily], and [TextStyle.letterSpacing].
///
/// Returns `null` when [style] is null or contains no applicable properties.
Map<String, Object?>? textStylePayload(TextStyle? style) {
  if (style == null) return null;
  final weight = _fontWeightValue(style.fontWeight);
  final payload = <String, Object?>{
    ...?(style.fontSize == null ? null : <String, Object?>{'fontSize': style.fontSize}),
    ...?(weight == null ? null : <String, Object?>{'fontWeight': weight}),
    ...?(style.fontFamily?.isNotEmpty == true ? <String, Object?>{'fontFamily': style.fontFamily} : null),
    ...?(style.letterSpacing == null ? null : <String, Object?>{'letterSpacing': style.letterSpacing}),
  };
  return payload.isEmpty ? null : payload;
}

/// Returns a stable hash for [style] suitable for use in a native view
/// signature computation.
int textStyleSignature(TextStyle? style) {
  if (style == null) return 0;
  final payload = textStylePayload(style);
  if (payload == null) return 0;
  return Object.hashAllUnordered(payload.entries.map((e) => Object.hash(e.key, e.value)));
}

int? _fontWeightValue(FontWeight? fontWeight) {
  return switch (fontWeight) {
    null => null,
    FontWeight.w100 => 100,
    FontWeight.w200 => 200,
    FontWeight.w300 => 300,
    FontWeight.w400 => 400,
    FontWeight.w500 => 500,
    FontWeight.w600 => 600,
    FontWeight.w700 => 700,
    FontWeight.w800 => 800,
    FontWeight.w900 => 900,
    _ => 400,
  };
}
