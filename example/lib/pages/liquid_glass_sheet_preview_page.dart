import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassSheetPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassSheetPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassSheetPreviewPage> createState() => _LiquidGlassSheetPreviewPageState();
}

class _LiquidGlassSheetPreviewPageState extends State<LiquidGlassSheetPreviewPage> {
  LiquidGlassSheetHandle? _activeHandle;
  bool _showTitle = true;
  bool _showMessage = true;
  bool _prefersGrabberVisible = true;
  bool _isModal = false;
  bool _mediumDetent = true;
  bool _largeDetent = true;

  List<LiquidGlassSheetDetent> get _detents => [
        if (_mediumDetent) LiquidGlassSheetDetent.medium,
        if (_largeDetent) LiquidGlassSheetDetent.large,
      ];

  void _showSheet(BuildContext context) {
    _activeHandle?.dismiss();
    _activeHandle = LiquidGlassSheet.show(
      context: context,
      title: _showTitle ? 'Sheet Title' : null,
      message: _showMessage ? 'This is a Liquid Glass native sheet on iOS 26+.' : null,
      detents: _detents.isNotEmpty ? _detents : [LiquidGlassSheetDetent.medium],
      prefersGrabberVisible: _prefersGrabberVisible,
      isModal: _isModal,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Custom sheet body content. Can include any widget.'),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _activeHandle?.dismiss();
                _activeHandle = null;
              },
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _activeHandle?.dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassSheet preview'),
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
                  child: FilledButton.icon(
                    onPressed: () => _showSheet(context),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Show Sheet'),
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
                        title: const Text('Show title'),
                        value: _showTitle,
                        onChanged: (v) => setState(() => _showTitle = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show message'),
                        value: _showMessage,
                        onChanged: (v) => setState(() => _showMessage = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Prefers grabber visible'),
                        value: _prefersGrabberVisible,
                        onChanged: (v) => setState(() => _prefersGrabberVisible = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Modal (non-dismissible)'),
                        value: _isModal,
                        onChanged: (v) => setState(() => _isModal = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Medium detent'),
                        value: _mediumDetent,
                        onChanged: (v) => setState(() => _mediumDetent = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Large detent'),
                        value: _largeDetent,
                        onChanged: (v) => setState(() => _largeDetent = v),
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
