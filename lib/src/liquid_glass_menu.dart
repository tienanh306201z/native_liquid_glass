import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shares/liquid_glass_icon.dart';
import 'utils/native_liquid_glass_utils.dart';
import 'utils/text_style_utils.dart';

/// A single menu item for [LiquidGlassMenu].
class LiquidGlassMenuItem {
  /// Unique identifier for this item.
  final String id;

  /// Display title.
  final String title;

  /// Optional icon.
  final NativeLiquidGlassIcon? icon;

  /// Whether this is a destructive action (shown in red).
  final bool isDestructive;

  /// Whether this item is disabled.
  final bool isDisabled;

  /// Nested submenu items.
  final List<LiquidGlassMenuItem>? children;

  const LiquidGlassMenuItem({required this.id, required this.title, this.icon, this.isDestructive = false, this.isDisabled = false, this.children});

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'title': title,
      'sfSymbol': icon?.sfSymbolName,
      'isDestructive': isDestructive,
      'isDisabled': isDisabled,
      'children': children?.map((c) => c.toMap()).toList(),
    };
  }
}

/// A native iOS context menu using UIButton + UIMenu with Liquid Glass effects
/// on iOS 26+.
///
/// Renders an inline button that shows a native UIMenu on long-press or tap.
/// On non-iOS platforms, falls back to [PopupMenuButton].
class LiquidGlassMenu extends StatefulWidget {
  /// Menu items.
  final List<LiquidGlassMenuItem> items;

  /// Called when a menu item is selected. Receives the item's [id].
  final ValueChanged<String> onItemSelected;

  /// Button label text. If null, uses [sfSymbol] or a default icon.
  final String? label;

  /// Icon for the menu trigger button.
  final NativeLiquidGlassIcon? icon;

  /// Optional tint color.
  final Color? color;

  /// Optional icon size for the trigger button icon.
  final double? iconSize;

  /// Optional text style for the trigger button label.
  ///
  /// Supported properties: [TextStyle.fontSize], [TextStyle.fontWeight],
  /// [TextStyle.fontFamily], and [TextStyle.letterSpacing].
  final TextStyle? labelTextStyle;

  /// Menu title shown above items on iOS.
  final String? menuTitle;

  /// Height of the trigger button. Defaults to 44.
  final double height;

  /// Named constructor for icon-only menu triggers.
  const LiquidGlassMenu.icon({
    super.key,
    required this.items,
    required this.onItemSelected,
    required NativeLiquidGlassIcon this.icon,
    this.color,
    this.iconSize,
    this.menuTitle,
    this.height = 44,
  }) : label = null,
       labelTextStyle = null;

  const LiquidGlassMenu({
    super.key,
    required this.items,
    required this.onItemSelected,
    this.label,
    this.icon,
    this.color,
    this.iconSize,
    this.labelTextStyle,
    this.menuTitle,
    this.height = 44,
  });

  @override
  State<LiquidGlassMenu> createState() => _LiquidGlassMenuState();
}

class _LiquidGlassMenuState extends State<LiquidGlassMenu> {
  MethodChannel? _nativeChannel;
  int? _lastItemsHash;
  int? _lastColor;
  double? _nativeWidth;

  @override
  void didUpdateWidget(covariant LiquidGlassMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPropsToNativeIfNeeded();
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    final itemsHash = Object.hashAll(widget.items.map((i) => i.id));
    final color = widget.color?.toARGB32();
    if (_lastItemsHash != itemsHash || _lastColor != color) {
      await ch.invokeMethod('updateMenu', _buildCreationParams());
      _lastItemsHash = itemsHash;
      _lastColor = color;
    }
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'itemSelected') {
      final id = call.arguments as String;
      widget.onItemSelected(id);
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-menu-view/$viewId');
    channel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeChannel = channel;
    _lastItemsHash = Object.hashAll(widget.items.map((i) => i.id));
    _lastColor = widget.color?.toARGB32();
    _requestIntrinsicSize();
  }

  Future<void> _requestIntrinsicSize() async {
    final ch = _nativeChannel;
    if (ch == null) return;
    try {
      final result = await ch.invokeMethod<Map>('getIntrinsicSize');
      if (result != null && mounted) {
        final w = (result['width'] as num?)?.toDouble();
        if (w != null && w > 0 && w != _nativeWidth) {
          setState(() => _nativeWidth = w + 16);
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  Map<String, Object?> _buildCreationParams() {
    return <String, Object?>{
      'items': widget.items.map((i) => i.toMap()).toList(),
      'label': widget.label,
      'sfSymbol': widget.icon?.sfSymbolName,
      'color': widget.color?.toARGB32(),
      'iconSize': widget.iconSize,
      'labelStyle': textStylePayload(widget.labelTextStyle),
      'menuTitle': widget.menuTitle,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      final isIconOnly = widget.label == null;
      final width = isIconOnly ? widget.height : (_nativeWidth ?? _estimateWidth());
      return SizedBox(
        width: width,
        height: widget.height,
        child: UiKitView(
          viewType: 'liquid-glass-menu-view',
          creationParams: _buildCreationParams(),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    }

    return const SizedBox();
  }

  double _estimateWidth() {
    final label = widget.label ?? '';
    final fontSize = widget.labelTextStyle?.fontSize ?? 16.0;
    final textWidth = label.length * fontSize * 0.55;
    final iconWidth = widget.icon != null ? (widget.iconSize ?? 20) + 8 : 0;
    return textWidth + iconWidth + 32;
  }
}
