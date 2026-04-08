import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassPopoverPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassPopoverPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassPopoverPreviewPage> createState() => _LiquidGlassPopoverPreviewPageState();
}

class _LiquidGlassPopoverPreviewPageState extends State<LiquidGlassPopoverPreviewPage> {
  LiquidGlassPopoverHandle? _activeHandle;
  bool _barrierDismissible = true;
  double _preferredWidth = 280;
  double _preferredHeight = 160;

  void _showPopover(BuildContext context, GlobalKey anchorKey) {
    final box = anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final position = box.localToGlobal(Offset.zero);
    final anchorRect = position & box.size;

    _activeHandle?.dismiss();
    _activeHandle = LiquidGlassPopover.show(
      context: context,
      anchorRect: anchorRect,
      preferredWidth: _preferredWidth,
      preferredHeight: _preferredHeight,
      barrierDismissible: _barrierDismissible,
      builder: (ctx) => _PopoverContent(
        onDismiss: () {
          _activeHandle?.dismiss();
          _activeHandle = null;
        },
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
    final anchorKey = GlobalKey();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassPopover preview'),
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
                      Text('Tap the button to show a popover', style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        key: anchorKey,
                        onPressed: () => _showPopover(context, anchorKey),
                        icon: const Icon(Icons.info_outline_rounded),
                        label: const Text('Show Popover'),
                      ),
                    ],
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
                        title: const Text('Tap outside to dismiss'),
                        value: _barrierDismissible,
                        onChanged: (v) => setState(() => _barrierDismissible = v),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Width'),
                          Expanded(
                            child: Slider.adaptive(
                              min: 180,
                              max: 400,
                              value: _preferredWidth,
                              label: _preferredWidth.toStringAsFixed(0),
                              onChanged: (v) => setState(() => _preferredWidth = v),
                            ),
                          ),
                          Text(_preferredWidth.toStringAsFixed(0)),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Height'),
                          Expanded(
                            child: Slider.adaptive(
                              min: 100,
                              max: 400,
                              value: _preferredHeight,
                              label: _preferredHeight.toStringAsFixed(0),
                              onChanged: (v) => setState(() => _preferredHeight = v),
                            ),
                          ),
                          Text(_preferredHeight.toStringAsFixed(0)),
                        ],
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

class _PopoverContent extends StatelessWidget {
  final VoidCallback onDismiss;

  const _PopoverContent({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Popover Content', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('This is a native iOS popover with Liquid Glass effects on iOS 26+.'),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onDismiss, child: const Text('Dismiss')),
          ),
        ],
      ),
    );
  }
}
