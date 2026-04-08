import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassSliderPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassSliderPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassSliderPreviewPage> createState() => _LiquidGlassSliderPreviewPageState();
}

class _LiquidGlassSliderPreviewPageState extends State<LiquidGlassSliderPreviewPage> {
  double _volume = 0.6;
  double _brightness = 0.8;
  double _temperature = 21;
  bool _enabled = true;
  bool _useCustomColor = false;
  bool _useStep = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tintColor = _useCustomColor ? colorScheme.tertiary : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassSlider preview'),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SliderRow(
                            label: 'Volume',
                            icon: Icons.volume_up_rounded,
                            value: _volume,
                            min: 0.0,
                            max: 1.0,
                            step: _useStep ? 0.1 : null,
                            enabled: _enabled,
                            color: tintColor,
                            onChanged: (v) => setState(() => _volume = v),
                          ),
                          const SizedBox(height: 16),
                          _SliderRow(
                            label: 'Brightness',
                            icon: Icons.brightness_6_rounded,
                            value: _brightness,
                            min: 0.0,
                            max: 1.0,
                            step: _useStep ? 0.1 : null,
                            enabled: _enabled,
                            color: tintColor,
                            onChanged: (v) => setState(() => _brightness = v),
                          ),
                          const SizedBox(height: 16),
                          _SliderRow(
                            label: 'Temp ${_temperature.toStringAsFixed(0)}°C',
                            icon: Icons.thermostat_rounded,
                            value: _temperature,
                            min: 16,
                            max: 30,
                            step: _useStep ? 1.0 : null,
                            enabled: _enabled,
                            color: tintColor,
                            onChanged: (v) => setState(() => _temperature = v),
                          ),
                        ],
                      ),
                    ),
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
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Discrete steps'),
                        value: _useStep,
                        onChanged: (v) => setState(() => _useStep = v),
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

class _SliderRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final double? step;
  final bool enabled;
  final Color? color;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.enabled,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: LiquidGlassSlider(value: value, min: min, max: max, step: step, onChanged: onChanged, enabled: enabled, color: color),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 48,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.end),
        ),
      ],
    );
  }
}
