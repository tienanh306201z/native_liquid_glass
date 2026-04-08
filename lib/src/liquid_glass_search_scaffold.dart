import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'liquid_glass_tab_bar.dart';
import 'shares/liquid_glass_icon.dart';
import 'utils/native_liquid_glass_utils.dart';

/// A full-screen scaffold that wraps a native UITabBarController with
/// inline search support (UISearchTab on iOS 26+).
///
/// This is a complete Scaffold replacement for apps that want native iOS tab
/// bar + search behavior. The tab bar supports the same customization as
/// [LiquidGlassTabBar].
///
/// On non-iOS platforms, falls back to a Flutter [Scaffold] with a
/// [BottomNavigationBar] and a search field.
class LiquidGlassSearchScaffold extends StatefulWidget {
  /// Tab items.
  final List<LiquidGlassTabItem> tabs;

  /// Called when the selected tab changes.
  final ValueChanged<int> onTabChanged;

  /// Called when the search text changes.
  final ValueChanged<String>? onSearchChanged;

  /// Called when the search is submitted.
  final ValueChanged<String>? onSearchSubmitted;

  /// Called when search becomes active/inactive.
  final ValueChanged<bool>? onSearchActiveChanged;

  /// Currently selected tab index.
  final int selectedIndex;

  /// Search hint text.
  final String searchHint;

  /// Whether the search tab is enabled.
  final bool searchEnabled;

  /// Builders for each tab's content.
  final List<WidgetBuilder> tabBuilders;

  /// Optional action button shown as a separate native pill on iOS.
  ///
  /// When provided, this button is rendered to the trailing side of the
  /// native tab bar and does not affect tab selection. Useful for search
  /// toggle, compose, or other actions.
  final LiquidGlassTabItem? iosActionButton;

  /// Callback fired when [iosActionButton] is tapped.
  final VoidCallback? onActionButtonPressed;

  /// Height of the scaffold. If null, fills available space.
  final double? height;

  // -- Tab bar customization (parity with LiquidGlassTabBar) --

  /// Whether tab labels should be displayed under icons.
  final bool showLabels;

  /// Color used for selected tab item.
  final Color? selectedItemColor;

  /// Optional icon size for native tab items.
  final double? iconSize;

  /// Optional label typography for native tab titles.
  final TextStyle? labelTextStyle;

  /// iOS native tab bar item positioning mode.
  final LiquidGlassTabBarItemPositioning iosItemPositioning;

  /// Optional iOS native item spacing.
  final double? iosItemSpacing;

  /// Optional iOS native item width.
  final double? iosItemWidth;

  const LiquidGlassSearchScaffold({
    super.key,
    required this.tabs,
    required this.onTabChanged,
    required this.tabBuilders,
    this.selectedIndex = 0,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onSearchActiveChanged,
    this.searchHint = 'Search',
    this.searchEnabled = true,
    this.iosActionButton,
    this.onActionButtonPressed,
    this.height,
    this.showLabels = true,
    this.selectedItemColor,
    this.iconSize,
    this.labelTextStyle,
    this.iosItemPositioning = LiquidGlassTabBarItemPositioning.automatic,
    this.iosItemSpacing,
    this.iosItemWidth,
  }) : assert(tabs.length == tabBuilders.length, 'tabs and tabBuilders must have the same length.');

  @override
  State<LiquidGlassSearchScaffold> createState() => _LiquidGlassSearchScaffoldState();
}

class _LiquidGlassSearchScaffoldState extends State<LiquidGlassSearchScaffold> {
  MethodChannel? _nativeChannel;
  List<Map<String, Object?>>? _nativeTabs;
  Map<String, Object?>? _nativeActionButton;
  int _nativePayloadRequestId = 0;
  bool _payloadsResolved = false;
  final int _nativeTabsVersion = 0;
  int? _lastConfigHash;

  @override
  void initState() {
    super.initState();
    _prepareNativeTabsPayloads();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassSearchScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldSig = _computeItemsSignature(oldWidget.tabs);
    final newSig = _computeItemsSignature(widget.tabs);
    if (oldSig != newSig) {
      _prepareNativeTabsPayloads();
    }
    if (oldWidget.searchEnabled != widget.searchEnabled) {
      _nativeChannel?.invokeMethod('setSearchEnabled', {'enabled': widget.searchEnabled});
    }
    _syncStyleToNativeIfNeeded();
  }

  int _computeConfigHash() {
    return Object.hashAll([
      widget.showLabels,
      widget.selectedItemColor?.toARGB32(),
      widget.iconSize,
      widget.labelTextStyle?.fontSize,
      widget.labelTextStyle?.fontWeight,
      widget.labelTextStyle?.fontFamily,
      widget.labelTextStyle?.letterSpacing,
      widget.iosItemPositioning,
      widget.iosItemSpacing,
      widget.iosItemWidth,
    ]);
  }

  Future<void> _syncStyleToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    final hash = _computeConfigHash();
    if (_lastConfigHash != hash) {
      await ch.invokeMethod('updateStyle', {
        'showLabels': widget.showLabels,
        'selectedItemColor': widget.selectedItemColor?.toARGB32(),
        if (widget.iconSize != null) 'iconSize': widget.iconSize,
        'labelStyle': _buildLabelStylePayload(widget.labelTextStyle),
        'itemPositioning': widget.iosItemPositioning.name,
        if (widget.iosItemSpacing != null) 'itemSpacing': widget.iosItemSpacing,
        if (widget.iosItemWidth != null) 'itemWidth': widget.iosItemWidth,
      });
      _lastConfigHash = hash;
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    clearNativeLiquidGlassIconCaches();
    _prepareNativeTabsPayloads();
  }

  int _computeItemsSignature(List<LiquidGlassTabItem> items) {
    return Object.hashAll(items.map((item) => item.nativeSignature));
  }

  Future<void> _prepareNativeTabsPayloads() async {
    final requestId = ++_nativePayloadRequestId;

    if (mounted) {
      setState(() {
        _payloadsResolved = false;
        _nativeTabs = null;
      });
    }

    final payload = await Future.wait<Map<String, Object?>>(widget.tabs.map(_buildNativeTabPayload));
    final actionButtonPayload = widget.iosActionButton == null ? null : await _buildNativeTabPayload(widget.iosActionButton!);

    if (!mounted || requestId != _nativePayloadRequestId) return;

    setState(() {
      _nativeTabs = payload;
      _nativeActionButton = actionButtonPayload;
      _payloadsResolved = true;
    });
  }

  Future<Map<String, Object?>> _buildNativeTabPayload(LiquidGlassTabItem item) async {
    final resolvedIcon = item.icon;
    final resolvedSelectedIcon = item.selectedIcon ?? item.icon;

    final iconPayload = await resolveIconPayload(resolvedIcon);
    final selectedPayload = await resolveIconPayload(resolvedSelectedIcon);

    return <String, Object?>{
      'label': item.label,
      'sfSymbolName': resolvedIcon.sfSymbolName,
      'selectedSfSymbolName': resolvedSelectedIcon.sfSymbolName,
      'iconDataPng': iconPayload.iconDataPng,
      'selectedIconDataPng': selectedPayload.iconDataPng,
      'assetIconPng': iconPayload.assetIconPng,
      'selectedAssetIconPng': selectedPayload.assetIconPng,
      'badgeValue': item.iosBadgeValue,
      'showBadge': item.iosShowBadge || item.iosBadgeValue != null,
      if (item.iosBadgeColor != null) 'badgeColor': item.iosBadgeColor!.toARGB32(),
      if (item.iosBadgeTextColor != null) 'badgeTextColor': item.iosBadgeTextColor!.toARGB32(),
      ...?(item.iconSize == null ? null : <String, Object?>{'iconSize': item.iconSize}),
      'selectedItemColor': item.selectedItemColor?.toARGB32(),
    };
  }

  int? _fontWeightToInt(FontWeight? fontWeight) {
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

  Map<String, Object?>? _buildLabelStylePayload(TextStyle? style) {
    if (style == null) return null;
    final payload = <String, Object?>{
      ...?(style.fontSize == null ? null : <String, Object?>{'fontSize': style.fontSize}),
      ...?(_fontWeightToInt(style.fontWeight) == null ? null : <String, Object?>{'fontWeight': _fontWeightToInt(style.fontWeight)}),
      ...?(style.fontFamily?.isNotEmpty == true ? <String, Object?>{'fontFamily': style.fontFamily} : null),
      ...?(style.letterSpacing == null ? null : <String, Object?>{'letterSpacing': style.letterSpacing}),
    };
    return payload.isEmpty ? null : payload;
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'tabChanged':
        final index = call.arguments as int;
        widget.onTabChanged(index);
      case 'searchChanged':
        final text = call.arguments as String;
        widget.onSearchChanged?.call(text);
      case 'searchSubmitted':
        final text = call.arguments as String;
        widget.onSearchSubmitted?.call(text);
      case 'searchActiveChanged':
        final active = call.arguments as bool;
        widget.onSearchActiveChanged?.call(active);
      case 'actionButtonPressed':
        widget.onActionButtonPressed?.call();
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-search-scaffold-view/$viewId');
    channel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeChannel = channel;
    _lastConfigHash = _computeConfigHash();
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  Map<String, Object?> _buildCreationParams(List<Map<String, Object?>> nativeTabs) {
    final labelStylePayload = _buildLabelStylePayload(widget.labelTextStyle);

    return <String, Object?>{
      'tabs': nativeTabs,
      'currentIndex': widget.selectedIndex,
      'showLabels': widget.showLabels,
      'selectedItemColor': widget.selectedItemColor?.toARGB32(),
      ...?(widget.iconSize == null ? null : <String, Object?>{'iconSize': widget.iconSize}),
      ...?(labelStylePayload == null ? null : <String, Object?>{'labelStyle': labelStylePayload}),
      'itemPositioning': widget.iosItemPositioning.name,
      ...?(widget.iosItemSpacing == null ? null : <String, Object?>{'itemSpacing': widget.iosItemSpacing}),
      ...?(widget.iosItemWidth == null ? null : <String, Object?>{'itemWidth': widget.iosItemWidth}),
      ...?(_nativeActionButton == null ? null : <String, Object?>{'actionButton': _nativeActionButton}),
      'searchHint': widget.searchHint,
      'searchEnabled': widget.searchEnabled,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      if (!_payloadsResolved || _nativeTabs == null) {
        return const SizedBox.shrink();
      }

      final nativeView = UiKitView(
        key: ValueKey(_nativeTabsVersion),
        viewType: 'liquid-glass-search-scaffold-view',
        creationParams: _buildCreationParams(_nativeTabs!),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );

      if (widget.height != null) {
        return SizedBox(height: widget.height, child: nativeView);
      }
      return nativeView;
    }

    return const SizedBox();
  }
}
