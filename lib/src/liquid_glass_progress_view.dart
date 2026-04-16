import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/liquid_glass_route_suppression.dart';
import 'utils/native_liquid_glass_utils.dart';

/// A native iOS progress view (UIProgressView) with Liquid Glass effects on iOS 26+.
///
/// On iOS, this renders a native `UIProgressView` through `UiKitView`.
/// On non-iOS platforms, falls back to Flutter's [LinearProgressIndicator].
class LiquidGlassProgressView extends StatefulWidget {
  /// Current progress value, from 0.0 to 1.0.
  final double progress;

  /// Optional tint color for the filled portion of the track.
  final Color? progressTintColor;

  /// Optional tint color for the unfilled portion of the track.
  final Color? trackTintColor;

  /// Height of the widget area. Defaults to 8.
  final double height;

  const LiquidGlassProgressView({
    super.key,
    required this.progress,
    this.progressTintColor,
    this.trackTintColor,
    this.height = 8,
  }) : assert(progress >= 0.0 && progress <= 1.0, 'progress must be between 0.0 and 1.0.');

  @override
  State<LiquidGlassProgressView> createState() => _LiquidGlassProgressViewState();
}

class _LiquidGlassProgressViewState extends State<LiquidGlassProgressView> with LiquidGlassRouteSuppression {
  MethodChannel? _nativeChannel;
  @override MethodChannel? get suppressionChannel => _nativeChannel;
  double? _lastProgress;
  int? _lastProgressTint;
  int? _lastTrackTint;

  @override
  void didUpdateWidget(covariant LiquidGlassProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPropsToNativeIfNeeded();
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    if (_lastProgress != widget.progress) {
      await ch.invokeMethod('setProgress', {'progress': widget.progress});
      _lastProgress = widget.progress;
    }
    final pt = widget.progressTintColor?.toARGB32();
    final tt = widget.trackTintColor?.toARGB32();
    if (_lastProgressTint != pt || _lastTrackTint != tt) {
      await ch.invokeMethod('setColors', {'progressTintColor': pt, 'trackTintColor': tt});
      _lastProgressTint = pt;
      _lastTrackTint = tt;
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-progress-view/$viewId');
    _nativeChannel = channel;
    _lastProgress = widget.progress;
    _lastProgressTint = widget.progressTintColor?.toARGB32();
    _lastTrackTint = widget.trackTintColor?.toARGB32();
    syncGlassRouteVisibility();
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  Map<String, Object?> _buildCreationParams() {
    return <String, Object?>{
      'progress': widget.progress,
      'progressTintColor': widget.progressTintColor?.toARGB32(),
      'trackTintColor': widget.trackTintColor?.toARGB32(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return SizedBox(
        height: widget.height,
        child: UiKitView(
          viewType: 'liquid-glass-progress-view',
          creationParams: _buildCreationParams(),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: LinearProgressIndicator(
        value: widget.progress,
        color: widget.progressTintColor,
        backgroundColor: widget.trackTintColor,
      ),
    );
  }
}
