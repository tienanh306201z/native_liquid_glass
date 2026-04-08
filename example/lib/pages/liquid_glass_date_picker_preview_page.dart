import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassDatePickerPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassDatePickerPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassDatePickerPreviewPage> createState() => _LiquidGlassDatePickerPreviewPageState();
}

class _LiquidGlassDatePickerPreviewPageState extends State<LiquidGlassDatePickerPreviewPage> {
  DateTime _selectedDate = DateTime.now();
  LiquidGlassDatePickerMode _mode = LiquidGlassDatePickerMode.dateAndTime;
  LiquidGlassDatePickerStyle _style = LiquidGlassDatePickerStyle.compact;
  int _minuteInterval = 1;

  String _formatDate(DateTime dt) {
    switch (_mode) {
      case LiquidGlassDatePickerMode.date:
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      case LiquidGlassDatePickerMode.time:
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      case LiquidGlassDatePickerMode.dateAndTime:
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  double _heightForStyle() {
    return switch (_style) {
      LiquidGlassDatePickerStyle.compact => 44,
      LiquidGlassDatePickerStyle.inline => 360,
      LiquidGlassDatePickerStyle.wheels => 216,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassDatePicker preview'),
        actions: [ThemeModeActionButton(onThemeChanged: widget.onThemeChanged)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_formatDate(_selectedDate), style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      LiquidGlassDatePicker(
                        initialDate: _selectedDate,
                        mode: _mode,
                        style: _style,
                        minuteInterval: _minuteInterval,
                        height: _heightForStyle(),
                        onDateChanged: (dt) => setState(() => _selectedDate = dt),
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Mode', style: Theme.of(context).textTheme.titleSmall),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<LiquidGlassDatePickerMode>(
                        initialValue: _mode,
                        decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: const [
                          DropdownMenuItem(value: LiquidGlassDatePickerMode.date, child: Text('Date')),
                          DropdownMenuItem(value: LiquidGlassDatePickerMode.time, child: Text('Time')),
                          DropdownMenuItem(value: LiquidGlassDatePickerMode.dateAndTime, child: Text('Date & Time')),
                        ],
                        onChanged: (v) => setState(() => _mode = v!),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Style', style: Theme.of(context).textTheme.titleSmall),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<LiquidGlassDatePickerStyle>(
                        segments: const [
                          ButtonSegment(value: LiquidGlassDatePickerStyle.compact, label: Text('Compact')),
                          ButtonSegment(value: LiquidGlassDatePickerStyle.inline, label: Text('Inline')),
                          ButtonSegment(value: LiquidGlassDatePickerStyle.wheels, label: Text('Wheels')),
                        ],
                        selected: {_style},
                        onSelectionChanged: (sel) => setState(() => _style = sel.first),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Minute interval: $_minuteInterval', style: Theme.of(context).textTheme.titleSmall),
                      ),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 1, label: Text('1')),
                          ButtonSegment(value: 5, label: Text('5')),
                          ButtonSegment(value: 15, label: Text('15')),
                          ButtonSegment(value: 30, label: Text('30')),
                        ],
                        selected: {_minuteInterval},
                        onSelectionChanged: (sel) => setState(() => _minuteInterval = sel.first),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
