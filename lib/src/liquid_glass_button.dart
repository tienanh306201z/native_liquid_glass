import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shares/liquid_glass_icon.dart';
import 'utils/native_liquid_glass_utils.dart';
import 'utils/text_style_utils.dart';

/// Image placement options for buttons with both image and label.
enum LiquidGlassImagePlacement {
  /// Image placed before the text (default).
  leading,

  /// Image placed after the text.
  trailing,

  /// Image placed above the text.
  top,

  /// Image placed below the text.
  bottom,
}

/// Visual style for [LiquidGlassButton].
///
/// Mirrors the `UIButton.Configuration` styles available on iOS 15+.
/// On iOS 26+, [glass] and [prominentGlass] use the native Liquid Glass effect.
enum LiquidGlassButtonStyle {
  /// Automatic style chosen by the system.
  automatic,

  /// Minimal, label-only appearance with no background shape.
  plain,

  /// Gray tinted background.
  gray,

  /// Tinted background using the button's tint color.
  tinted,

  /// Bordered style with a subtle stroke border.
  bordered,

  /// Prominent bordered style with a filled tint background.
  borderedProminent,

  /// Filled background using the button's tint color.
  filled,

  /// Liquid Glass background (iOS 26+). Falls back to [tinted] on older OS.
  glass,

  /// Prominent Liquid Glass background (iOS 26+). Falls back to
  /// [borderedProminent] on older OS.
  prominentGlass,
}

/// A native-styled Liquid Glass button for iOS.
///
/// On iOS, this widget renders a native `UIButton` through `UiKitView`.
/// On iOS 26+, the native side uses `UIButton.Configuration.prominentGlass()`
/// with interactive glass effects.
/// On non-iOS platforms, it falls back to Flutter `FilledButton` or
/// `IconButton.filled` depending on mode.
///
/// Use the default constructor for text buttons with an optional icon, and
/// [LiquidGlassButton.icon] for icon-only buttons.
class LiquidGlassButton extends StatefulWidget {
  /// Button title text. Null in icon-only mode.
  final String? label;

  /// Called when the button is pressed.
  ///
  /// If null, the button is disabled.
  final VoidCallback? onPressed;

  /// Optional icon displayed in the button.
  ///
  /// On iOS, the icon is sent to the native platform view. SF Symbols are
  /// rendered natively; [IconData] and asset icons are rasterized to PNG.
  /// On non-iOS platforms it falls back to a Flutter widget.
  final NativeLiquidGlassIcon? icon;

  /// Optional fixed width. Only used in text button mode.
  ///
  /// When null, width wraps content size.
  final double? width;

  /// Optional fixed button height. Only used in text button mode.
  ///
  /// When null, height wraps content size.
  final double? height;

  /// Square size for icon-only mode. Only used with [LiquidGlassButton.icon].
  final double? size;

  /// Icon size used by native and fallback rendering.
  final double iconSize;

  /// Optional foreground color used for native title/icon and fallback label.
  final Color? foregroundColor;

  /// Optional icon color override.
  ///
  /// When provided, icon rendering uses this color instead of
  /// [foregroundColor].
  final Color? iconColor;

  /// Optional tint color for native iOS glass effect.
  final Color? tint;

  /// Spacing between icon and label.
  final double imagePadding;

  /// Whether native iOS glass effect should be interactive.
  final bool interactive;

  /// Optional ID for glass effect union.
  ///
  /// When multiple buttons share the same [glassEffectUnionId], they will
  /// be combined into a single unified Liquid Glass effect.
  /// Only applies on iOS 26+.
  final String? glassEffectUnionId;

  /// Optional ID for glass effect morphing transitions.
  ///
  /// When a button with a [glassEffectId] appears or disappears, it will
  /// morph into/out of other buttons with the same ID.
  /// Only applies on iOS 26+.
  final String? glassEffectId;

  /// Optional text style for the button label.
  ///
  /// Supported properties: [TextStyle.fontSize], [TextStyle.fontWeight],
  /// [TextStyle.fontFamily], and [TextStyle.letterSpacing].
  /// Only used in text-button mode (not icon-only).
  final TextStyle? labelTextStyle;

  /// Image placement relative to the label text.
  final LiquidGlassImagePlacement imagePlacement;

  /// Optional badge value displayed on the button.
  ///
  /// When non-null and non-empty, a badge with text is displayed at the
  /// top-right corner. Accepts any text (e.g. "3", "99+", "NEW").
  /// For a dot badge without text, leave this null and set [showBadge] to true.
  final String? badgeValue;

  /// Whether to show a badge indicator on the button.
  ///
  /// When true without [badgeValue], shows a small dot badge (notification
  /// indicator). When [badgeValue] is set, this defaults to true automatically.
  final bool showBadge;

  /// Badge background color.
  ///
  /// Defaults to red when null.
  final Color? badgeColor;

  /// Badge text color when [badgeValue] is set.
  ///
  /// Defaults to white when null.
  final Color? badgeTextColor;

  /// Badge size.
  ///
  /// For text badges, this controls the font size (default 12).
  /// For dot badges, this controls the dot diameter (default 10).
  final double? badgeSize;

  /// Optional semantic tooltip for fallback platforms. Only used in icon-only
  /// mode.
  final String? tooltip;

  /// Visual style for the button.
  ///
  /// Defaults to [LiquidGlassButtonStyle.prominentGlass] for text buttons and
  /// [LiquidGlassButtonStyle.glass] for icon-only buttons.
  final LiquidGlassButtonStyle style;

  /// Optional custom corner radius.
  ///
  /// When null, the button uses a fully rounded capsule shape.
  final double? borderRadius;

  /// Optional custom content padding.
  ///
  /// When null, the native default padding is used.
  final EdgeInsets? padding;

  /// Whether the button responds to user interaction without changing appearance.
  ///
  /// When false, touch events are blocked but the button keeps its normal
  /// visual state (no dimming). To also dim/disable visually, set
  /// [onPressed] to null or use [enabled].
  ///
  /// Defaults to true.
  final bool interaction;

  /// Explicit label text color.
  ///
  /// When provided, overrides any color derived from [foregroundColor] or the
  /// system tint on the text.
  final Color? labelColor;

  /// If true, the button shrinks to its intrinsic content width.
  ///
  /// Useful when placing the button inside a [Row] or other non-bounded layout.
  final bool shrinkWrap;

  /// Maximum number of lines for the label text.
  ///
  /// Defaults to 1. Set to null for unlimited lines.
  final int? maxLines;

  /// Whether this button is in icon-only mode.
  final bool _iconOnly;

  /// Creates a native Liquid Glass text button with an optional icon.
  const LiquidGlassButton({
    super.key,
    required String this.label,
    required this.onPressed,
    this.icon,
    this.width,
    this.height,
    this.iconSize = 18,
    this.foregroundColor,
    this.iconColor,
    this.tint,
    this.imagePadding = 8,
    this.interactive = true,
    this.glassEffectUnionId,
    this.glassEffectId,
    this.imagePlacement = LiquidGlassImagePlacement.leading,
    this.badgeValue,
    this.showBadge = false,
    this.badgeColor,
    this.badgeTextColor,
    this.badgeSize,
    this.labelTextStyle,
    this.style = LiquidGlassButtonStyle.prominentGlass,
    this.borderRadius,
    this.padding,
    this.interaction = true,
    this.labelColor,
    this.shrinkWrap = false,
    this.maxLines = 1,
  }) : _iconOnly = false,
       size = null,
       tooltip = null,
       assert(width == null || width > 0, 'width must be > 0 when provided.'),
       assert(height == null || height > 0, 'height must be > 0 when provided.'),
       assert(iconSize > 0, 'iconSize must be > 0.'),
       assert(imagePadding >= 0, 'imagePadding must be >= 0.');

  /// Creates a native Liquid Glass icon-only button.
  const LiquidGlassButton.icon({
    super.key,
    required this.onPressed,
    required NativeLiquidGlassIcon this.icon,
    this.size = 50,
    this.iconSize = 20,
    this.tooltip,
    this.iconColor,
    this.tint,
    this.interactive = true,
    this.glassEffectUnionId,
    this.glassEffectId,
    this.style = LiquidGlassButtonStyle.glass,
    this.borderRadius,
    this.padding,
    this.interaction = true,
    this.badgeValue,
    this.showBadge = false,
    this.badgeColor,
    this.badgeTextColor,
    this.badgeSize,
  }) : _iconOnly = true,
       label = null,
       foregroundColor = null,
       labelColor = null,
       width = null,
       height = null,
       imagePadding = 0,
       imagePlacement = LiquidGlassImagePlacement.leading,
       labelTextStyle = null,
       shrinkWrap = false,
       maxLines = null,
       assert(size == null || size > 0, 'size must be > 0.'),
       assert(iconSize > 0, 'iconSize must be > 0.');

  @override
  State<LiquidGlassButton> createState() => _LiquidGlassButtonState();
}

class _LiquidGlassButtonState extends State<LiquidGlassButton> {
  MethodChannel? _nativeChannel;
  NativeLiquidGlassIconPayload? _iconPayload;
  int _nativePayloadRequestId = 0;
  bool _nativeIconPayloadResolved = false;
  int _iconSignature = 0;
  double? _nativeWidth;
  double? _nativeHeight;
  int? _lastConfigHash;

  @override
  void initState() {
    super.initState();
    _iconSignature = widget.icon?.nativeSignature ?? 0;
    _prepareNativeIconPayloads();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newSignature = widget.icon?.nativeSignature ?? 0;
    if (newSignature != _iconSignature) {
      _iconSignature = newSignature;
      _prepareNativeIconPayloads();
    }
    _syncPropsToNativeIfNeeded();
  }

  @override
  void reassemble() {
    super.reassemble();
    clearNativeLiquidGlassIconCaches();
    _prepareNativeIconPayloads();

    if (mounted) {
      setState(() {
        _nativeWidth = null;
        _nativeHeight = null;
        _lastConfigHash = null;
      });
      _syncPropsToNativeIfNeeded();
    }
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'onPressed') {
      widget.onPressed?.call();
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-button-view/$viewId');
    channel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeChannel = channel;
    // Reset hash so any stale value set against the previously-destroyed native
    // view (e.g. from _prepareNativeIconPayloads calling sync on an old channel)
    // cannot prevent this fresh view from receiving its first full sync.
    _lastConfigHash = null;
    _syncPropsToNativeIfNeeded();
    if (!widget._iconOnly) {
      Future.delayed(const Duration(milliseconds: 10), _requestIntrinsicSize);
    }
  }

  int _computeConfigHash() {
    return Object.hashAll([
      widget._iconOnly,
      widget.label,
      widget.icon?.nativeSignature,
      _iconPayload?.iconDataPng,
      _iconPayload?.assetIconPng,
      widget.width,
      widget.height,
      widget.size,
      widget.iconSize,
      widget.onPressed != null,
      widget.foregroundColor?.toARGB32(),
      widget.iconColor?.toARGB32(),
      widget.tint?.toARGB32(),
      widget.imagePadding,
      widget.interactive,
      widget.glassEffectUnionId,
      widget.glassEffectId,
      widget.imagePlacement,
      widget.badgeValue,
      widget.showBadge,
      widget.badgeColor?.toARGB32(),
      widget.badgeTextColor?.toARGB32(),
      widget.badgeSize,
      textStyleSignature(widget.labelTextStyle),
      widget.style,
      widget.borderRadius,
      widget.padding,
      widget.interaction,
      widget.labelColor?.toARGB32(),
      widget.maxLines,
    ]);
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    final hash = _computeConfigHash();
    if (_lastConfigHash != hash) {
      await ch.invokeMethod('updateConfig', _buildNativeCreationParams(resolvedSize: _resolveNativeSize(context)));
      _lastConfigHash = hash;
      if (!widget._iconOnly) {
        _requestIntrinsicSize();
      }
    }
  }

  @override
  void dispose() {
    _nativePayloadRequestId++;
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  bool get _needsNativeIconPayload {
    final icon = widget.icon;
    return icon != null && !icon.isSfSymbol;
  }

  Future<void> _prepareNativeIconPayloads() async {
    final requestId = ++_nativePayloadRequestId;

    if (mounted) {
      if (_needsNativeIconPayload) {
        setState(() {
          _nativeIconPayloadResolved = false;
          _iconPayload = null;
        });
      } else {
        // Switching to SF Symbol — clear any stale payload so the native
        // side doesn't see leftover PNG bytes that would take priority.
        if (_iconPayload != null) {
          setState(() {
            _iconPayload = null;
            _nativeIconPayloadResolved = true;
          });
          _syncPropsToNativeIfNeeded();
        }
        return;
      }
    }

    final payload = await resolveIconPayload(widget.icon);

    if (!mounted || requestId != _nativePayloadRequestId) {
      return;
    }

    setState(() {
      _iconPayload = payload;
      _nativeIconPayloadResolved = true;
    });
    _syncPropsToNativeIfNeeded();
  }

  Future<void> _requestIntrinsicSize() async {
    final ch = _nativeChannel;
    if (ch == null || !mounted) return;
    try {
      final size = await ch.invokeMethod<Map<Object?, Object?>>('getIntrinsicSize');
      final w = (size?['width'] as num?)?.toDouble();
      final h = (size?['height'] as num?)?.toDouble();
      if (mounted && (w != null || h != null)) {
        setState(() {
          if (w != null) _nativeWidth = w;
          if (h != null) _nativeHeight = h;
        });
      }
    } catch (_) {}
  }

  // — Text button size helpers —

  Size _estimateWrapContentSize(BuildContext context) {
    const textStyle = TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.0);

    final textPainter = TextPainter(
      textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
      maxLines: 1,
      text: TextSpan(text: widget.label, style: textStyle),
    )..layout();

    final hasIcon = widget.icon != null;

    const horizontalInsets = 32.0;
    const verticalInsets = 20.0;

    final iconContribution = hasIcon ? widget.iconSize + widget.imagePadding : 0.0;

    final estimatedWidth = math.max(44.0, (horizontalInsets + textPainter.width + iconContribution).ceilToDouble());
    final estimatedHeight = math.max(32.0, (verticalInsets + textPainter.height).ceilToDouble());

    return Size(estimatedWidth, estimatedHeight);
  }

  Size _resolveNativeSize(BuildContext context) {
    if (widget.width != null && widget.height != null) {
      return Size(widget.width!, widget.height!);
    }
    final estimatedSize = _estimateWrapContentSize(context);
    return Size(widget.width ?? estimatedSize.width, widget.height ?? estimatedSize.height);
  }

  // — Creation params —

  Map<String, Object?> _buildNativeCreationParams({Size? resolvedSize}) {
    final isIconOnly = widget._iconOnly;
    final iconMap = widget.icon?.toNativeMap(_iconPayload) ?? <String, Object?>{};
    final p = widget.padding;
    return <String, Object?>{
      'title': widget.label,
      ...iconMap,
      'width': isIconOnly ? widget.size : resolvedSize!.width,
      'height': isIconOnly ? widget.size : resolvedSize!.height,
      'enabled': widget.onPressed != null,
      'iconOnly': isIconOnly,
      'iconSize': widget.iconSize,
      'foregroundColor': (isIconOnly ? widget.iconColor : widget.foregroundColor)?.toARGB32(),
      'iconColor': widget.iconColor?.toARGB32(),
      'tint': widget.tint?.toARGB32(),
      'imagePadding': widget.imagePadding,
      'interactive': widget.interactive,
      'glassEffectUnionId': widget.glassEffectUnionId,
      'glassEffectId': widget.glassEffectId,
      'buttonStyle': widget.style.name,
      if (widget.borderRadius != null) 'borderRadius': widget.borderRadius,
      if (p != null) ...{'paddingTop': p.top, 'paddingBottom': p.bottom, 'paddingLeft': p.left, 'paddingRight': p.right},
      'interaction': widget.interaction,
      if (widget.labelColor != null) 'labelColor': widget.labelColor!.toARGB32(),
      if (!isIconOnly) 'imagePlacement': widget.imagePlacement.name,
      'badgeValue': widget.badgeValue,
      'showBadge': widget.showBadge || widget.badgeValue != null,
      if (widget.badgeColor != null) 'badgeColor': widget.badgeColor!.toARGB32(),
      if (widget.badgeTextColor != null) 'badgeTextColor': widget.badgeTextColor!.toARGB32(),
      if (widget.badgeSize != null) 'badgeSize': widget.badgeSize,
      if (!isIconOnly) 'labelStyle': textStylePayload(widget.labelTextStyle),
      if (!isIconOnly && widget.maxLines != null) 'maxLines': widget.maxLines,
    };
  }

  @override
  Widget build(BuildContext context) {
    final nativePayloadReady = !_needsNativeIconPayload || _nativeIconPayloadResolved;
    final isIconOnly = widget._iconOnly;

    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      if (isIconOnly) {
        if (!nativePayloadReady) {
          return SizedBox(width: widget.size, height: widget.size);
        }

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: UiKitView(
            viewType: 'liquid-glass-button-view',
            creationParams: _buildNativeCreationParams(),
            creationParamsCodec: const StandardMessageCodec(),
            onPlatformViewCreated: _onPlatformViewCreated,
          ),
        );
      }

      if (!nativePayloadReady) {
        final fallbackSize = _resolveNativeSize(context);
        return SizedBox(width: fallbackSize.width, height: fallbackSize.height);
      }

      final estimated = _resolveNativeSize(context);
      final nativeSize = Size(widget.width ?? _nativeWidth ?? estimated.width, widget.height ?? _nativeHeight ?? estimated.height);

      return SizedBox(
        width: nativeSize.width,
        height: nativeSize.height,
        child: UiKitView(
          viewType: 'liquid-glass-button-view',
          creationParams: _buildNativeCreationParams(resolvedSize: nativeSize),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    }

    return const SizedBox();
  }
}

/// Deprecated: Use [LiquidGlassButton.icon] instead.
@Deprecated('Use LiquidGlassButton.icon instead.')
class LiquidGlassIconButton extends StatelessWidget {
  /// Called when the icon button is pressed.
  final VoidCallback? onPressed;

  /// Icon displayed in the button.
  final NativeLiquidGlassIcon icon;

  /// Square size of the button.
  final double size;

  /// Icon size used by native and fallback rendering.
  final double iconSize;

  /// Optional semantic tooltip for fallback platforms.
  final String? tooltip;

  /// Optional icon color override.
  final Color? iconColor;

  /// Optional tint color for native iOS glass effect.
  final Color? tint;

  /// Whether native iOS glass effect should be interactive.
  final bool interactive;

  /// Optional ID for glass effect union.
  final String? glassEffectUnionId;

  /// Optional ID for glass effect morphing transitions.
  final String? glassEffectId;

  const LiquidGlassIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.size = 50,
    this.iconSize = 20,
    this.tooltip,
    this.iconColor,
    this.tint,
    this.interactive = true,
    this.glassEffectUnionId,
    this.glassEffectId,
  }) : assert(size > 0, 'size must be > 0.'),
       assert(iconSize > 0, 'iconSize must be > 0.');

  @override
  Widget build(BuildContext context) {
    return LiquidGlassButton.icon(
      onPressed: onPressed,
      icon: icon,
      size: size,
      iconSize: iconSize,
      tooltip: tooltip,
      iconColor: iconColor,
      tint: tint,
      interactive: interactive,
      glassEffectUnionId: glassEffectUnionId,
      glassEffectId: glassEffectId,
    );
  }
}
