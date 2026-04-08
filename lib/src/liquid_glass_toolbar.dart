import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shares/liquid_glass_icon.dart';
import 'utils/native_liquid_glass_utils.dart';
import 'utils/text_style_utils.dart';

/// Style for toolbar bar button items.
enum LiquidGlassToolbarItemStyle {
  /// Standard weight text/icon.
  plain,

  /// Bold weight text (like a "Done" button).
  done,
}

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
  /// When provided, overrides the toolbar-level [LiquidGlassToolbar.tintColor]
  /// for this item only.
  final Color? tintColor;

  /// Item style. [LiquidGlassToolbarItemStyle.done] renders text in bold.
  final LiquidGlassToolbarItemStyle style;

  const LiquidGlassToolbarItem({
    required this.id,
    this.icon,
    this.label,
    this.enabled = true,
    this.iconSize,
    this.tintColor,
    this.style = LiquidGlassToolbarItemStyle.plain,
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
      'style': style.name,
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

  /// Height of the toolbar. Defaults to 44.
  final double height;

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

  const LiquidGlassToolbar({
    super.key,
    required this.items,
    this.onItemTapped,
    this.height = 44,
    this.shadowColor,
    this.iconWeight = LiquidGlassToolbarIconWeight.regular,
    this.labelTextStyle,
  });

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
      Object.hashAll(widget.items.map((i) => Object.hash(i.id, i.enabled, i.icon?.nativeSignature, i.label, i.tintColor?.toARGB32(), i.style, i.iconSize))),
      widget.shadowColor?.toARGB32(),
      widget.iconWeight,
      textStyleSignature(widget.labelTextStyle),
    ]);
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    final hash = _computeConfigHash();
    if (_lastConfigHash != hash) {
      await ch.invokeMethod('updateToolbar', _buildCreationParams());
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

  Map<String, Object?> _buildCreationParams() {
    final payloads = _itemPayloads;
    return <String, Object?>{
      'items': [for (var i = 0; i < widget.items.length; i++) widget.items[i].toMap(payloads != null && i < payloads.length ? payloads[i] : null)],
      if (widget.shadowColor != null) 'shadowColor': widget.shadowColor!.toARGB32(),
      'iconWeight': widget.iconWeight.name,
      'labelStyle': textStylePayload(widget.labelTextStyle),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return SizedBox(
        height: widget.height,
        child: UiKitView(
          viewType: 'liquid-glass-toolbar-view',
          creationParams: _buildCreationParams(),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    }

    return const SizedBox();
  }
}
