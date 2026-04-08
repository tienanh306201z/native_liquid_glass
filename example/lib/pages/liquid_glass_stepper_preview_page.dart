import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassStepperPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassStepperPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassStepperPreviewPage> createState() =>
      _LiquidGlassStepperPreviewPageState();
}

class _LiquidGlassStepperPreviewPageState
    extends State<LiquidGlassStepperPreviewPage> {
  double _quantity = 1;
  double _fontSize = 16;
  double _rating = 3;
  bool _enabled = true;
  bool _useCustomColor = false;
  bool _wraps = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tintColor = _useCustomColor ? colorScheme.tertiary : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassStepper preview'),
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
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StepperRow(
                            label: 'Quantity',
                            value: _quantity,
                            min: 1,
                            max: 10,
                            step: 1,
                            wraps: _wraps,
                            enabled: _enabled,
                            color: tintColor,
                            onChanged: (v) => setState(() => _quantity = v),
                          ),
                          const SizedBox(height: 16),
                          _StepperRow(
                            label: 'Font size (${_fontSize.toInt()}pt)',
                            value: _fontSize,
                            min: 10,
                            max: 36,
                            step: 2,
                            wraps: _wraps,
                            enabled: _enabled,
                            color: tintColor,
                            onChanged: (v) => setState(() => _fontSize = v),
                          ),
                          const SizedBox(height: 16),
                          _StepperRow(
                            label: 'Rating (${'★' * _rating.toInt()})',
                            value: _rating,
                            min: 1,
                            max: 5,
                            step: 1,
                            wraps: _wraps,
                            enabled: _enabled,
                            color: tintColor,
                            onChanged: (v) => setState(() => _rating = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        title: const Text('Wrap around at boundaries'),
                        value: _wraps,
                        onChanged: (v) => setState(() => _wraps = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom tint color'),
                        value: _useCustomColor,
                        onChanged: (v) => setState(() => _useCustomColor = v),
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

class _StepperRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final bool wraps;
  final bool enabled;
  final Color? color;
  final ValueChanged<double> onChanged;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.wraps,
    required this.enabled,
    required this.onChanged,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
        LiquidGlassStepper(
          value: value,
          min: min,
          max: max,
          step: step,
          wraps: wraps,
          enabled: enabled,
          color: color,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
