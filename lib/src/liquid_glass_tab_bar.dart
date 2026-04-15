import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shares/liquid_glass_icon.dart';
import 'utils/native_liquid_glass_utils.dart';

/// Extra height added above the native platform view frame so the iOS liquid
/// glass visual effects (blur / glow) are not clipped when Flutter composites
/// the view with overlays such as bottom sheets or dialogs.
const double _kGlassEffectOverflow = 20.0;

/// Item positioning behavior for iOS native `UITabBar`.
enum LiquidGlassTabBarItemPositioning {
  /// iOS chooses the most appropriate positioning automatically.
  automatic,

  /// Items expand to fill available horizontal space.
  fill,

  /// Items are centered as a group.
  centered,
}

extension on LiquidGlassTabBarItemPositioning {
  String get platformValue {
    switch (this) {
      case LiquidGlassTabBarItemPositioning.automatic:
        return 'automatic';
      case LiquidGlassTabBarItemPositioning.fill:
        return 'fill';
      case LiquidGlassTabBarItemPositioning.centered:
        return 'centered';
    }
  }
}

/// A single tab item configuration used by [LiquidGlassTabBar].
class LiquidGlassTabItem {
  /// Visible tab label.
  final String label;

  /// Icon for the tab item.
  ///
  /// On iOS, SF Symbols are rendered natively. [IconData] and asset icons are
  /// rasterized to PNG and sent to the native platform view.
  final NativeLiquidGlassIcon icon;

  /// Optional icon for the selected state.
  ///
  /// When null, [icon] is reused for both states.
  final NativeLiquidGlassIcon? selectedIcon;

  /// Optional iOS badge value shown on the native tab bar item.
  ///
  /// When non-null and non-empty, a badge with text is displayed on the tab.
  /// For a dot badge without text, leave this null and set [iosShowBadge] to true.
  final String? iosBadgeValue;

  /// Whether to show a dot badge indicator on the tab.
  ///
  /// When true without [iosBadgeValue], shows a small dot badge (notification
  /// indicator). When [iosBadgeValue] is set, this defaults to true automatically.
  final bool iosShowBadge;

  /// Badge background color. Defaults to red when null.
  final Color? iosBadgeColor;

  /// Badge text color when [iosBadgeValue] is set. Defaults to white when null.
  final Color? iosBadgeTextColor;

  /// Optional icon size override for this tab item on iOS.
  ///
  /// When provided, this value takes precedence over
  /// [LiquidGlassTabBar.iconSize] for this item.
  final double? iconSize;

  /// Optional selected-state color override for this tab item on iOS.
  ///
  /// When provided, this value takes precedence over
  /// [LiquidGlassTabBar.selectedItemColor] for this item.
  final Color? selectedItemColor;

  const LiquidGlassTabItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.iosBadgeValue,
    this.iosShowBadge = false,
    this.iosBadgeColor,
    this.iosBadgeTextColor,
    this.iconSize,
    this.selectedItemColor,
  }) : assert(iconSize == null || iconSize > 0, 'iconSize must be > 0 when provided.');

  int get nativeSignature => Object.hash(
    label,
    icon.nativeSignature,
    selectedIcon?.nativeSignature,
    iosBadgeValue,
    iosShowBadge,
    iosBadgeColor?.toARGB32(),
    iosBadgeTextColor?.toARGB32(),
    iconSize,
    selectedItemColor?.toARGB32(),
  );
}

/// A bottom tab bar with a Liquid Glass background.
///
/// On iOS, this widget uses the system `UITabBarController` via platform views.
/// On non-iOS platforms, it renders a lightweight Flutter fallback.
class LiquidGlassTabBar extends StatefulWidget {
  /// Tab items to render.
  final List<LiquidGlassTabItem> items;

  /// Optional action button shown as a separate native pill on iOS.
  ///
  /// When provided, this button is rendered to the trailing side of the
  /// native tab bar and does not affect [currentIndex] selection.
  final LiquidGlassTabItem? iosActionButton;

  /// Current selected tab index.
  final int currentIndex;

  /// Callback for tab selection.
  final ValueChanged<int> onTabSelected;

  /// Callback fired when [iosActionButton] is tapped.
  final VoidCallback? onActionButtonPressed;

  /// Optional fixed width. If null, uses parent max width.
  final double? width;

  /// Bar height.
  final double height;

  /// Whether tab labels should be displayed under icons.
  final bool showLabels;

  /// Optional icon size for native tab items.
  ///
  /// Applies to SF Symbols and image-based icons on iOS.
  final double? iconSize;

  /// Optional label typography for native tab titles.
  ///
  /// Supported properties on iOS are [TextStyle.fontSize],
  /// [TextStyle.fontWeight], [TextStyle.fontFamily], and
  /// [TextStyle.letterSpacing].
  final TextStyle? labelTextStyle;

  /// Color used for selected tab item.
  ///
  /// When null, iOS uses system default tint.
  final Color? selectedItemColor;

  /// iOS native tab bar item positioning mode.
  final LiquidGlassTabBarItemPositioning iosItemPositioning;

  /// Optional iOS native item spacing.
  final double? iosItemSpacing;

  /// Optional iOS native item width.
  final double? iosItemWidth;

  const LiquidGlassTabBar({
    super.key,
    required this.items,
    this.iosActionButton,
    required this.currentIndex,
    required this.onTabSelected,
    this.onActionButtonPressed,
    this.width,
    this.height = 72,
    this.showLabels = true,
    this.iconSize,
    this.labelTextStyle,
    this.selectedItemColor,
    this.iosItemPositioning = LiquidGlassTabBarItemPositioning.automatic,
    this.iosItemSpacing,
    this.iosItemWidth,
  }) : assert(items.length >= 2, 'LiquidGlassTabBar requires at least 2 tab items.'),
       assert(currentIndex >= 0, 'currentIndex must be >= 0.'),
       assert(currentIndex < items.length, 'currentIndex must be within the range of items.'),
       assert(height >= 56, 'height should be >= 56 for comfortable tap targets.'),
       assert(iconSize == null || iconSize > 0, 'iconSize must be > 0 when provided.'),
       assert(iosItemSpacing == null || iosItemSpacing >= 0, 'iosItemSpacing must be >= 0 when provided.'),
       assert(iosItemWidth == null || iosItemWidth > 0, 'iosItemWidth must be > 0 when provided.');

  @override
  State<LiquidGlassTabBar> createState() => _LiquidGlassTabBarState();
}

class _LiquidGlassTabBarState extends State<LiquidGlassTabBar> {
  MethodChannel? _nativeChannel;
  List<Map<String, Object?>>? _nativeTabs;
  Map<String, Object?>? _nativeActionButton;
  int? _lastNativeSelectedIndex;

  int _nativeTabsVersion = 0;
  int _nativePayloadRequestId = 0;
  int _itemsSignature = 0;

  @override
  void initState() {
    super.initState();
    _itemsSignature = _computeItemsSignature(widget.items, widget.iosActionButton);
    _prepareNativeTabsPayloads();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newSignature = _computeItemsSignature(widget.items, widget.iosActionButton);
    if (newSignature != _itemsSignature) {
      _itemsSignature = newSignature;
      _prepareNativeTabsPayloads();
    }

    if (oldWidget.currentIndex != widget.currentIndex) {
      if (_lastNativeSelectedIndex == widget.currentIndex) {
        // This index already came from native user selection; avoid a redundant
        // round-trip setSelectedIndex call.
        _lastNativeSelectedIndex = null;
      } else {
        _syncNativeSelectedIndex(widget.currentIndex);
      }
    }
  }

  @override
  void reassemble() {
    super.reassemble();

    clearNativeLiquidGlassIconCaches();
    _prepareNativeTabsPayloads();
  }

  @override
  void dispose() {
    _nativePayloadRequestId++;
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onTabSelected':
        final rawIndex = call.arguments;
        if (rawIndex is int) {
          _lastNativeSelectedIndex = rawIndex;
          widget.onTabSelected(rawIndex);
        } else if (rawIndex is num) {
          final selectedIndex = rawIndex.toInt();
          _lastNativeSelectedIndex = selectedIndex;
          widget.onTabSelected(selectedIndex);
        }
        return;
      case 'onActionButtonPressed':
        widget.onActionButtonPressed?.call();
        return;
      default:
        return;
    }
  }

  void _onNativePlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-tab-bar-view/$viewId');
    channel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeChannel = channel;

    _syncNativeSelectedIndex(widget.currentIndex);
  }

  void _syncNativeSelectedIndex(int index) {
    unawaited(_invokeSetSelectedIndex(index));
  }

  Future<void> _invokeSetSelectedIndex(int index) async {
    final channel = _nativeChannel;
    if (channel == null) {
      return;
    }

    try {
      await channel.invokeMethod<void>('setSelectedIndex', index);
    } catch (_) {
      // Ignore update failures so tab interactions never crash Flutter.
    }
  }

  Map<String, Object?>? _buildLabelStylePayload(TextStyle? style) {
    if (style == null) {
      return null;
    }

    final fontWeight = _fontWeightToInt(style.fontWeight);
    final payload = <String, Object?>{
      ...?(style.fontSize == null ? null : <String, Object?>{'fontSize': style.fontSize}),
      ...?(fontWeight == null ? null : <String, Object?>{'fontWeight': fontWeight}),
      ...?(style.fontFamily?.isNotEmpty == true ? <String, Object?>{'fontFamily': style.fontFamily} : null),
      ...?(style.letterSpacing == null ? null : <String, Object?>{'letterSpacing': style.letterSpacing}),
    };

    if (payload.isEmpty) {
      return null;
    }

    return payload;
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

  int _labelStyleSignature(TextStyle? style) {
    final payload = _buildLabelStylePayload(style);
    if (payload == null) {
      return 0;
    }

    return Object.hashAllUnordered(payload.entries.map((entry) => Object.hash(entry.key, entry.value)));
  }

  Map<String, Object?> _buildNativeCreationParams(double resolvedWidth, List<Map<String, Object?>> nativeTabs, Map<String, Object?>? nativeActionButton) {
    final labelStylePayload = _buildLabelStylePayload(widget.labelTextStyle);

    return <String, Object?>{
      'width': resolvedWidth,
      'height': widget.height,
      'glassOverflow': _kGlassEffectOverflow,
      'showLabels': widget.showLabels,
      'currentIndex': widget.currentIndex,
      'itemPositioning': widget.iosItemPositioning.platformValue,
      ...?(widget.iconSize == null ? null : <String, Object?>{'iconSize': widget.iconSize}),
      ...?(labelStylePayload == null ? null : <String, Object?>{'labelStyle': labelStylePayload}),
      'selectedItemColor': widget.selectedItemColor?.toARGB32(),
      ...?(widget.iosItemSpacing == null ? null : <String, Object?>{'itemSpacing': widget.iosItemSpacing}),
      ...?(widget.iosItemWidth == null ? null : <String, Object?>{'itemWidth': widget.iosItemWidth}),
      ...?(nativeActionButton == null ? null : <String, Object?>{'actionButton': nativeActionButton}),
      'tabs': nativeTabs,
    };
  }

  Future<void> _prepareNativeTabsPayloads() async {
    final requestId = ++_nativePayloadRequestId;

    final payload = await Future.wait<Map<String, Object?>>(widget.items.map(_buildNativeTabPayload));
    final actionButtonPayload = widget.iosActionButton == null ? null : await _buildNativeTabPayload(widget.iosActionButton!);

    if (!mounted || requestId != _nativePayloadRequestId) {
      return;
    }

    setState(() {
      _nativeTabs = payload;
      _nativeActionButton = actionButtonPayload;
      _nativeTabsVersion++;
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

  int _computeItemsSignature(List<LiquidGlassTabItem> items, LiquidGlassTabItem? iosActionButton) {
    return Object.hashAll([...items.map((item) => item.nativeSignature), iosActionButton?.nativeSignature]);
  }

  double _resolveWidth(BuildContext context, BoxConstraints constraints) {
    if (widget.width != null) {
      return widget.width!;
    }
    if (constraints.hasBoundedWidth && constraints.maxWidth.isFinite) {
      return constraints.maxWidth;
    }
    return MediaQuery.sizeOf(context).width;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = _resolveWidth(context, constraints);
        final actionButtonReady = widget.iosActionButton == null || _nativeActionButton != null;

        if (NativeLiquidGlassUtils.supportsLiquidGlass && _nativeTabs != null && actionButtonReady) {
          return _buildNativeIosTabBar(resolvedWidth, _nativeTabs!, _nativeActionButton);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildNativeIosTabBar(double resolvedWidth, List<Map<String, Object?>> nativeTabs, Map<String, Object?>? nativeActionButton) {
    final nativeViewKey = ValueKey<int>(
      Object.hash(
        widget.showLabels,
        widget.items.length,
        widget.iosActionButton?.nativeSignature,
        _nativeTabsVersion,
        widget.iconSize,
        _labelStyleSignature(widget.labelTextStyle),
        widget.selectedItemColor,
        widget.iosItemPositioning,
        widget.iosItemSpacing,
        widget.iosItemWidth,
      ),
    );

    return SizedBox(
      width: resolvedWidth,
      height: widget.height + _kGlassEffectOverflow,
      child: UiKitView(
        key: nativeViewKey,
        viewType: 'liquid-glass-tab-bar-view',
        creationParams: _buildNativeCreationParams(resolvedWidth, nativeTabs, nativeActionButton),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onNativePlatformViewCreated,
      ),
    );
  }
}
