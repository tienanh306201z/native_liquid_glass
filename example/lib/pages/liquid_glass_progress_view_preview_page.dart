import 'dart:async';

import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassProgressViewPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassProgressViewPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassProgressViewPreviewPage> createState() => _LiquidGlassProgressViewPreviewPageState();
}

class _LiquidGlassProgressViewPreviewPageState extends State<LiquidGlassProgressViewPreviewPage> {
  double _downloadProgress = 0.65;
  double _uploadProgress = 0.3;
  bool _useCustomColors = false;
  bool _animate = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleAnimate(bool v) {
    setState(() => _animate = v);
    _timer?.cancel();
    if (v) {
      _downloadProgress = 0;
      _uploadProgress = 0;
      _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = (_downloadProgress + 0.01).clamp(0.0, 1.0);
          _uploadProgress = (_uploadProgress + 0.007).clamp(0.0, 1.0);
          if (_downloadProgress >= 1.0 && _uploadProgress >= 1.0) {
            _downloadProgress = 0;
            _uploadProgress = 0;
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassProgressView preview'),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _ProgressRow(
                            label: 'Download ${(_downloadProgress * 100).toInt()}%',
                            progress: _downloadProgress,
                            progressTintColor: _useCustomColors ? colorScheme.primary : null,
                            trackTintColor: _useCustomColors ? colorScheme.surfaceContainerHighest : null,
                          ),
                          const SizedBox(height: 24),
                          _ProgressRow(
                            label: 'Upload ${(_uploadProgress * 100).toInt()}%',
                            progress: _uploadProgress,
                            progressTintColor: _useCustomColors ? colorScheme.tertiary : null,
                            trackTintColor: _useCustomColors ? colorScheme.surfaceContainerHighest : null,
                          ),
                          if (!_animate) ...[
                            const SizedBox(height: 24),
                            Text('Drag to adjust:', style: Theme.of(context).textTheme.labelMedium),
                            Slider.adaptive(value: _downloadProgress, onChanged: (v) => setState(() => _downloadProgress = v)),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Animate progress'),
                        value: _animate,
                        onChanged: _toggleAnimate,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom colors'),
                        value: _useCustomColors,
                        onChanged: (v) => setState(() => _useCustomColors = v),
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

class _ProgressRow extends StatelessWidget {
  final String label;
  final double progress;
  final Color? progressTintColor;
  final Color? trackTintColor;

  const _ProgressRow({required this.label, required this.progress, this.progressTintColor, this.trackTintColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 8),
        LiquidGlassProgressView(progress: progress, progressTintColor: progressTintColor, trackTintColor: trackTintColor, height: 6),
      ],
    );
  }
}
