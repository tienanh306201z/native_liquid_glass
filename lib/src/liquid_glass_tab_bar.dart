import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shares/liquid_glass_icon.dart';
import 'utils/liquid_glass_route_suppression.dart';
import 'utils/native_liquid_glass_utils.dart';

/// Tap gesture claim for the native tab bar's `UiKitView`.
///
/// Tab-item selection and action-button taps go through the native
/// `UITabBarController`; declaring the recognizer up-front keeps
/// Flutter's lazy forwarding from delaying or cancelling those
/// touches.
final Set<Factory<OneSequenceGestureRecognizer>> _tabBarGestureRecognizers =
    <Factory<OneSequenceGestureRecognizer>>{
  Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
};

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
  /// On iOS the badge appearance is bar-global, so if multiple items set this
  /// the first declared item's color is applied to all badges.
  final Color? iosBadgeColor;

  /// Badge text color when [iosBadgeValue] is set. Defaults to white when null.
  /// As with [iosBadgeColor], this is bar-global on iOS (first declared item
  /// with a value wins).
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

  /// Signature of everything that requires *recreating* the native platform
  /// view when it changes: icons, labels, sizing, and badge *colors* (which are
  /// baked into the bar-global `UITabBarAppearance`). Deliberately excludes the
  /// badge value/visibility so a changing badge count can be pushed to the live
  /// view instead of forcing a teardown + rebuild (which flickers).
  int get structuralSignature => Object.hash(
    label,
    icon.nativeSignature,
    selectedIcon?.nativeSignature,
    iosBadgeColor?.toARGB32(),
    iosBadgeTextColor?.toARGB32(),
    iconSize,
    selectedItemColor?.toARGB32(),
  );

  /// Signature of the live-updatable badge state (value + dot visibility).
  int get badgeSignature => Object.hash(iosBadgeValue, iosShowBadge);
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

class _LiquidGlassTabBarState extends State<LiquidGlassTabBar> with LiquidGlassRouteSuppression {
  MethodChannel? _nativeChannel;
  @override MethodChannel? get suppressionChannel => _nativeChannel;
  List<Map<String, Object?>>? _nativeTabs;
  Map<String, Object?>? _nativeActionButton;
  int? _lastNativeSelectedIndex;

  int _nativeTabsVersion = 0;
  int _nativePayloadRequestId = 0;
  int _itemsStructuralSignature = 0;
  int _badgeSignature = 0;
  Map<String, Object?>? _cachedCreationParams;
  int? _creationParamsCacheKey;

  @override
  void initState() {
    super.initState();
    _itemsStructuralSignature =
        _computeStructuralSignature(widget.items, widget.iosActionButton);
    _badgeSignature = _computeBadgeSignature(widget.items, widget.iosActionButton);
    _prepareNativeTabsPayloads();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newStructural =
        _computeStructuralSignature(widget.items, widget.iosActionButton);
    if (newStructural != _itemsStructuralSignature) {
      // Icons / labels / sizing / badge colors changed: the native view must be
      // rebuilt (new key + fresh creationParams).
      _itemsStructuralSignature = newStructural;
      _badgeSignature = _computeBadgeSignature(widget.items, widget.iosActionButton);
      _prepareNativeTabsPayloads();
    } else {
      final newBadge = _computeBadgeSignature(widget.items, widget.iosActionButton);
      if (newBadge != _badgeSignature) {
        // Only the badge value/visibility changed: push it to the live native
        // view instead of recreating it (which would flicker).
        _badgeSignature = newBadge;
        _pushBadgeUpdate();
      }
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
    _cachedCreationParams = null;
    _creationParamsCacheKey = null;
    _prepareNativeTabsPayloads();
  }

  @override
  void dispose() {
    _nativePayloadRequestId++;
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }
  void _rollbackIfSelectionRejected(int nativeSelectedIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.currentIndex == nativeSelectedIndex) {
        return;
      }
      _lastNativeSelectedIndex = null;
      _syncNativeSelectedIndex(widget.currentIndex);
    });
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (!mounted) return;
    switch (call.method) {
      case 'onTabSelected':
        final rawIndex = call.arguments;
        if (rawIndex is num) {
          final selectedIndex = rawIndex.toInt();
          _lastNativeSelectedIndex = selectedIndex;
          widget.onTabSelected(selectedIndex);
          _rollbackIfSelectionRejected(selectedIndex);
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
    syncGlassRouteVisibility();
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
    if (style == null) return 0;
    // Hash the fields directly — avoids building an intermediate `Map` just
    // to iterate its entries. The four fields below are exactly what
    // `_buildLabelStylePayload` emits; keep them in sync if either side
    // grows new fields.
    return Object.hash(
      style.fontSize,
      _fontWeightToInt(style.fontWeight),
      style.fontFamily?.isNotEmpty == true ? style.fontFamily : null,
      style.letterSpacing,
    );
  }

  Map<String, Object?> _creationParamsCached(double resolvedWidth, List<Map<String, Object?>> nativeTabs, Map<String, Object?>? nativeActionButton, String brightness) {
    // `nativeTabs`/`nativeActionButton` change identity only when
    // `_prepareNativeTabsPayloads` publishes a new list via setState,
    // so identity hashing is a safe proxy for their content here.
    final key = Object.hashAll([
      resolvedWidth,
      widget.height,
      widget.showLabels,
      widget.currentIndex,
      widget.iosItemPositioning,
      widget.iconSize,
      _labelStyleSignature(widget.labelTextStyle),
      widget.selectedItemColor?.toARGB32(),
      widget.iosItemSpacing,
      widget.iosItemWidth,
      brightness,
      identityHashCode(nativeTabs),
      identityHashCode(nativeActionButton),
    ]);
    final cached = _cachedCreationParams;
    if (_creationParamsCacheKey == key && cached != null) {
      return cached;
    }
    final params = _buildNativeCreationParams(resolvedWidth, nativeTabs, nativeActionButton, brightness);
    _creationParamsCacheKey = key;
    _cachedCreationParams = params;
    return params;
  }

  Map<String, Object?> _buildNativeCreationParams(double resolvedWidth, List<Map<String, Object?>> nativeTabs, Map<String, Object?>? nativeActionButton, String brightness) {
    final labelStylePayload = _buildLabelStylePayload(widget.labelTextStyle);

    return <String, Object?>{
      'width': resolvedWidth,
      'height': widget.height,
      'glassOverflow': _kGlassEffectOverflow,
      'showLabels': widget.showLabels,
      'currentIndex': widget.currentIndex,
      'itemPositioning': widget.iosItemPositioning.platformValue,
      'brightness': brightness,
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

  int _computeStructuralSignature(
      List<LiquidGlassTabItem> items, LiquidGlassTabItem? iosActionButton) {
    return Object.hashAll([
      ...items.map((item) => item.structuralSignature),
      iosActionButton?.structuralSignature,
    ]);
  }

  int _computeBadgeSignature(
      List<LiquidGlassTabItem> items, LiquidGlassTabItem? iosActionButton) {
    return Object.hashAll([
      ...items.map((item) => item.badgeSignature),
      iosActionButton?.badgeSignature,
    ]);
  }

  /// Pushes the current badge values to the live native view (no platform-view
  /// recreation) and keeps the cached creation payload in sync so a *later*
  /// structural rebuild carries the current values.
  void _pushBadgeUpdate() {
    _applyBadgesToCachedTabs();

    final badges = <Map<String, Object?>>[
      for (final item in widget.items) _badgePayload(item),
      if (widget.iosActionButton != null) _badgePayload(widget.iosActionButton!),
    ];
    unawaited(_invokeUpdateBadges(badges));
  }

  Map<String, Object?> _badgePayload(LiquidGlassTabItem item) => <String, Object?>{
        'badgeValue': item.iosBadgeValue,
        'showBadge': item.iosShowBadge || item.iosBadgeValue != null,
      };

  /// Mutates the cached native-tab payload so a *later* platform-view
  /// recreation (e.g. a brightness flip) carries the current badge values
  /// instead of the ones captured when the payload was last built.
  void _applyBadgesToCachedTabs() {
    final tabs = _nativeTabs;
    if (tabs != null) {
      for (var i = 0; i < tabs.length && i < widget.items.length; i++) {
        final payload = _badgePayload(widget.items[i]);
        tabs[i]['badgeValue'] = payload['badgeValue'];
        tabs[i]['showBadge'] = payload['showBadge'];
      }
    }

    final actionButton = widget.iosActionButton;
    final cachedAction = _nativeActionButton;
    if (actionButton != null && cachedAction != null) {
      final payload = _badgePayload(actionButton);
      cachedAction['badgeValue'] = payload['badgeValue'];
      cachedAction['showBadge'] = payload['showBadge'];
    }

    // The payload maps were mutated in place (identity unchanged), so force the
    // creation-params cache to rebuild from them on the next view creation.
    _creationParamsCacheKey = null;
  }

  Future<void> _invokeUpdateBadges(List<Map<String, Object?>> badges) async {
    final channel = _nativeChannel;
    if (channel == null) {
      return;
    }
    try {
      await channel.invokeMethod<void>('updateBadges', badges);
    } catch (_) {
      // Ignore update failures so badge changes never crash Flutter.
    }
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
          // Mirror the app's theme brightness to the native bar so its
          // background, labels, and icons follow the Flutter theme instead of
          // the device appearance (which made them invert after navigation).
          final brightness = Theme.of(context).brightness == Brightness.dark ? 'dark' : 'light';
          return _buildNativeIosTabBar(resolvedWidth, _nativeTabs!, _nativeActionButton, brightness);
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildNativeIosTabBar(double resolvedWidth, List<Map<String, Object?>> nativeTabs, Map<String, Object?>? nativeActionButton, String brightness) {
    final nativeViewKey = ValueKey<int>(
      Object.hash(
        widget.showLabels,
        widget.items.length,
        widget.iosActionButton?.structuralSignature,
        _nativeTabsVersion,
        widget.iconSize,
        _labelStyleSignature(widget.labelTextStyle),
        widget.selectedItemColor,
        widget.iosItemPositioning,
        widget.iosItemSpacing,
        widget.iosItemWidth,
        // Recreate the platform view when the app theme flips so the native
        // bar picks up the new brightness via creationParams.
        brightness,
      ),
    );

    return SizedBox(
      width: resolvedWidth,
      height: widget.height + _kGlassEffectOverflow,
      child: UiKitView(
        key: nativeViewKey,
        viewType: 'liquid-glass-tab-bar-view',
        creationParams: _creationParamsCached(resolvedWidth, nativeTabs, nativeActionButton, brightness),
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onNativePlatformViewCreated,
        gestureRecognizers: _tabBarGestureRecognizers,
      ),
    );
  }
}
