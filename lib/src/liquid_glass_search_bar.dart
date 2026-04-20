import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/native_liquid_glass_utils.dart';
import 'utils/liquid_glass_route_suppression.dart';
import 'utils/text_style_utils.dart';

/// Gesture factories for the native search bar's `UiKitView`.
///
/// The search field takes taps (focus, cancel button) and pans inside
/// its text (selection handles on iOS). Claiming both up-front keeps
/// Flutter's gesture arena from swallowing keyboard-focus taps.
final Set<Factory<OneSequenceGestureRecognizer>> _searchBarGestureRecognizers =
    <Factory<OneSequenceGestureRecognizer>>{
  Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
  Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
};

/// Controller for [LiquidGlassSearchBar].
class LiquidGlassSearchBarController extends ChangeNotifier {
  MethodChannel? _channel;
  bool _isExpanded = false;

  /// Whether the search bar is currently expanded.
  bool get isExpanded => _isExpanded;

  /// Expand the search bar.
  Future<void> expand() async {
    _isExpanded = true;
    await _channel?.invokeMethod<void>('expand');
    notifyListeners();
  }

  /// Collapse the search bar.
  Future<void> collapse() async {
    _isExpanded = false;
    await _channel?.invokeMethod<void>('collapse');
    notifyListeners();
  }

  /// Clear the search text.
  Future<void> clear() async {
    await _channel?.invokeMethod<void>('clear');
  }

  /// Set the search text programmatically.
  Future<void> setText(String text) async {
    await _channel?.invokeMethod<void>('setText', {'text': text});
  }

  /// Request focus on the search field.
  Future<void> focus() async {
    await _channel?.invokeMethod<void>('focus');
  }

  /// Remove focus from the search field.
  Future<void> unfocus() async {
    await _channel?.invokeMethod<void>('unfocus');
  }
}

/// An expandable search bar with Liquid Glass effects.
///
/// On iOS 26+, this renders a native search text field with glass effect.
/// On other platforms, it falls back to a Flutter [TextField] with optional
/// glass container wrapping.
class LiquidGlassSearchBar extends StatefulWidget {
  /// Placeholder text shown when the search field is empty.
  final String placeholder;

  /// Called when the search text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits a search.
  final ValueChanged<String>? onSubmitted;

  /// Called when the cancel button is tapped.
  final VoidCallback? onCancelTap;

  /// Called when the expansion state changes.
  final ValueChanged<bool>? onExpandStateChanged;

  /// Whether the search bar can expand from a compact icon.
  final bool expandable;

  /// Whether the search bar starts expanded.
  final bool initiallyExpanded;

  /// Height when expanded.
  final double expandedHeight;

  /// Optional tint color for the glass effect.
  final Color? tint;

  /// Optional color for the typed text.
  final Color? textColor;

  /// Optional color for the placeholder text.
  final Color? placeholderColor;

  /// Optional text style for the search input.
  ///
  /// Supported properties: [TextStyle.fontSize], [TextStyle.fontWeight],
  /// [TextStyle.fontFamily], and [TextStyle.letterSpacing].
  final TextStyle? textStyle;

  /// Whether to show a cancel button when expanded.
  final bool showCancelButton;

  /// Text displayed on the cancel button.
  final String cancelText;

  /// Optional color for the cancel button text.
  ///
  /// When null, uses [tint] or the system accent color.
  final Color? cancelButtonColor;

  /// Optional color for the search icon.
  ///
  /// When null, uses [tint] or the system secondary color.
  final Color? iconColor;

  /// Optional corner radius for the search bar shape.
  ///
  /// When null, uses a fully rounded capsule shape.
  final double? borderRadius;

  /// Whether native iOS glass effect should be interactive.
  final bool interactive;

  /// Optional ID for glass effect union.
  ///
  /// When multiple glass views share the same [glassEffectUnionId], they will
  /// be combined into a single unified Liquid Glass effect.
  /// Only applies on iOS 26+.
  final String? glassEffectUnionId;

  /// Optional ID for glass effect morphing transitions.
  ///
  /// When a glass view with a [glassEffectId] appears or disappears, it will
  /// morph into/out of other views with the same ID.
  /// Only applies on iOS 26+.
  final String? glassEffectId;

  /// Optional controller for programmatic control.
  final LiquidGlassSearchBarController? controller;

  const LiquidGlassSearchBar({
    super.key,
    this.placeholder = 'Search',
    this.onChanged,
    this.onSubmitted,
    this.onCancelTap,
    this.onExpandStateChanged,
    this.expandable = true,
    this.initiallyExpanded = false,
    this.expandedHeight = 44.0,
    this.tint,
    this.textColor,
    this.placeholderColor,
    this.textStyle,
    this.showCancelButton = true,
    this.cancelText = 'Cancel',
    this.cancelButtonColor,
    this.iconColor,
    this.borderRadius,
    this.interactive = true,
    this.glassEffectUnionId,
    this.glassEffectId,
    this.controller,
  });

  @override
  State<LiquidGlassSearchBar> createState() => _LiquidGlassSearchBarState();
}

class _LiquidGlassSearchBarState extends State<LiquidGlassSearchBar> with SingleTickerProviderStateMixin, LiquidGlassRouteSuppression {
  MethodChannel? _nativeChannel;
  @override MethodChannel? get suppressionChannel => _nativeChannel;
  late bool _isExpanded;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late final AnimationController _expandController;
  String? _lastPlaceholder;
  int? _lastTint;
  int? _lastTextColor;
  int? _lastPlaceholderColor;
  int? _lastCancelButtonColor;
  int? _lastIconColor;
  Map<String, Object?>? _cachedCreationParams;
  int? _creationParamsCacheKey;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded || !widget.expandable;

    _expandController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300), value: _isExpanded ? 1.0 : 0.0);
    widget.controller?._isExpanded = _isExpanded;
  }

  @override
  void reassemble() {
    super.reassemble();
    _lastPlaceholder = null;
    _cachedCreationParams = null;
    _creationParamsCacheKey = null;
    _syncPropsToNativeIfNeeded();
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-search-bar-view/$viewId');
    channel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeChannel = channel;
    widget.controller?._channel = channel;
    _lastPlaceholder = widget.placeholder;
    _lastTint = widget.tint?.toARGB32();
    _lastTextColor = widget.textColor?.toARGB32();
    _lastPlaceholderColor = widget.placeholderColor?.toARGB32();
    syncGlassRouteVisibility();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPropsToNativeIfNeeded();
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    if (_lastPlaceholder != widget.placeholder) {
      await ch.invokeMethod('setPlaceholder', {'placeholder': widget.placeholder});
      _lastPlaceholder = widget.placeholder;
    }
    final tint = widget.tint?.toARGB32();
    final textColor = widget.textColor?.toARGB32();
    final placeholderColor = widget.placeholderColor?.toARGB32();
    final cancelButtonColor = widget.cancelButtonColor?.toARGB32();
    final iconColor = widget.iconColor?.toARGB32();
    if (_lastTint != tint || _lastTextColor != textColor || _lastPlaceholderColor != placeholderColor || _lastCancelButtonColor != cancelButtonColor || _lastIconColor != iconColor) {
      await ch.invokeMethod('setStyle', {'tint': tint, 'textColor': textColor, 'placeholderColor': placeholderColor, 'cancelButtonColor': cancelButtonColor, 'iconColor': iconColor});
      _lastTint = tint;
      _lastTextColor = textColor;
      _lastPlaceholderColor = placeholderColor;
      _lastCancelButtonColor = cancelButtonColor;
      _lastIconColor = iconColor;
    }
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onChanged':
        widget.onChanged?.call(call.arguments as String? ?? '');
      case 'onSubmitted':
        widget.onSubmitted?.call(call.arguments as String? ?? '');
      case 'onCancel':
        _collapse();
        widget.onCancelTap?.call();
      case 'onExpandStateChanged':
        final expanded = call.arguments as bool? ?? false;
        setState(() {
          _isExpanded = expanded;
        });
        widget.onExpandStateChanged?.call(expanded);
    }
  }

  void _collapse() {
    setState(() {
      _isExpanded = false;
    });
    _expandController.reverse();
    widget.controller?._isExpanded = false;
    widget.onExpandStateChanged?.call(false);
    _textController.clear();
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    _textController.dispose();
    _focusNode.dispose();
    _expandController.dispose();
    super.dispose();
  }

  int _computeCreationParamsHash() {
    return Object.hashAll([
      widget.placeholder,
      widget.expandable,
      widget.initiallyExpanded,
      widget.expandedHeight,
      widget.tint?.toARGB32(),
      widget.showCancelButton,
      widget.cancelText,
      widget.textColor?.toARGB32(),
      widget.placeholderColor?.toARGB32(),
      textStyleSignature(widget.textStyle),
      widget.cancelButtonColor?.toARGB32(),
      widget.iconColor?.toARGB32(),
      widget.borderRadius,
      widget.interactive,
      widget.glassEffectUnionId,
      widget.glassEffectId,
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
      'placeholder': widget.placeholder,
      'expandable': widget.expandable,
      'initiallyExpanded': widget.initiallyExpanded,
      'expandedHeight': widget.expandedHeight,
      'tint': widget.tint?.toARGB32(),
      'showCancelButton': widget.showCancelButton,
      'cancelText': widget.cancelText,
      'textColor': widget.textColor?.toARGB32(),
      'placeholderColor': widget.placeholderColor?.toARGB32(),
      'textStyle': textStylePayload(widget.textStyle),
      if (widget.cancelButtonColor != null) 'cancelButtonColor': widget.cancelButtonColor!.toARGB32(),
      if (widget.iconColor != null) 'iconColor': widget.iconColor!.toARGB32(),
      if (widget.borderRadius != null) 'borderRadius': widget.borderRadius,
      'interactive': widget.interactive,
      'glassEffectUnionId': widget.glassEffectUnionId,
      'glassEffectId': widget.glassEffectId,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return SizedBox(
        height: widget.expandedHeight,
        child: UiKitView(
          viewType: 'liquid-glass-search-bar-view',
          creationParams: _creationParamsCached(),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
          gestureRecognizers: _searchBarGestureRecognizers,
        ),
      );
    }

    // Flutter fallback.
    return const SizedBox();
  }
}
