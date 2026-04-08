import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassColorPickerPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassColorPickerPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassColorPickerPreviewPage> createState() => _LiquidGlassColorPickerPreviewPageState();
}

class _LiquidGlassColorPickerPreviewPageState extends State<LiquidGlassColorPickerPreviewPage> {
  Color _selectedColor = const Color(0xFF5AC8FA);
  bool _supportsAlpha = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassColorPicker preview'),
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
                      Text('Selected Color', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: _selectedColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white24),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${_selectedColor.toARGB32().toRadixString(16).toUpperCase().substring(2)}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontFamily: 'monospace'),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'R:${_selectedColor.r.toInt()}  G:${_selectedColor.g.toInt()}  B:${_selectedColor.b.toInt()}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 4),
                              Text('Alpha: ${(_selectedColor.a / 255 * 100).toStringAsFixed(0)}%', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Text('Tap the swatch to open the color picker', style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 16),
                      LiquidGlassColorPicker(
                        selectedColor: _selectedColor,
                        onColorChanged: (c) => setState(() => _selectedColor = c),
                        title: 'Pick a Color',
                        supportsAlpha: _supportsAlpha,
                        size: 64,
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Supports alpha channel'),
                    value: _supportsAlpha,
                    onChanged: (v) => setState(() => _supportsAlpha = v),
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
