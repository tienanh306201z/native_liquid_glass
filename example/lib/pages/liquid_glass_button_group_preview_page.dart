import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassButtonGroupPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassButtonGroupPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassButtonGroupPreviewPage> createState() => _LiquidGlassButtonGroupPreviewPageState();
}

class _LiquidGlassButtonGroupPreviewPageState extends State<LiquidGlassButtonGroupPreviewPage> {
  String _lastPressed = 'None';
  Axis _axis = Axis.horizontal;
  double _spacing = 8;
  bool _useForegroundColor = false;
  bool _useLabelTextStyle = false;
  bool _useGlassTint = false;
  bool _disableDelete = false;
  double _iconSize = 18;
  LiquidGlassImagePlacement _imagePlacement = LiquidGlassImagePlacement.leading;
  double _imagePadding = 8;
  bool _useCustomPadding = false;
  bool _useBorderRadius = false;
  final int _maxLines = 1;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassButtonGroup preview'),
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
                      Text('Last pressed: $_lastPressed', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 24),
                      LiquidGlassButtonGroup(
                        axis: _axis,
                        spacing: _spacing,
                        buttons: [
                          LiquidGlassButtonData(
                            label: 'Share',
                            icon: const NativeLiquidGlassIcon.sfSymbol('square.and.arrow.up'),
                            foregroundColor: _useForegroundColor ? colorScheme.primary : null,
                            tint: _useGlassTint ? colorScheme.secondaryContainer : null,
                            iconSize: _iconSize,
                            imagePlacement: _imagePlacement,
                            imagePadding: _imagePadding,
                            borderRadius: _useBorderRadius ? 12 : null,
                            padding: _useCustomPadding ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12) : null,
                            maxLines: _maxLines,
                            onPressed: () => setState(() => _lastPressed = 'Share'),
                          ),
                          LiquidGlassButtonData(
                            label: 'Edit',
                            icon: const NativeLiquidGlassIcon.sfSymbol('pencil'),
                            labelTextStyle: _useLabelTextStyle ? const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.3) : null,
                            iconSize: _iconSize,
                            imagePlacement: _imagePlacement,
                            imagePadding: _imagePadding,
                            borderRadius: _useBorderRadius ? 12 : null,
                            padding: _useCustomPadding ? const EdgeInsets.symmetric(horizontal: 20, vertical: 12) : null,
                            onPressed: () => setState(() => _lastPressed = 'Edit'),
                          ),
                          LiquidGlassButtonData(
                            icon: const NativeLiquidGlassIcon.sfSymbol('trash'),
                            iconColor: Colors.red,
                            iconSize: _iconSize,
                            enabled: !_disableDelete,
                            borderRadius: _useBorderRadius ? 12 : null,
                            onPressed: () => setState(() => _lastPressed = 'Delete'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Axis', style: Theme.of(context).textTheme.titleSmall),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<Axis>(
                          segments: const [
                            ButtonSegment(value: Axis.horizontal, label: Text('Horizontal')),
                            ButtonSegment(value: Axis.vertical, label: Text('Vertical')),
                          ],
                          selected: {_axis},
                          onSelectionChanged: (selection) => setState(() => _axis = selection.first),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Image placement', style: Theme.of(context).textTheme.titleSmall),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<LiquidGlassImagePlacement>(
                          segments: const [
                            ButtonSegment(value: LiquidGlassImagePlacement.leading, label: Text('Lead')),
                            ButtonSegment(value: LiquidGlassImagePlacement.trailing, label: Text('Trail')),
                            ButtonSegment(value: LiquidGlassImagePlacement.top, label: Text('Top')),
                            ButtonSegment(value: LiquidGlassImagePlacement.bottom, label: Text('Btm')),
                          ],
                          selected: {_imagePlacement},
                          onSelectionChanged: (sel) => setState(() => _imagePlacement = sel.first),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Foreground color (Share)'),
                          value: _useForegroundColor,
                          onChanged: (v) => setState(() => _useForegroundColor = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Custom label text style (Edit)'),
                          value: _useLabelTextStyle,
                          onChanged: (v) => setState(() => _useLabelTextStyle = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Glass tint (Share)'),
                          value: _useGlassTint,
                          onChanged: (v) => setState(() => _useGlassTint = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Custom padding'),
                          value: _useCustomPadding,
                          onChanged: (v) => setState(() => _useCustomPadding = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Border radius (rounded rect)'),
                          value: _useBorderRadius,
                          onChanged: (v) => setState(() => _useBorderRadius = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Disable Delete button'),
                          value: _disableDelete,
                          onChanged: (v) => setState(() => _disableDelete = v),
                        ),
                        Row(
                          children: [
                            const Text('Spacing'),
                            Expanded(
                              child: Slider.adaptive(
                                min: 0,
                                max: 24,
                                divisions: 12,
                                value: _spacing,
                                label: _spacing.toStringAsFixed(0),
                                onChanged: (value) => setState(() => _spacing = value),
                              ),
                            ),
                            Text(_spacing.toStringAsFixed(0)),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Icon sz'),
                            Expanded(
                              child: Slider.adaptive(
                                min: 14,
                                max: 28,
                                divisions: 14,
                                value: _iconSize,
                                label: _iconSize.toStringAsFixed(0),
                                onChanged: (value) => setState(() => _iconSize = value),
                              ),
                            ),
                            Text(_iconSize.toStringAsFixed(0)),
                          ],
                        ),
                        Row(
                          children: [
                            const Text('Img pad'),
                            Expanded(
                              child: Slider.adaptive(
                                min: 0,
                                max: 20,
                                divisions: 20,
                                value: _imagePadding,
                                label: _imagePadding.toStringAsFixed(0),
                                onChanged: (value) => setState(() => _imagePadding = value),
                              ),
                            ),
                            Text(_imagePadding.toStringAsFixed(0)),
                          ],
                        ),
                      ],
                    ),
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
