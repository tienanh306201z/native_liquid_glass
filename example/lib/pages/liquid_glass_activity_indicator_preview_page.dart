import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassActivityIndicatorPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassActivityIndicatorPreviewPage(
      {super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassActivityIndicatorPreviewPage> createState() =>
      _LiquidGlassActivityIndicatorPreviewPageState();
}

class _LiquidGlassActivityIndicatorPreviewPageState
    extends State<LiquidGlassActivityIndicatorPreviewPage> {
  bool _animating = true;
  bool _hidesWhenStopped = true;
  bool _useCustomColor = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final customColor = _useCustomColor ? colorScheme.tertiary : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassActivityIndicator preview'),
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
                          horizontal: 24, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Column(
                                children: [
                                  LiquidGlassActivityIndicator(
                                    animating: _animating,
                                    hidesWhenStopped: _hidesWhenStopped,
                                    style: LiquidGlassActivityIndicatorStyle
                                        .medium,
                                    color: customColor,
                                    size: 44,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Medium'),
                                ],
                              ),
                              Column(
                                children: [
                                  LiquidGlassActivityIndicator(
                                    animating: _animating,
                                    hidesWhenStopped: _hidesWhenStopped,
                                    style:
                                        LiquidGlassActivityIndicatorStyle.large,
                                    color: customColor,
                                    size: 60,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text('Large'),
                                ],
                              ),
                            ],
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
                        title: const Text('Animating'),
                        value: _animating,
                        onChanged: (v) => setState(() => _animating = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hides when stopped'),
                        value: _hidesWhenStopped,
                        onChanged: (v) => setState(() => _hidesWhenStopped = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom color'),
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
