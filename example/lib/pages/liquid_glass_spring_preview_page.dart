import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassSpringPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassSpringPreviewPage({
    super.key,
    required this.onThemeChanged,
  });

  @override
  State<LiquidGlassSpringPreviewPage> createState() =>
      _LiquidGlassSpringPreviewPageState();
}

class _LiquidGlassSpringPreviewPageState
    extends State<LiquidGlassSpringPreviewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spring Animation preview'),
        actions: [
          ThemeModeActionButton(onThemeChanged: widget.onThemeChanged),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _SpringBuilderDemo(),
            SizedBox(height: 24),
            _SpringPresetsDemo(),
            SizedBox(height: 24),
            _VelocitySpringBuilderDemo(),
            SizedBox(height: 24),
            _OffsetSpringBuilderDemo(),
            SizedBox(height: 24),
            _ControllerDemo(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SpringBuilder — tap to toggle scale
// ─────────────────────────────────────────────────────────────────────────────

class _SpringBuilderDemo extends StatefulWidget {
  const _SpringBuilderDemo();

  @override
  State<_SpringBuilderDemo> createState() => _SpringBuilderDemoState();
}

class _SpringBuilderDemoState extends State<_SpringBuilderDemo> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return _DemoCard(
      title: 'SpringBuilder',
      subtitle: 'Tap the circle to toggle scale',
      child: Center(
        child: GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: SpringBuilder(
            value: _expanded ? 1.5 : 1.0,
            spring: LiquidGlassSpring.bouncy(),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.tertiary,
                  ],
                ),
              ),
              child: const Icon(Icons.touch_app, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Spring presets comparison
// ─────────────────────────────────────────────────────────────────────────────

class _SpringPresetsDemo extends StatefulWidget {
  const _SpringPresetsDemo();

  @override
  State<_SpringPresetsDemo> createState() => _SpringPresetsDemoState();
}

class _SpringPresetsDemoState extends State<_SpringPresetsDemo> {
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _DemoCard(
      title: 'Spring Presets',
      subtitle: 'Compare bouncy, snappy, smooth, interactive',
      trailing: TextButton(
        onPressed: () => setState(() => _triggered = !_triggered),
        child: Text(_triggered ? 'Reset' : 'Animate'),
      ),
      child: Column(
        children: [
          _PresetRow(
            label: 'Bouncy',
            color: colorScheme.primary,
            spring: LiquidGlassSpring.bouncy(),
            triggered: _triggered,
          ),
          const SizedBox(height: 12),
          _PresetRow(
            label: 'Snappy',
            color: colorScheme.secondary,
            spring: LiquidGlassSpring.snappy(),
            triggered: _triggered,
          ),
          const SizedBox(height: 12),
          _PresetRow(
            label: 'Smooth',
            color: colorScheme.tertiary,
            spring: LiquidGlassSpring.smooth(),
            triggered: _triggered,
          ),
          const SizedBox(height: 12),
          _PresetRow(
            label: 'Interactive',
            color: colorScheme.error,
            spring: LiquidGlassSpring.interactive(),
            triggered: _triggered,
          ),
        ],
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  final String label;
  final Color color;
  final SpringDescription spring;
  final bool triggered;

  const _PresetRow({
    required this.label,
    required this.color,
    required this.spring,
    required this.triggered,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              return SpringBuilder(
                value: triggered ? 1.0 : 0.0,
                spring: spring,
                builder: (context, value, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: Offset(value * (maxWidth - 32), 0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VelocitySpringBuilder — drag and release
// ─────────────────────────────────────────────────────────────────────────────

class _VelocitySpringBuilderDemo extends StatefulWidget {
  const _VelocitySpringBuilderDemo();

  @override
  State<_VelocitySpringBuilderDemo> createState() =>
      _VelocitySpringBuilderDemoState();
}

class _VelocitySpringBuilderDemoState
    extends State<_VelocitySpringBuilderDemo> {
  double _dragOffset = 0.0;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _DemoCard(
      title: 'VelocitySpringBuilder',
      subtitle: 'Drag horizontally, then release',
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxDrag = (constraints.maxWidth - 64) / 2;
            return VelocitySpringBuilder(
              value: _dragOffset,
              active: _isDragging,
              springWhenActive: LiquidGlassSpring.interactive(),
              springWhenReleased: LiquidGlassSpring.bouncy(),
              builder: (context, value, velocity, child) {
                final tilt = (velocity / 2000).clamp(-0.15, 0.15);
                return Transform.translate(
                  offset: Offset(value, 0),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(tilt),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onHorizontalDragStart: (_) {
                  setState(() => _isDragging = true);
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dragOffset =
                        (_dragOffset + details.delta.dx).clamp(-maxDrag, maxDrag);
                  });
                },
                onHorizontalDragEnd: (_) {
                  setState(() {
                    _isDragging = false;
                    _dragOffset = 0.0;
                  });
                },
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.open_with,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OffsetSpringBuilder — tap to move
// ─────────────────────────────────────────────────────────────────────────────

class _OffsetSpringBuilderDemo extends StatefulWidget {
  const _OffsetSpringBuilderDemo();

  @override
  State<_OffsetSpringBuilderDemo> createState() =>
      _OffsetSpringBuilderDemoState();
}

class _OffsetSpringBuilderDemoState extends State<_OffsetSpringBuilderDemo> {
  Offset _target = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _DemoCard(
      title: 'OffsetSpringBuilder',
      subtitle: 'Tap anywhere to move the dot',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 200,
          color: colorScheme.surfaceContainerLowest,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                onTapDown: (details) {
                  setState(() {
                    _target = Offset(
                      details.localPosition.dx - 20,
                      details.localPosition.dy - 20,
                    );
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: [
                    OffsetSpringBuilder(
                      value: _target,
                      spring: LiquidGlassSpring.snappy(),
                      builder: (context, value, child) {
                        return Positioned(
                          left: value.dx,
                          top: value.dy,
                          child: child!,
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.tertiary,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.tertiary.withValues(alpha: 0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SingleSpringController — imperative API
// ─────────────────────────────────────────────────────────────────────────────

class _ControllerDemo extends StatefulWidget {
  const _ControllerDemo();

  @override
  State<_ControllerDemo> createState() => _ControllerDemoState();
}

class _ControllerDemoState extends State<_ControllerDemo>
    with SingleTickerProviderStateMixin {
  late final SingleSpringController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = SingleSpringController(
      vsync: this,
      spring: LiquidGlassSpring.bouncy(),
      initialValue: 0.0,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _DemoCard(
      title: 'SingleSpringController',
      subtitle: 'Imperative API with bounds clamping',
      child: Column(
        children: [
          ListenableBuilder(
            listenable: _ctrl,
            builder: (context, _) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _ctrl.value,
                      minHeight: 12,
                      backgroundColor:
                          colorScheme.surfaceContainerHighest,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_ctrl.value * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.tonal(
                onPressed: () => _ctrl.animateTo(0.0),
                child: const Text('0%'),
              ),
              FilledButton.tonal(
                onPressed: () => _ctrl.animateTo(0.5),
                child: const Text('50%'),
              ),
              FilledButton.tonal(
                onPressed: () => _ctrl.animateTo(1.0),
                child: const Text('100%'),
              ),
              OutlinedButton(
                onPressed: () => _ctrl.setValue(0.0),
                child: const Text('Reset'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared card wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _DemoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _DemoCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
