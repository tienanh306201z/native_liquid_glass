import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shares/liquid_glass_border.dart';
import 'shares/liquid_glass_icon.dart';
import 'utils/native_liquid_glass_utils.dart';
import 'utils/liquid_glass_route_suppression.dart';
import 'utils/text_style_utils.dart';

/// Tap-only gesture claim for the native toolbar's `UiKitView`.
///
/// Matches the pattern used by the other interactive native widgets:
/// joining the gesture arena for taps ensures full down→up sequences
/// reach the SwiftUI buttons instead of getting delayed or cancelled
/// by Flutter's default lazy-forwarding for platform views.
final Set<Factory<OneSequenceGestureRecognizer>> _toolbarGestureRecognizers =
    <Factory<OneSequenceGestureRecognizer>>{
  Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
};

/// A toolbar item.
class LiquidGlassToolbarItem {
  /// Unique identifier.
  final String id;

  /// Icon for this item.
  final NativeLiquidGlassIcon? icon;

  /// Text label.
  final String? label;

  /// Whether this item is enabled.
  final bool enabled;

  /// Optional icon size for this item on iOS.
  final double? iconSize;

  /// Optional per-item tint color.
  ///
  /// When provided, colors this item's icon or text directly via
  /// `foregroundStyle` on iOS 26+. When null, the item inherits the
  /// ambient foreground color from the host.
  final Color? tintColor;

  const LiquidGlassToolbarItem({
    required this.id,
    this.icon,
    this.label,
    this.enabled = true,
    this.iconSize,
    this.tintColor,
  });

  Map<String, Object?> toMap([NativeLiquidGlassIconPayload? payload]) {
    return <String, Object?>{
      'id': id,
      'sfSymbol': icon?.sfSymbolName,
      if (payload?.iconDataPng != null) 'iconDataPng': payload!.iconDataPng,
      if (payload?.assetIconPng != null) 'assetIconPng': payload!.assetIconPng,
      'label': label,
      'enabled': enabled,
      if (iconSize != null) 'iconSize': iconSize,
      if (tintColor != null) 'tintColor': tintColor!.toARGB32(),
    };
  }
}

/// A special item that splits the toolbar into separate glass capsules,
/// with either a flexible or a fixed gap between them.
///
/// Both kinds of spacer **split** the items list: every run of items
/// between spacers becomes its own independent Liquid Glass pill, just
/// like Apple's iOS 26 split-toolbar pattern in Mail / Safari.
///
/// * `flexible: true` (default) — the gap between capsules expands to
///   distribute leftover horizontal space. Best inside a fill-parent
///   toolbar (the auto-promote rule on [LiquidGlassToolbar.width]
///   handles this when `width` is null).
/// * `flexible: false, width: X` — the gap between capsules is exactly
///   `X` points. Useful for a tight, predictable separation between
///   pills regardless of available width.
class LiquidGlassToolbarSpacer extends LiquidGlassToolbarItem {
  /// If true, the gap between the surrounding capsules expands to fill
  /// leftover horizontal space (`Spacer()`). If false, the gap is fixed
  /// at [width] points.
  final bool flexible;

  /// Width for fixed spacers. Defaults to 16 on iOS.
  final double? width;

  const LiquidGlassToolbarSpacer({this.flexible = true, this.width}) : super(id: flexible ? '__flexible_space__' : '__fixed_space__');

  @override
  Map<String, Object?> toMap([NativeLiquidGlassIconPayload? payload]) {
    return <String, Object?>{'id': id, 'spacer': true, 'flexible': flexible, if (!flexible && width != null) 'width': width};
  }
}

/// SF Symbol weight for toolbar icons.
enum LiquidGlassToolbarIconWeight { ultraLight, thin, light, regular, medium, semibold, bold, heavy, black }

/// A native iOS toolbar (UIToolbar) with Liquid Glass effects on iOS 26+.
///
/// On non-iOS platforms, falls back to a [BottomAppBar].
class LiquidGlassToolbar extends StatefulWidget {
  /// Toolbar items.
  final List<LiquidGlassToolbarItem> items;

  /// Called when an item is tapped. Receives the item's [id].
  final ValueChanged<String>? onItemTapped;

  /// Height of the toolbar's glass bar. Defaults to 44.
  ///
  /// On iOS 26+ the bar is rendered as a SwiftUI `HStack` with
  /// `.glassEffect(.regular, in: Capsule())` and actually resizes to this
  /// height — bar-button items stay vertically centered inside it.
  ///
  /// On iOS 15–25 the plugin falls back to `UIToolbar`, which locks its
  /// visible bar to the system-intrinsic 44pt regardless of this value
  /// (extra space becomes transparent padding below the bar).
  final double height;

  /// Optional explicit width for the toolbar.
  ///
  /// * `null` (the default):
  ///   * If [items] contains a flexible `LiquidGlassToolbarSpacer` →
  ///     the toolbar **fills its parent's width** so the spacer can
  ///     actually distribute the capsule groups (the iOS 26 split-
  ///     toolbar pattern). Without this auto-detection a flex spacer
  ///     would silently collapse to 0 and leave the capsules stuck
  ///     together at one edge — almost never what callers want.
  ///   * Otherwise → the toolbar **wraps its content**: width is
  ///     estimated from the items' natural sizes (icon point size,
  ///     text measurement via `TextPainter`, fixed spacer widths, plus
  ///     the per-capsule horizontal `padding`). The widget centers
  ///     itself horizontally in the parent's allocated slot.
  /// * A finite value — the toolbar takes exactly that width; any
  ///   flexible spacers expand into the leftover room.
  /// * `double.infinity` — the toolbar fills its parent's width
  ///   (forces fill-parent even without a flex spacer).
  final double? width;

  /// Optional bottom shadow/separator color.
  ///
  /// Set to transparent to remove the separator line.
  final Color? shadowColor;

  /// Default SF Symbol weight for all toolbar items.
  ///
  /// Individual items can override icon weight via [LiquidGlassToolbarItem.iconSize].
  /// Defaults to [LiquidGlassToolbarIconWeight.regular].
  final LiquidGlassToolbarIconWeight iconWeight;

  /// Optional text style for text-only toolbar items.
  ///
  /// Supported properties: [TextStyle.fontSize], [TextStyle.fontWeight],
  /// [TextStyle.fontFamily], and [TextStyle.letterSpacing].
  final TextStyle? labelTextStyle;

  /// Horizontal gap between adjacent items, in points. Defaults to 8.
  ///
  /// Implemented as `itemSpacing / 2` of horizontal padding per item, so:
  /// * `0` — items touch each other (capsule wraps tightly).
  /// * `8` (default) — 8pt gap between items, 4pt inset from each end of
  ///   the capsule.
  /// * `16` — 16pt gap, 8pt inset.
  ///
  /// Must be `>= 0`.
  final double itemSpacing;

  /// Optional stroked border drawn on top of each glass capsule,
  /// following the capsule shape. Applies to every pill in a split
  /// toolbar identically.
  final LiquidGlassBorder? border;

  /// Padding applied **inside each glass capsule**, between the items and
  /// the capsule edge. Defaults to no padding.
  ///
  /// Because the padding lives inside the capsule's shape, it grows the
  /// capsule visually (the pill wraps wider / taller around the items)
  /// rather than pushing it away from the widget's outer edges — i.e.
  /// `padding` is CSS-style padding of the capsule container, not an
  /// outer margin. The toolbar widget still wraps tightly around the
  /// capsule(s) in wrap-content mode.
  ///
  /// Horizontal padding is the most common use (breathing room inside
  /// the pill). Vertical padding shrinks the item content area but the
  /// capsule itself still fills `height`, so items are centered within
  /// the remaining space.
  ///
  /// Pass an `EdgeInsetsDirectional` (or wrap in a `Directionality`) for
  /// RTL-aware insets.
  final EdgeInsetsGeometry padding;

  const LiquidGlassToolbar({
    super.key,
    required this.items,
    this.onItemTapped,
    this.height = 44,
    this.width,
    this.shadowColor,
    this.iconWeight = LiquidGlassToolbarIconWeight.regular,
    this.labelTextStyle,
    this.itemSpacing = 8,
    this.padding = EdgeInsets.zero,
    this.border,
  }) : assert(itemSpacing >= 0, 'itemSpacing must be >= 0.');

  @override
  State<LiquidGlassToolbar> createState() => _LiquidGlassToolbarState();
}

class _LiquidGlassToolbarState extends State<LiquidGlassToolbar> with LiquidGlassRouteSuppression {
  MethodChannel? _nativeChannel;
  @override MethodChannel? get suppressionChannel => _nativeChannel;
  int? _lastConfigHash;
  List<NativeLiquidGlassIconPayload>? _itemPayloads;
  int _nativePayloadRequestId = 0;
  int _itemsSignature = 0;
  int _payloadsGeneration = 0;
  int? _estimateCacheKey;
  double? _cachedEstimate;
  Map<String, Object?>? _cachedCreationParams;
  int? _creationParamsCacheKey;

  @override
  void initState() {
    super.initState();
    _itemsSignature = _computeItemsSignature();
    _prepareIconPayloads();
  }

  @override
  void reassemble() {
    super.reassemble();
    clearNativeLiquidGlassIconCaches();
    _estimateCacheKey = null;
    _cachedEstimate = null;
    _cachedCreationParams = null;
    _creationParamsCacheKey = null;
    _lastConfigHash = null;
    _prepareIconPayloads();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newSignature = _computeItemsSignature();
    if (newSignature != _itemsSignature) {
      _itemsSignature = newSignature;
      _prepareIconPayloads();
    } else {
      _syncPropsToNativeIfNeeded();
    }
  }

  int _computeItemsSignature() {
    return Object.hashAll(widget.items.map((i) => Object.hash(i.id, i.icon?.nativeSignature)));
  }

  Future<void> _prepareIconPayloads() async {
    final requestId = ++_nativePayloadRequestId;
    final payloads = await Future.wait(widget.items.map((item) => resolveIconPayload(item.icon)));
    if (!mounted || requestId != _nativePayloadRequestId) return;
    setState(() {
      _itemPayloads = payloads;
      // Bump the generation so `_computeConfigHash` and the cached
      // params key both invalidate automatically — no need to null
      // `_lastConfigHash` manually.
      _payloadsGeneration++;
    });
    _syncPropsToNativeIfNeeded();
  }

  int _computeConfigHash() {
    return Object.hashAll([
      widget.items.length,
      Object.hashAll(widget.items.map((i) => Object.hash(i.id, i.enabled, i.icon?.nativeSignature, i.label, i.tintColor?.toARGB32(), i.iconSize))),
      widget.shadowColor?.toARGB32(),
      widget.iconWeight,
      textStyleSignature(widget.labelTextStyle),
      widget.itemSpacing,
      widget.padding,
      widget.border?.signature,
      _payloadsGeneration,
    ]);
  }

  int _computeSyncHash(EdgeInsets padding) {
    // Resolved `EdgeInsets` carries the text-direction component of the
    // geometry, so including it in the key handles RTL flips too.
    return Object.hash(_computeConfigHash(), padding);
  }

  Map<String, Object?> _creationParamsCached(EdgeInsets padding) {
    final key = _computeSyncHash(padding);
    final cached = _cachedCreationParams;
    if (_creationParamsCacheKey == key && cached != null) {
      return cached;
    }
    final params = _buildCreationParams(padding);
    _creationParamsCacheKey = key;
    _cachedCreationParams = params;
    return params;
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    final textDirection = mounted
        ? (Directionality.maybeOf(context) ?? TextDirection.ltr)
        : TextDirection.ltr;
    final padding = widget.padding.resolve(textDirection);
    final hash = _computeSyncHash(padding);
    if (_lastConfigHash != hash) {
      await ch.invokeMethod('updateToolbar', _creationParamsCached(padding));
      _lastConfigHash = hash;
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
    final channel = MethodChannel('liquid-glass-toolbar-view/$viewId');
    channel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeChannel = channel;
    // Native just received the cached creationParams, so seed
    // `_lastConfigHash` to skip a redundant `updateToolbar` round-trip
    // on the common case. If props drifted between build and this
    // callback (e.g. a late payload resolved) the hash will differ and
    // `_syncPropsToNativeIfNeeded` still pushes the delta.
    _lastConfigHash = _creationParamsCacheKey;
    _syncPropsToNativeIfNeeded();
    syncGlassRouteVisibility();
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  Map<String, Object?> _buildCreationParams([EdgeInsets? resolvedPadding]) {
    final payloads = _itemPayloads;
    final padding = resolvedPadding ?? EdgeInsets.zero;
    return <String, Object?>{
      'items': [for (var i = 0; i < widget.items.length; i++) widget.items[i].toMap(payloads != null && i < payloads.length ? payloads[i] : null)],
      if (widget.shadowColor != null) 'shadowColor': widget.shadowColor!.toARGB32(),
      'iconWeight': widget.iconWeight.name,
      'labelStyle': textStylePayload(widget.labelTextStyle),
      'itemSpacing': widget.itemSpacing,
      'paddingTop': padding.top,
      'paddingBottom': padding.bottom,
      'paddingLeft': padding.left,
      'paddingRight': padding.right,
      if (widget.border != null) ...widget.border!.toMap(),
    };
  }

  /// Estimates the toolbar's intrinsic width in wrap-content mode.
  ///
  /// Sums per-item natural widths (icon size, `TextPainter`-measured
  /// label widths) plus `itemSpacing` per item (mirroring
  /// `.padding(.horizontal, itemSpacing / 2)` on each item button),
  /// plus `padding.horizontal` per capsule *group* (since the padding
  /// is applied inside each group's glass capsule), plus the width of
  /// each fixed spacer between groups. Flexible spacers contribute `0`
  /// here — there's no leftover room to distribute when the toolbar
  /// hugs its content (and `width: null` + flex spacer auto-promotes
  /// to fill-parent anyway, so the estimator isn't used in that case).
  double _estimateToolbarWidth(BuildContext context, EdgeInsets resolvedPadding) {
    final labelTextDirection =
        Directionality.maybeOf(context) ?? TextDirection.ltr;
    final cacheKey = Object.hashAll([
      textStyleSignature(widget.labelTextStyle),
      widget.itemSpacing,
      resolvedPadding.horizontal,
      labelTextDirection,
      for (final item in widget.items)
        if (item is LiquidGlassToolbarSpacer)
          Object.hash('spacer', item.flexible, item.width)
        else
          Object.hash(item.id, item.label, item.icon != null, item.iconSize),
    ]);
    final cached = _cachedEstimate;
    if (_estimateCacheKey == cacheKey && cached != null) {
      return cached;
    }

    double total = 0;

    final labelFontSize = widget.labelTextStyle?.fontSize ?? 17;
    final labelFontWeight = widget.labelTextStyle?.fontWeight ?? FontWeight.w400;

    bool groupOpen = false;
    int groupCount = 0;

    void closeGroup() {
      if (groupOpen) {
        groupCount++;
        groupOpen = false;
      }
    }

    for (final item in widget.items) {
      if (item is LiquidGlassToolbarSpacer) {
        // Both flexible and fixed spacers close the current capsule
        // group (each runs as its own glass pill).
        closeGroup();
        if (item.flexible) {
          // Flex spacers contribute 0 in wrap-content (caller can't
          // really get split-toolbar in wrap-content; the auto-promote
          // path takes over for that case).
          continue;
        }
        total += item.width ?? 16;
        continue;
      }

      // Button item: SwiftUI renders `itemContent`.padding(.horizontal,
      // itemSpacing / 2), so each item contributes `content + itemSpacing`.
      double contentWidth = 0;
      final iconSize = item.iconSize ?? 20;
      final hasIcon = item.icon != null;
      final hasLabel = (item.label?.isNotEmpty ?? false);
      if (hasIcon) contentWidth += iconSize;
      if (hasLabel) {
        final painter = TextPainter(
          text: TextSpan(
            text: item.label,
            style: TextStyle(fontSize: labelFontSize, fontWeight: labelFontWeight),
          ),
          maxLines: 1,
          textDirection: labelTextDirection,
        )..layout();
        contentWidth += painter.width;
      }
      total += contentWidth + widget.itemSpacing;
      groupOpen = true;
    }

    closeGroup();

    // Each capsule group adds its own horizontal padding inside its
    // glass shape.
    total += groupCount * resolvedPadding.horizontal;

    final result = total.ceilToDouble();
    _estimateCacheKey = cacheKey;
    _cachedEstimate = result;
    return result;
  }

  /// Whether the items list contains a flexible `LiquidGlassToolbarSpacer`.
  ///
  /// When true and `widget.width` is null we promote the toolbar to
  /// fill-parent mode so the flex spacer has room to distribute the
  /// capsule groups (the iOS 26 split-toolbar pattern). Wrap-content
  /// would silently collapse the spacer to 0 and leave the capsules
  /// stuck together at one edge, which is rarely what a caller using a
  /// flex spacer actually wants.
  bool get _hasFlexibleSpacer => widget.items.any(
        (item) => item is LiquidGlassToolbarSpacer && item.flexible,
      );

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      // `widget.height` maps 1:1 to the visible glass bar height — no
      // implicit outer margin. `widget.padding` is applied *inside*
      // each capsule on the iOS side (grows each glass pill), so it
      // shows up in the width estimate but doesn't affect the outer
      // widget's height or add any extra margin.
      //
      // Width resolution:
      //   * `widget.width` set                      → use it verbatim
      //   * `widget.width` null + has flex spacer   → fill parent (so the
      //                                                 spacer can
      //                                                 distribute)
      //   * `widget.width` null + no flex spacer    → wrap content
      //                                                 (estimate)
      final textDirection =
          Directionality.maybeOf(context) ?? TextDirection.ltr;
      final padding = widget.padding.resolve(textDirection);
      final fillParent =
          widget.width == null ? _hasFlexibleSpacer : !widget.width!.isFinite;
      final resolvedWidth = widget.width ??
          (_hasFlexibleSpacer
              ? double.infinity
              : _estimateToolbarWidth(context, padding));

      Widget result = SizedBox(
        width: resolvedWidth,
        height: widget.height,
        child: UiKitView(
          viewType: 'liquid-glass-toolbar-view',
          creationParams: _creationParamsCached(padding),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: _toolbarGestureRecognizers,
        ),
      );
      // Wrap-content mode needs to shrink below a tight-horizontal
      // parent's constraint (e.g. inside `Column(crossAxisAlignment:
      // .stretch)` or a `Padding` inside one). `UnconstrainedBox`
      // releases the horizontal constraint so the widget can actually
      // be its estimated content width; vertical stays constrained so
      // the supplied `height` is honored. Centered alignment matches
      // Apple's iOS 26 floating-toolbar visual (toolbars sit centered,
      // not leading-aligned).
      if (widget.width == null && !fillParent) {
        result = UnconstrainedBox(
          constrainedAxis: Axis.vertical,
          alignment: Alignment.center,
          child: result,
        );
      }
      return result;
    }

    return const SizedBox();
  }
}
