import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassSearchBarPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassSearchBarPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassSearchBarPreviewPage> createState() => _LiquidGlassSearchBarPreviewPageState();
}

class _LiquidGlassSearchBarPreviewPageState extends State<LiquidGlassSearchBarPreviewPage> {
  final _controller = LiquidGlassSearchBarController();
  String _searchText = '';
  String _submittedText = '';
  bool _expandable = true;
  bool _showCancelButton = true;
  bool _useCustomTint = false;
  bool _useTextColor = false;
  bool _usePlaceholderColor = false;
  bool _useTextStyle = false;
  bool _useIconColor = false;
  bool _useCancelButtonColor = false;
  bool _useBorderRadius = false;
  double _textFontSize = 15;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassSearchBar preview'),
        actions: [ThemeModeActionButton(onThemeChanged: widget.onThemeChanged)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LiquidGlassSearchBar(
                controller: _controller,
                expandable: _expandable,
                showCancelButton: _showCancelButton,
                tint: _useCustomTint ? colorScheme.primary : null,
                textColor: _useTextColor ? colorScheme.primary : null,
                placeholderColor: _usePlaceholderColor ? colorScheme.secondary : null,
                iconColor: _useIconColor ? colorScheme.tertiary : null,
                cancelButtonColor: _useCancelButtonColor ? Colors.red : null,
                borderRadius: _useBorderRadius ? 12 : null,
                textStyle: _useTextStyle ? TextStyle(fontSize: _textFontSize, fontWeight: FontWeight.w500, letterSpacing: 0.2) : null,
                onChanged: (text) => setState(() => _searchText = text),
                onSubmitted: (text) => setState(() => _submittedText = text),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Current: $_searchText', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Submitted: $_submittedText', style: Theme.of(context).textTheme.bodyLarge),
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
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Expandable'),
                          value: _expandable,
                          onChanged: (value) => setState(() => _expandable = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Show cancel button'),
                          value: _showCancelButton,
                          onChanged: (value) => setState(() => _showCancelButton = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Custom tint color'),
                          value: _useCustomTint,
                          onChanged: (value) => setState(() => _useCustomTint = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Custom text color'),
                          value: _useTextColor,
                          onChanged: (value) => setState(() => _useTextColor = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Custom placeholder color'),
                          value: _usePlaceholderColor,
                          onChanged: (value) => setState(() => _usePlaceholderColor = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Custom icon color'),
                          value: _useIconColor,
                          onChanged: (value) => setState(() => _useIconColor = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Custom cancel button color (red)'),
                          value: _useCancelButtonColor,
                          onChanged: (value) => setState(() => _useCancelButtonColor = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Border radius (rounded rect)'),
                          value: _useBorderRadius,
                          onChanged: (value) => setState(() => _useBorderRadius = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Custom text style'),
                          value: _useTextStyle,
                          onChanged: (value) => setState(() => _useTextStyle = value),
                        ),
                        if (_useTextStyle)
                          Row(
                            children: [
                              const Text('Font sz'),
                              Expanded(
                                child: Slider.adaptive(
                                  min: 12,
                                  max: 22,
                                  divisions: 10,
                                  value: _textFontSize,
                                  label: _textFontSize.toStringAsFixed(0),
                                  onChanged: (v) => setState(() => _textFontSize = v),
                                ),
                              ),
                              Text(_textFontSize.toStringAsFixed(0)),
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
