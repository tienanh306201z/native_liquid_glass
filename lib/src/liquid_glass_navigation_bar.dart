import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shares/liquid_glass_icon.dart';
import 'utils/native_liquid_glass_utils.dart';
import 'utils/liquid_glass_route_suppression.dart';
import 'utils/text_style_utils.dart';

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
  /// [TextStyle.fontFamily], and [TextStyle.letterSpacing].
  final TextStyle? titleTextStyle;

  /// Height of the bar. Defaults to 44 (standard) or 96 (large title).
  final double? height;

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

  @override
  void didUpdateWidget(covariant LiquidGlassNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPropsToNativeIfNeeded();
  }

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
    if (call.method == 'itemTapped') {
      final id = call.arguments as String;
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
    syncGlassRouteVisibility();
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
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
          creationParams: _buildCreationParams(),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    }

    return const SizedBox();
  }
}
