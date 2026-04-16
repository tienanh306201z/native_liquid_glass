import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'utils/liquid_glass_route_suppression.dart';
import 'utils/native_liquid_glass_utils.dart';

/// Mode of the date picker.
enum LiquidGlassDatePickerMode {
  /// Date only (year, month, day).
  date,

  /// Time only (hour, minute).
  time,

  /// Date and time.
  dateAndTime,
}

/// Preferred display style of the date picker.
enum LiquidGlassDatePickerStyle {
  /// Compact inline display.
  compact,

  /// Full inline calendar/time wheels.
  inline,

  /// Spinning wheel columns.
  wheels,
}

/// Controller for [LiquidGlassDatePicker].
class LiquidGlassDatePickerController extends ChangeNotifier {
  MethodChannel? _channel;

  /// Set the date programmatically.
  Future<void> setDate(DateTime date, {bool animated = false}) async {
    await _channel?.invokeMethod<void>('setDate', {'date': date.millisecondsSinceEpoch, 'animated': animated});
  }

  /// Set minimum date.
  Future<void> setMinimumDate(DateTime date) async {
    await _channel?.invokeMethod<void>('setMinimumDate', {'date': date.millisecondsSinceEpoch});
  }

  /// Set maximum date.
  Future<void> setMaximumDate(DateTime date) async {
    await _channel?.invokeMethod<void>('setMaximumDate', {'date': date.millisecondsSinceEpoch});
  }
}

/// A native iOS date picker (UIDatePicker) with Liquid Glass effects on iOS 26+.
///
/// Supports date, time, and dateAndTime modes with
/// compact, inline, or wheels styles.
///
/// On non-iOS platforms, falls back to [showDatePicker] / [showTimePicker].
class LiquidGlassDatePicker extends StatefulWidget {
  /// The initial date.
  final DateTime initialDate;

  /// Picker mode.
  final LiquidGlassDatePickerMode mode;

  /// Preferred display style.
  final LiquidGlassDatePickerStyle style;

  /// Called when the selected date changes.
  final ValueChanged<DateTime> onDateChanged;

  /// Minimum selectable date.
  final DateTime? minimumDate;

  /// Maximum selectable date.
  final DateTime? maximumDate;

  /// Minute interval for time selection (1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30).
  final int minuteInterval;

  /// Optional tint color.
  final Color? color;

  /// Height of the picker. Defaults vary by style.
  final double height;

  /// Optional controller for imperative updates.
  final LiquidGlassDatePickerController? controller;

  const LiquidGlassDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateChanged,
    this.mode = LiquidGlassDatePickerMode.dateAndTime,
    this.style = LiquidGlassDatePickerStyle.compact,
    this.minimumDate,
    this.maximumDate,
    this.minuteInterval = 1,
    this.color,
    this.height = 200,
    this.controller,
  });

  @override
  State<LiquidGlassDatePicker> createState() => _LiquidGlassDatePickerState();
}

class _LiquidGlassDatePickerState extends State<LiquidGlassDatePicker> with LiquidGlassRouteSuppression {
  MethodChannel? _nativeChannel;
  @override MethodChannel? get suppressionChannel => _nativeChannel;
  int? _lastMode;
  int? _lastStyle;
  int? _lastMinDate;
  int? _lastMaxDate;
  int? _lastMinuteInterval;
  int? _lastColor;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant LiquidGlassDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _bindController();
    }
    _syncPropsToNativeIfNeeded();
  }

  void _bindController() {
    widget.controller?._channel = _nativeChannel;
  }

  Future<void> _handleNativeMethodCall(MethodCall call) async {
    if (call.method == 'dateChanged') {
      final millis = call.arguments as int;
      widget.onDateChanged(DateTime.fromMillisecondsSinceEpoch(millis));
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _nativeChannel?.setMethodCallHandler(null);
    final channel = MethodChannel('liquid-glass-date-picker-view/$viewId');
    channel.setMethodCallHandler(_handleNativeMethodCall);
    _nativeChannel = channel;
    widget.controller?._channel = channel;
    _lastMode = widget.mode.index;
    _lastStyle = widget.style.index;
    _lastMinDate = widget.minimumDate?.millisecondsSinceEpoch;
    _lastMaxDate = widget.maximumDate?.millisecondsSinceEpoch;
    _lastMinuteInterval = widget.minuteInterval;
    _lastColor = widget.color?.toARGB32();
    syncGlassRouteVisibility();
  }

  @override
  void dispose() {
    _nativeChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _syncPropsToNativeIfNeeded() async {
    final ch = _nativeChannel;
    if (ch == null) return;

    final minDate = widget.minimumDate?.millisecondsSinceEpoch;
    final maxDate = widget.maximumDate?.millisecondsSinceEpoch;
    final color = widget.color?.toARGB32();

    if (widget.mode.index != _lastMode || widget.style.index != _lastStyle || widget.minuteInterval != _lastMinuteInterval) {
      // Mode/style/interval change requires full config update
      await ch.invokeMethod('updateConfig', _buildCreationParams());
      _lastMode = widget.mode.index;
      _lastStyle = widget.style.index;
      _lastMinuteInterval = widget.minuteInterval;
      _lastMinDate = minDate;
      _lastMaxDate = maxDate;
      _lastColor = color;
      return;
    }

    if (minDate != _lastMinDate) {
      await ch.invokeMethod('setMinimumDate', {'date': minDate});
      _lastMinDate = minDate;
    }
    if (maxDate != _lastMaxDate) {
      await ch.invokeMethod('setMaximumDate', {'date': maxDate});
      _lastMaxDate = maxDate;
    }
    if (color != _lastColor) {
      await ch.invokeMethod('setColor', {'color': color});
      _lastColor = color;
    }
  }

  Map<String, Object?> _buildCreationParams() {
    return <String, Object?>{
      'initialDate': widget.initialDate.millisecondsSinceEpoch,
      'mode': widget.mode.index,
      'style': widget.style.index,
      'minimumDate': widget.minimumDate?.millisecondsSinceEpoch,
      'maximumDate': widget.maximumDate?.millisecondsSinceEpoch,
      'minuteInterval': widget.minuteInterval,
      'color': widget.color?.toARGB32(),
    };
  }

  @override
  Widget build(BuildContext context) {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      return SizedBox(
        height: widget.height,
        child: UiKitView(
          viewType: 'liquid-glass-date-picker-view',
          creationParams: _buildCreationParams(),
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    }

    return const SizedBox();
  }
}
