import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassAlertPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassAlertPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassAlertPreviewPage> createState() => _LiquidGlassAlertPreviewPageState();
}

class _LiquidGlassAlertPreviewPageState extends State<LiquidGlassAlertPreviewPage> {
  LiquidGlassAlertStyle _style = LiquidGlassAlertStyle.alert;
  String? _lastResult;
  bool _isLoading = false;

  Future<void> _showAlert(BuildContext context) async {
    setState(() => _isLoading = true);
    final result = await LiquidGlassAlert.show(
      context: context,
      title: 'Delete Item',
      message: 'Are you sure you want to delete this item? This action cannot be undone.',
      style: _style,
      actions: [
        const LiquidGlassAlertAction(id: 'cancel', title: 'Cancel', isCancel: true),
        const LiquidGlassAlertAction(id: 'delete', title: 'Delete', isDestructive: true),
      ],
    );
    if (mounted) {
      setState(() {
        _lastResult = result ?? 'dismissed';
        _isLoading = false;
      });
    }
  }

  Future<void> _showConfirm(BuildContext context) async {
    setState(() => _isLoading = true);
    final confirmed = await LiquidGlassAlert.confirm(
      context: context,
      title: 'Save Changes?',
      message: 'Do you want to save your changes before leaving?',
      confirmTitle: 'Save',
      cancelTitle: 'Discard',
    );
    if (mounted) {
      setState(() {
        _lastResult = confirmed ? 'confirmed' : 'discarded';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassAlert preview'),
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
                    spacing: 16,
                    children: [
                      if (_lastResult != null) ...[
                        Text('Last result: "$_lastResult"', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 8),
                      ],
                      FilledButton.icon(
                        onPressed: _isLoading ? null : () => _showAlert(context),
                        icon: const Icon(Icons.warning_amber_rounded),
                        label: const Text('Show Alert'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _isLoading ? null : () => _showConfirm(context),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Show Confirm'),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Alert style', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      SegmentedButton<LiquidGlassAlertStyle>(
                        segments: const [
                          ButtonSegment(value: LiquidGlassAlertStyle.alert, label: Text('Alert')),
                          ButtonSegment(value: LiquidGlassAlertStyle.actionSheet, label: Text('Action Sheet')),
                        ],
                        selected: {_style},
                        onSelectionChanged: (s) => setState(() => _style = s.first),
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
