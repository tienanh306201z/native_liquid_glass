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
  double _width = 240;
  double _height = 160;
  bool _useCustomTint = false;
  bool _interactive = false;
  bool _animateChanges = false;
  int _tapCount = 0;
  int _customShapeIndex = 0; // 0 = SVG curve, 1 = diamond

  List<LiquidGlassPathOp> get _currentCustomPath =>
      _customShapeIndex == 0 ? _svgCurvePath : _diamondPath;

  Size get _currentCustomPathSize =>
      _customShapeIndex == 0 ? _svgCurvePathSize : _diamondPathSize;

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
                      customPath: _shape == LiquidGlassEffectShape.custom ? _currentCustomPath : null,
                      customPathSize: _shape == LiquidGlassEffectShape.custom ? _currentCustomPathSize : null,
                    ),
                    animateChanges: _animateChanges,
                    width: _width,
                    height: _height,
                    onTap: () => setState(() => _tapCount++),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Tapped $_tapCount times',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _showTestBottomSheet(context),
                      icon: const Icon(Icons.vertical_align_bottom),
                      label: const Text('Bottom Sheet'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const _GlassScreenB()),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Push Screen'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _label(context, 'Effect'),
                        const SizedBox(height: 8),
                        SegmentedButton<LiquidGlassEffect>(
                          segments: const [
                            ButtonSegment(value: LiquidGlassEffect.regular, label: Text('Regular')),
                            ButtonSegment(value: LiquidGlassEffect.clear, label: Text('Clear')),
                          ],
                          selected: {_effect},
                          onSelectionChanged: (s) => setState(() => _effect = s.first),
                        ),
                        const SizedBox(height: 12),
                        _label(context, 'Shape'),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<LiquidGlassEffectShape>(
                            segments: const [
                              ButtonSegment(value: LiquidGlassEffectShape.rect, label: Text('Rect')),
                              ButtonSegment(value: LiquidGlassEffectShape.capsule, label: Text('Capsule')),
                              ButtonSegment(value: LiquidGlassEffectShape.circle, label: Text('Circle')),
                              ButtonSegment(value: LiquidGlassEffectShape.custom, label: Text('Custom')),
                            ],
                            selected: {_shape},
                            onSelectionChanged: (s) => setState(() => _shape = s.first),
                          ),
                        ),
                        if (_shape == LiquidGlassEffectShape.custom) ...[
                          const SizedBox(height: 8),
                          _label(context, 'Custom shape'),
                          const SizedBox(height: 8),
                          SegmentedButton<int>(
                            segments: const [
                              ButtonSegment(value: 0, label: Text('SVG Curve')),
                              ButtonSegment(value: 1, label: Text('Diamond')),
                            ],
                            selected: {_customShapeIndex},
                            onSelectionChanged: (s) => setState(() => _customShapeIndex = s.first),
                          ),
                        ],
                        if (_shape == LiquidGlassEffectShape.rect)
                          _sliderRow('Radius', _cornerRadius, 0, 40, 20, (v) => setState(() => _cornerRadius = v)),
                        _sliderRow('Width', _width, 40, 340, 30, (v) => setState(() => _width = v)),
                        _sliderRow('Height', _height, 40, 340, 30, (v) => setState(() => _height = v)),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Interactive'),
                          value: _interactive,
                          onChanged: (v) => setState(() => _interactive = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Custom tint'),
                          value: _useCustomTint,
                          onChanged: (v) => setState(() => _useCustomTint = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Animate changes'),
                          value: _animateChanges,
                          onChanged: (v) => setState(() => _animateChanges = v),
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

  void _showTestBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.9,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Flutter Bottom Sheet', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 24),
            LiquidGlassContainer(
              config: const LiquidGlassConfig(
                effect: LiquidGlassEffect.regular,
                shape: LiquidGlassEffectShape.capsule,
                interactive: true,
              ),
              width: 200,
              height: 56,
              child: const Center(child: Text('Glass inside sheet')),
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _sliderRow(String label, double value, double min, double max, int divisions, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 52, child: Text(label)),
        Expanded(
          child: Slider.adaptive(
            min: min,
            max: max,
            divisions: divisions,
            value: value,
            label: value.toStringAsFixed(0),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 32, child: Text(value.toStringAsFixed(0))),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen B — pushed from container preview to test navigation suppression
// ─────────────────────────────────────────────────────────────────────────────

class _GlassScreenB extends StatelessWidget {
  const _GlassScreenB();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screen B (Glass)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LiquidGlassContainer(
              config: const LiquidGlassConfig(
                effect: LiquidGlassEffect.regular,
                shape: LiquidGlassEffectShape.rect,
                cornerRadius: 20,
                interactive: true,
              ),
              width: 220,
              height: 120,
              child: const Center(child: Text('Glass on Screen B')),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (ctx) => SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.9,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Sheet from Screen B',
                            style: Theme.of(ctx).textTheme.titleLarge),
                        const SizedBox(height: 24),
                        LiquidGlassContainer(
                          config: const LiquidGlassConfig(
                            effect: LiquidGlassEffect.regular,
                            shape: LiquidGlassEffectShape.capsule,
                            interactive: true,
                          ),
                          width: 200,
                          height: 56,
                          child: const Center(child: Text('Glass inside sheet')),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close')),
                      ],
                    ),
                  ),
                ),
              ),
              icon: const Icon(Icons.vertical_align_bottom),
              label: const Text('Bottom Sheet'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom shape 1: SVG curve (from user's SVG path data)
// Original viewBox: 1 0 24 226 (shifted x by -1).
// ─────────────────────────────────────────────────────────────────────────────

const _svgCurvePathSize = Size(24, 226);

const _svgCurvePath = [
  LiquidGlassPathOp.moveTo(24, 37.7794),
  LiquidGlassPathOp.cubicTo(24, 31.0743, 24, 27.7217, 22.6889, 25.1523),
  LiquidGlassPathOp.cubicTo(21.3779, 22.5828, 18.1255, 20.2256, 11.6208, 15.5111),
  LiquidGlassPathOp.cubicTo(5.74982, 11.2559, 0, 5.90567, 0, 1.27187),
  LiquidGlassPathOp.cubicTo(0, -8.19519, 0.00015, 232.779, 0, 224.806),
  LiquidGlassPathOp.cubicTo(-0.000082, 220.573, 6.76777, 214.354, 13.1156, 209.452),
  LiquidGlassPathOp.cubicTo(18.7325, 205.115, 21.541, 202.947, 22.7705, 200.444),
  LiquidGlassPathOp.cubicTo(24, 197.941, 24, 194.803, 24, 188.526),
  LiquidGlassPathOp.lineTo(24, 37.7794),
  LiquidGlassPathOp.close(),
];

// ─────────────────────────────────────────────────────────────────────────────
// Custom shape 2: Diamond / elongated hexagon
// ─────────────────────────────────────────────────────────────────────────────

const _diamondPathSize = Size(200, 120);

const _diamondPath = [
  LiquidGlassPathOp.moveTo(50, 0),
  LiquidGlassPathOp.lineTo(150, 0),
  LiquidGlassPathOp.lineTo(200, 60),
  LiquidGlassPathOp.lineTo(150, 120),
  LiquidGlassPathOp.lineTo(50, 120),
  LiquidGlassPathOp.lineTo(0, 60),
  LiquidGlassPathOp.close(),
];
