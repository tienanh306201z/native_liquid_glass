import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shares/liquid_glass_icon.dart';
import 'utils/native_liquid_glass_utils.dart';
import 'utils/liquid_glass_route_suppression.dart';
import 'utils/text_style_utils.dart';

/// Tap gesture claim for the native navigation bar's `UiKitView`.
///
/// Leading/trailing bar-button items tap to fire `onItemTapped`;
/// declaring the recognizer up-front prevents Flutter's lazy forwarding
/// from losing the touch.
final Set<Factory<OneSequenceGestureRecognizer>> _navBarGestureRecognizers =
    <Factory<OneSequenceGestureRecognizer>>{
  Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
};

/// A navigation bar item for leading/trailing actions.
class LiquidGlassNavBarItem {
  /// Unique identifier for tap callbacks.
  final String id;

  /// Icon for this item.
  final NativeLiquidGlassIcon? icon;

  /// Text label (used as fallback if no icon).
  final String? label;

  /// Optional icon size override for this item on iOS.
  final double? iconSize;

  const LiquidGlassNavBarItem({required this.id, this.icon, this.label, this.iconSize});

  Map<String, Object?> toMap() {
    return <String, Object?>{'id': id, 'sfSymbol': icon?.sfSymbolName, 'label': label, if (iconSize != null) 'iconSize': iconSize};
  }
}

/// A native iOS navigation bar (UINavigationBar) with Liquid Glass effects
/// on iOS 26+.
///
/// On non-iOS platforms, falls back to a Flutter [AppBar].
class LiquidGlassNavigationBar extends StatefulWidget {
  /// Title text.
  final String title;

  /// Whether to use a large title style.
  final bool largeTitle;

  /// Leading bar button items.
  final List<LiquidGlassNavBarItem> leadingItems;

  /// Trailing bar button items.
  final List<LiquidGlassNavBarItem> trailingItems;

  /// Called when a bar button item is tapped. Receives the item's [id].
  final ValueChanged<String>? onItemTapped;

  /// Background color. If null, uses system default (glass on iOS 26+).
  final Color? backgroundColor;

  /// Tint color for bar items.
  final Color? tintColor;

  /// Optional text style for the navigation bar title.
  ///
  /// Supported properties: [TextStyle.fontSize], [TextStyle.fontWeight],
  /// [TextStyle.fontFamily], [TextStyle.letterSpacing], and [TextStyle.color].
  final TextStyle? titleTextStyle;

  /// Height of the bar. Defaults to 44 (standard) or 96 (large title).
  final double? height;

  /// Brightness the native bar renders with.
  ///
  /// When null (the default) the bar follows the **device** appearance, like
  /// any other UIKit bar. If your app drives its own theme (for example a
  /// `ThemeMode` toggle) pass `Theme.of(context).brightness` so the title,
  /// bar-button glyphs and glass background resolve against the same
  /// brightness as the page behind them; changes are applied to the live
  /// view without recreating it.
  final Brightness? brightness;

  const LiquidGlassNavigationBar({
    super.key,
    required this.title,
    this.largeTitle = false,
    this.leadingItems = const [],
    this.trailingItems = const [],
    this.onItemTapped,
    this.backgroundColor,
    this.tintColor,
    this.titleTextStyle,
    this.height,
    this.brightness,
  });

  @override
  State<LiquidGlassNavigationBar> createState() => _LiquidGlassNavigationBarState();
}

class _LiquidGlassNavigationBarState extends State<LiquidGlassNavigationBar> with LiquidGlassRouteSuppression {
  MethodChannel? _nativeChannel;
  @override MethodChannel? get suppressionChannel => _nativeChannel;
  String? _lastTitle;
  int? _lastTintColor;
  int? _lastBgColor;
  int _lastTitleStyleHash = 0;
  int _lastLeadingItemsHash = 0;
  int _lastTrailingItemsHash = 0;
  Map<String, Object?>? _cachedCreationParams;
  int? _creationParamsCacheKey;
  String? _lastBrightness;

  @override
  void didUpdateWidget(covariant LiquidGlassNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPropsToNativeIfNeeded();
  }

  /// [LiquidGlassNavigationBar.brightness] as the string the native side
  /// decodes; `null` means "follow the device".
  static String? _brightnessValue(Brightness? brightness) => switch (brightness) {
        null => null,
        Brightness.dark => 'dark',
        Brightness.light => 'light',
      };

  int _computeItemsHash(List<LiquidGlassNavBarItem> items) {
    return Object.hashAll(items.map((i) => Object.hash(i.id, i.icon?.nativeSignature, i.label, i.iconSize)));
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    if (_lastTitle != widget.title) {
      await ch.invokeMethod('setTitle', {'title': widget.title});
      _lastTitle = widget.title;
    }
    final tintColor = widget.tintColor?.toARGB32();
    final bgColor = widget.backgroundColor?.toARGB32();
    final titleStyleHash = textStyleSignature(widget.titleTextStyle);
    if (_lastTintColor != tintColor || _lastBgColor != bgColor || _lastTitleStyleHash != titleStyleHash) {
      await ch.invokeMethod('setStyle', {'tintColor': tintColor, 'backgroundColor': bgColor, 'titleStyle': textStylePayload(widget.titleTextStyle)});
      _lastTintColor = tintColor;
      _lastBgColor = bgColor;
      _lastTitleStyleHash = titleStyleHash;
    }
    final brightness = _brightnessValue(widget.brightness);
    if (_lastBrightness != brightness) {
      // Sent as an explicit null when cleared so native falls back to the
      // device appearance instead of keeping the previous override.
      await ch.invokeMethod('setBrightness', {'brightness': brightness});
      _lastBrightness = brightness;
    }
    final leadingHash = _computeItemsHash(widget.leadingItems);
    final trailingHash = _computeItemsHash(widget.trailingItems);
    if (_lastLeadingItemsHash != leadingHash || _lastTrailingItemsHash != trailingHash) {
      await ch.invokeMethod('setItems', {
        'leadingItems': widget.leadingItems.map((i) => i.toMap()).toList(),
        'trailingItems': widget.trailingItems.map((i) => i.toMap()).toList(),
      });
      _lastLeadingItemsHash = leadingHash;
      _lastTrailingItemsHash = trailingHash;
    }
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (!mounted) return;
    if (call.method == 'itemTapped') {
      final id = call.arguments as String?;
      if (id == null) return;
      widget.onItemTapped?.call(id);
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-navigation-bar-view/$viewId');
    channel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeChannel = channel;
    _lastTitle = widget.title;
    _lastTintColor = widget.tintColor?.toARGB32();
    _lastBgColor = widget.backgroundColor?.toARGB32();
    _lastTitleStyleHash = textStyleSignature(widget.titleTextStyle);
    _lastLeadingItemsHash = _computeItemsHash(widget.leadingItems);
    _lastTrailingItemsHash = _computeItemsHash(widget.trailingItems);
    _lastBrightness = _brightnessValue(widget.brightness);
    syncGlassRouteVisibility();
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  int _computeCreationParamsHash() {
    return Object.hashAll([
      widget.title,
      widget.largeTitle,
      _computeItemsHash(widget.leadingItems),
      _computeItemsHash(widget.trailingItems),
      widget.backgroundColor?.toARGB32(),
      widget.tintColor?.toARGB32(),
      textStyleSignature(widget.titleTextStyle),
      widget.brightness,
    ]);
  }

  Map<String, Object?> _creationParamsCached() {
    final key = _computeCreationParamsHash();
    final cached = _cachedCreationParams;
    if (_creationParamsCacheKey == key && cached != null) {
      return cached;
    }
    final params = _buildCreationParams();
    _creationParamsCacheKey = key;
    _cachedCreationParams = params;
    return params;
  }

  Map<String, Object?> _buildCreationParams() {
    return <String, Object?>{
      'title': widget.title,
      'largeTitle': widget.largeTitle,
      'leadingItems': widget.leadingItems.map((i) => i.toMap()).toList(),
      'trailingItems': widget.trailingItems.map((i) => i.toMap()).toList(),
      'backgroundColor': widget.backgroundColor?.toARGB32(),
      'tintColor': widget.tintColor?.toARGB32(),
      'titleStyle': textStylePayload(widget.titleTextStyle),
      // Optional override of the device appearance; omitted (null) means the
      // bar follows the device like any UIKit bar.
      'brightness': _brightnessValue(widget.brightness),
    };
  }

  double get _height {
    if (widget.height != null) return widget.height!;
    return widget.largeTitle ? 96 : 44;
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return SizedBox(
        height: _height,
        child: UiKitView(
          viewType: 'liquid-glass-navigation-bar-view',
          creationParams: _creationParamsCached(),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: _navBarGestureRecognizers,
        ),
      );
    }

    return const SizedBox();
  }
}
