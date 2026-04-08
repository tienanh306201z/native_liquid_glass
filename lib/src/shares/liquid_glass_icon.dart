import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The source type of a [NativeLiquidGlassIcon].
enum _IconSourceType { sfSymbol, iconData, asset }

/// A unified icon representation for all Liquid Glass widgets.
///
/// Supports three icon sources:
/// - **SF Symbol** — native iOS system icons, referenced by name.
/// - **IconData** — Flutter Material/Cupertino icon glyphs.
/// - **Asset** — image assets from the app bundle (PNG, SVG, etc.).
///
/// On iOS, [sfSymbol] is preferred and rendered natively. [iconData] and
/// [asset] icons are rasterized to PNG and sent over the platform channel.
///
/// On non-iOS platforms, the [fallbackIcon] getter returns a Flutter [Widget].
///
/// ```dart
/// // SF Symbol (preferred on iOS)
/// NativeLiquidGlassIcon.sfSymbol('star.fill')
///
/// // Flutter IconData
/// NativeLiquidGlassIcon.iconData(Icons.star)
///
/// // Asset image
/// NativeLiquidGlassIcon.asset('assets/icons/star.png')
/// ```
@immutable
class NativeLiquidGlassIcon {
  final _IconSourceType _type;

  /// SF Symbol name. Non-null only when constructed via [NativeLiquidGlassIcon.sfSymbol].
  final String? sfSymbolName;

  /// Flutter icon data. Non-null only when constructed via [NativeLiquidGlassIcon.iconData].
  final IconData? iconDataValue;

  /// Asset path. Non-null only when constructed via [NativeLiquidGlassIcon.asset].
  final String? assetPath;

  /// Creates an icon from an SF Symbol name (native iOS).
  const NativeLiquidGlassIcon.sfSymbol(String name) : _type = _IconSourceType.sfSymbol, sfSymbolName = name, iconDataValue = null, assetPath = null;

  /// Creates an icon from Flutter [IconData].
  const NativeLiquidGlassIcon.iconData(IconData data) : _type = _IconSourceType.iconData, sfSymbolName = null, iconDataValue = data, assetPath = null;

  /// Creates an icon from an asset path (PNG, SVG, etc.).
  const NativeLiquidGlassIcon.asset(String path) : _type = _IconSourceType.asset, sfSymbolName = null, iconDataValue = null, assetPath = path;

  /// Whether this icon is an SF Symbol.
  bool get isSfSymbol => _type == _IconSourceType.sfSymbol;

  /// Whether this icon is Flutter [IconData].
  bool get isIconData => _type == _IconSourceType.iconData;

  /// Whether this icon is an asset image.
  bool get isAsset => _type == _IconSourceType.asset;

  /// Returns a Flutter [Widget] for non-iOS fallback rendering.
  ///
  /// [size] and [color] are optional overrides.
  Widget fallbackIcon({double? size, Color? color}) {
    switch (_type) {
      case _IconSourceType.sfSymbol:
        // SF Symbols don't render on non-iOS; use a generic placeholder.
        return Icon(Icons.circle_outlined, size: size, color: color);
      case _IconSourceType.iconData:
        return Icon(iconDataValue, size: size, color: color);
      case _IconSourceType.asset:
        final path = assetPath!;
        if (path.toLowerCase().endsWith('.svg')) {
          return SvgPicture.asset(path, width: size, height: size, colorFilter: color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null);
        }
        return ImageIcon(AssetImage(path), size: size, color: color);
    }
  }

  /// Serializes this icon for the native platform channel creation params.
  ///
  /// Returns a map with keys the native side expects:
  /// - `'sfSymbolName'` — SF Symbol string (or null).
  /// - `'iconDataPng'` — rasterized PNG bytes from IconData (or null).
  /// - `'assetIconPng'` — raw asset bytes (or null).
  ///
  /// Call [resolveNativePayload] first to populate PNG bytes.
  Map<String, Object?> toNativeMap(NativeLiquidGlassIconPayload? payload) {
    return <String, Object?>{'sfSymbolName': sfSymbolName, 'iconDataPng': payload?.iconDataPng, 'assetIconPng': payload?.assetIconPng};
  }

  /// A synchronous hash for change detection / native view signature.
  int get nativeSignature {
    switch (_type) {
      case _IconSourceType.sfSymbol:
        return Object.hash('sf', sfSymbolName);
      case _IconSourceType.iconData:
        return Object.hash('id', iconDataValue?.codePoint, iconDataValue?.fontFamily, iconDataValue?.fontPackage);
      case _IconSourceType.asset:
        return Object.hash('asset', assetPath);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NativeLiquidGlassIcon &&
        other._type == _type &&
        other.sfSymbolName == sfSymbolName &&
        other.iconDataValue == iconDataValue &&
        other.assetPath == assetPath;
  }

  @override
  int get hashCode => nativeSignature;
}

/// Pre-resolved binary payloads for sending a [NativeLiquidGlassIcon] to iOS.
class NativeLiquidGlassIconPayload {
  /// Rasterized PNG bytes for an [IconData] icon.
  final Uint8List? iconDataPng;

  /// Raw file bytes for an asset icon.
  final Uint8List? assetIconPng;

  const NativeLiquidGlassIconPayload({this.iconDataPng, this.assetIconPng});

  /// Whether the payload has been resolved (may still be null if the icon
  /// was an SF Symbol which needs no payload).
  bool get isEmpty => iconDataPng == null && assetIconPng == null;
}

// ---------------------------------------------------------------------------
// PNG rasterization & asset loading (reuses cached helpers)
// ---------------------------------------------------------------------------

final Map<String, Uint8List?> _iconPngCache = <String, Uint8List?>{};
final Map<String, Uint8List?> _assetBytesCache = <String, Uint8List?>{};

/// Clears all internal icon payload caches.
void clearNativeLiquidGlassIconCaches() {
  _iconPngCache.clear();
  _assetBytesCache.clear();
}

/// Resolves the native binary payload for [icon].
///
/// For SF Symbols this returns an empty payload immediately.
/// For [IconData] and asset icons the data is rasterized / loaded
/// asynchronously and cached.
Future<NativeLiquidGlassIconPayload> resolveIconPayload(NativeLiquidGlassIcon? icon) async {
  if (icon == null) {
    return const NativeLiquidGlassIconPayload();
  }

  switch (icon._type) {
    case _IconSourceType.sfSymbol:
      return const NativeLiquidGlassIconPayload();

    case _IconSourceType.iconData:
      final png = await _encodeIconDataAsPng(icon.iconDataValue!);
      return NativeLiquidGlassIconPayload(iconDataPng: png);

    case _IconSourceType.asset:
      final bytes = await _loadAssetBytes(icon.assetPath!);
      return NativeLiquidGlassIconPayload(assetIconPng: bytes);
  }
}

Future<Uint8List?> _encodeIconDataAsPng(IconData iconData) async {
  final dpr = _currentDevicePixelRatio();
  final cacheKey = _iconCacheKeyWithDpr(iconData, dpr);
  if (_iconPngCache.containsKey(cacheKey)) {
    return _iconPngCache[cacheKey];
  }

  try {
    const canvasSize = 64.0;
    const iconSize = 34.0;
    final physicalSize = (canvasSize * dpr).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(dpr);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(inherit: false, color: Colors.white, fontSize: iconSize, fontFamily: iconData.fontFamily, package: iconData.fontPackage),
      ),
    )..layout();

    final offset = Offset((canvasSize - textPainter.width) / 2, (canvasSize - textPainter.height) / 2);
    textPainter.paint(canvas, offset);

    final picture = recorder.endRecording();
    final image = await picture.toImage(physicalSize, physicalSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();

    _iconPngCache[cacheKey] = bytes;
    return bytes;
  } catch (_) {
    _iconPngCache[cacheKey] = null;
    return null;
  }
}

Future<Uint8List?> _loadAssetBytes(String assetPath) async {
  if (_assetBytesCache.containsKey(assetPath)) {
    return _assetBytesCache[assetPath];
  }

  try {
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();
    _assetBytesCache[assetPath] = bytes;
    return bytes;
  } catch (_) {
    _assetBytesCache[assetPath] = null;
    return null;
  }
}

String _iconCacheKeyWithDpr(IconData iconData, double dpr) {
  return [iconData.codePoint, iconData.fontFamily, iconData.fontPackage, iconData.matchTextDirection, dpr.toStringAsFixed(2)].join('|');
}

double _currentDevicePixelRatio() {
  final views = ui.PlatformDispatcher.instance.views;
  if (views.isEmpty) {
    return 3.0;
  }
  return views.first.devicePixelRatio;
}
