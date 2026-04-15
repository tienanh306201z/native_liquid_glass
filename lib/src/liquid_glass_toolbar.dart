import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shares/liquid_glass_icon.dart';
import 'utils/native_liquid_glass_utils.dart';
import 'utils/text_style_utils.dart';

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

/// A special item that represents flexible or fixed space in the toolbar.
class LiquidGlassToolbarSpacer extends LiquidGlassToolbarItem {
  /// If true, takes up flexible space. If false, fixed space.
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
  /// * `null` (the default) — the toolbar **wraps its content**: width is
  ///   estimated from the items' natural sizes (icon point size, text
  ///   measurement via `TextPainter`, fixed spacer widths, plus the
  ///   glass overflow padding). This matches Flutter button semantics.
  /// * A finite value — the toolbar takes exactly that width; flexible
  ///   `LiquidGlassToolbarSpacer`s expand into the leftover room.
  /// * `double.infinity` — the toolbar fills its parent's width.
  ///
  /// Note: flexible spacers only produce a visible gap when this is
  /// explicit. In wrap-content mode, a flexible spacer collapses to 0
  /// because there's no extra space to distribute.
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
  }) : assert(itemSpacing >= 0, 'itemSpacing must be >= 0.');

  @override
  State<LiquidGlassToolbar> createState() => _LiquidGlassToolbarState();
}

class _LiquidGlassToolbarState extends State<LiquidGlassToolbar> {
  MethodChannel? _nativeChannel;
  int? _lastConfigHash;
  List<NativeLiquidGlassIconPayload>? _itemPayloads;
  int _nativePayloadRequestId = 0;
  int _itemsSignature = 0;

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
      _lastConfigHash = null; // force sync on next call
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
    ]);
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    final hash = _computeConfigHash();
    if (_lastConfigHash != hash) {
      final textDirection = mounted
          ? (Directionality.maybeOf(context) ?? TextDirection.ltr)
          : TextDirection.ltr;
      final padding = widget.padding.resolve(textDirection);
      await ch.invokeMethod('updateToolbar', _buildCreationParams(padding));
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
    // Always sync current state — creation params may have been built before
    // icon payloads resolved, leaving native with missing icons.
    _syncPropsToNativeIfNeeded();
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
    };
  }

  /// Estimates the toolbar's intrinsic width in wrap-content mode.
  ///
  /// Sums per-item natural widths (icon size, `TextPainter`-measured
  /// label widths, fixed spacer widths) plus `itemSpacing` per item
  /// (mirroring `.padding(.horizontal, itemSpacing / 2)` on each item
  /// button), plus `padding.horizontal` per capsule *group* (since the
  /// padding is applied inside each group's glass capsule). Flexible
  /// spacers contribute `0` — there's no leftover room to distribute
  /// when the toolbar hugs its content.
  double _estimateToolbarWidth(BuildContext context, EdgeInsets resolvedPadding) {
    double total = 0;

    final labelFontSize = widget.labelTextStyle?.fontSize ?? 17;
    final labelFontWeight = widget.labelTextStyle?.fontWeight ?? FontWeight.w400;
    final labelTextDirection =
        Directionality.maybeOf(context) ?? TextDirection.ltr;

    bool groupOpen = false;
    int groupCount = 0;

    for (final item in widget.items) {
      if (item is LiquidGlassToolbarSpacer) {
        if (item.flexible) {
          // A flexible spacer closes the current capsule group and
          // collapses to 0 width in wrap-content mode.
          if (groupOpen) {
            groupCount++;
            groupOpen = false;
          }
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

    if (groupOpen) groupCount++;

    // Each capsule group adds its own horizontal padding inside its
    // glass shape.
    total += groupCount * resolvedPadding.horizontal;

    return total.ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      // `widget.height` maps 1:1 to the visible glass bar height — no
      // implicit outer margin. `widget.width` (when null) wraps content
      // via a Flutter-side estimate; explicit values are respected,
      // including `double.infinity` for "fill parent". `widget.padding`
      // is applied *inside* each capsule on the iOS side (grows each
      // glass pill), so it shows up in the width estimate but doesn't
      // affect the outer widget's height or add any extra margin.
      final textDirection =
          Directionality.maybeOf(context) ?? TextDirection.ltr;
      final padding = widget.padding.resolve(textDirection);
      final resolvedWidth =
          widget.width ?? _estimateToolbarWidth(context, padding);
      return SizedBox(
        width: resolvedWidth,
        height: widget.height,
        child: UiKitView(
          viewType: 'liquid-glass-toolbar-view',
          creationParams: _buildCreationParams(padding),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    }

    return const SizedBox();
  }
}
