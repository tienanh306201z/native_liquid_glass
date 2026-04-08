import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassSegmentedControlPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassSegmentedControlPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassSegmentedControlPreviewPage> createState() => _LiquidGlassSegmentedControlPreviewPageState();
}

class _LiquidGlassSegmentedControlPreviewPageState extends State<LiquidGlassSegmentedControlPreviewPage> {
  int _viewMode = 0;
  int _sortOrder = 0;
  int _category = 0;
  bool _enabled = true;
  bool _useCustomColor = false;
  double _controlHeight = 32;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassSegmentedControl preview'),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('View Mode', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      LiquidGlassSegmentedControl(
                        labels: const ['Grid', 'List', 'Columns'],
                        selectedIndex: _viewMode,
                        onValueChanged: (i) => setState(() => _viewMode = i),
                        enabled: _enabled,
                        color: _useCustomColor ? colorScheme.primary : null,
                        height: _controlHeight,
                      ),
                      const SizedBox(height: 24),
                      Text('Sort Order', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      LiquidGlassSegmentedControl(
                        labels: const ['Name', 'Date', 'Size'],
                        selectedIndex: _sortOrder,
                        onValueChanged: (i) => setState(() => _sortOrder = i),
                        enabled: _enabled,
                        color: _useCustomColor ? colorScheme.primary : null,
                        height: _controlHeight,
                      ),
                      const SizedBox(height: 24),
                      Text('Category', style: Theme.of(context).textTheme.labelMedium),
                      const SizedBox(height: 8),
                      LiquidGlassSegmentedControl(
                        labels: const ['All', 'Photos', 'Videos', 'Docs'],
                        selectedIndex: _category,
                        onValueChanged: (i) => setState(() => _category = i),
                        enabled: _enabled,
                        color: _useCustomColor ? colorScheme.primary : null,
                        height: _controlHeight,
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
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enabled'),
                        value: _enabled,
                        onChanged: (v) => setState(() => _enabled = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom tint color'),
                        value: _useCustomColor,
                        onChanged: (v) => setState(() => _useCustomColor = v),
                      ),
                      Row(
                        children: [
                          const Text('Height'),
                          Expanded(
                            child: Slider.adaptive(
                              min: 28,
                              max: 48,
                              divisions: 10,
                              value: _controlHeight,
                              label: _controlHeight.toStringAsFixed(0),
                              onChanged: (v) => setState(() => _controlHeight = v),
                            ),
                          ),
                          Text(_controlHeight.toStringAsFixed(0)),
                        ],
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
