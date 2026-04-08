import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassContainerPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassContainerPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassContainerPreviewPage> createState() => _LiquidGlassContainerPreviewPageState();
}

class _LiquidGlassContainerPreviewPageState extends State<LiquidGlassContainerPreviewPage> {
  LiquidGlassEffect _effect = LiquidGlassEffect.regular;
  LiquidGlassEffectShape _shape = LiquidGlassEffectShape.rect;
  double _cornerRadius = 16;
  bool _useCustomTint = false;
  bool _interactive = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassContainer preview'),
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
                  child: LiquidGlassContainer(
                    config: LiquidGlassConfig(
                      effect: _effect,
                      shape: _shape,
                      cornerRadius: _shape == LiquidGlassEffectShape.rect ? _cornerRadius : null,
                      tint: _useCustomTint ? colorScheme.primary : null,
                      interactive: _interactive,
                    ),
                    width: 240,
                    height: 160,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('Liquid Glass\nContainer', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Effect', style: Theme.of(context).textTheme.titleSmall),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<LiquidGlassEffect>(
                        segments: const [
                          ButtonSegment(value: LiquidGlassEffect.regular, label: Text('Regular')),
                          ButtonSegment(value: LiquidGlassEffect.clear, label: Text('Clear')),
                        ],
                        selected: {_effect},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _effect = selection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Shape', style: Theme.of(context).textTheme.titleSmall),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<LiquidGlassEffectShape>(
                        segments: const [
                          ButtonSegment(value: LiquidGlassEffectShape.rect, label: Text('Rect')),
                          ButtonSegment(value: LiquidGlassEffectShape.capsule, label: Text('Capsule')),
                          ButtonSegment(value: LiquidGlassEffectShape.circle, label: Text('Circle')),
                        ],
                        selected: {_shape},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _shape = selection.first;
                          });
                        },
                      ),
                      if (_shape == LiquidGlassEffectShape.rect)
                        Row(
                          children: [
                            const Text('Corner radius'),
                            Expanded(
                              child: Slider.adaptive(
                                min: 0,
                                max: 40,
                                divisions: 20,
                                value: _cornerRadius,
                                label: _cornerRadius.toStringAsFixed(0),
                                onChanged: (value) {
                                  setState(() {
                                    _cornerRadius = value;
                                  });
                                },
                              ),
                            ),
                            Text(_cornerRadius.toStringAsFixed(0)),
                          ],
                        ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Interactive'),
                        value: _interactive,
                        onChanged: (value) {
                          setState(() {
                            _interactive = value;
                          });
                        },
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom tint'),
                        value: _useCustomTint,
                        onChanged: (value) {
                          setState(() {
                            _useCustomTint = value;
                          });
                        },
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
