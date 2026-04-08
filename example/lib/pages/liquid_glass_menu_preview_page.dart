import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassMenuPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassMenuPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassMenuPreviewPage> createState() => _LiquidGlassMenuPreviewPageState();
}

class _LiquidGlassMenuPreviewPageState extends State<LiquidGlassMenuPreviewPage> {
  String? _lastSelected;
  bool _showLabel = true;
  bool _useSubmenu = false;
  bool _useCustomColor = false;
  bool _useLabelTextStyle = false;
  double _iconSize = 20;
  double _buttonHeight = 44;

  List<LiquidGlassMenuItem> _buildItems() {
    final baseItems = [
      const LiquidGlassMenuItem(id: 'share', title: 'Share', icon: NativeLiquidGlassIcon.sfSymbol('square.and.arrow.up')),
      const LiquidGlassMenuItem(id: 'copy', title: 'Copy', icon: NativeLiquidGlassIcon.sfSymbol('doc.on.doc')),
      const LiquidGlassMenuItem(id: 'edit', title: 'Edit', icon: NativeLiquidGlassIcon.sfSymbol('pencil')),
      if (_useSubmenu)
        LiquidGlassMenuItem(
          id: 'more',
          title: 'More',
          icon: const NativeLiquidGlassIcon.sfSymbol('ellipsis.circle'),
          children: [
            const LiquidGlassMenuItem(id: 'print', title: 'Print', icon: NativeLiquidGlassIcon.sfSymbol('printer')),
            const LiquidGlassMenuItem(id: 'export', title: 'Export', icon: NativeLiquidGlassIcon.sfSymbol('square.and.arrow.up.on.square')),
          ],
        ),
      const LiquidGlassMenuItem(id: 'delete', title: 'Delete', icon: NativeLiquidGlassIcon.sfSymbol('trash'), isDestructive: true),
    ];
    return baseItems;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassMenu preview'),
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
                      if (_lastSelected != null) ...[
                        Text('Selected: "$_lastSelected"', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 24),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LiquidGlassMenu(
                            items: _buildItems(),
                            label: _showLabel ? 'Options' : null,
                            icon: const NativeLiquidGlassIcon.sfSymbol('ellipsis.circle'),
                            menuTitle: 'Document Actions',
                            color: _useCustomColor ? colorScheme.primary : null,
                            iconSize: _iconSize,
                            height: _buttonHeight,
                            labelTextStyle: _useLabelTextStyle ? const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2) : null,
                            onItemSelected: (id) => setState(() => _lastSelected = id),
                          ),
                          const SizedBox(width: 16),
                          LiquidGlassMenu.icon(
                            items: _buildItems(),
                            icon: const NativeLiquidGlassIcon.sfSymbol('square.and.arrow.up'),
                            menuTitle: 'Share',
                            color: _useCustomColor ? colorScheme.secondary : null,
                            iconSize: _iconSize,
                            height: _buttonHeight,
                            onItemSelected: (id) => setState(() => _lastSelected = id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Tap or long-press a button to show the menu', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
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
                        title: const Text('Show text label'),
                        value: _showLabel,
                        onChanged: (v) => setState(() => _showLabel = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Include submenu'),
                        value: _useSubmenu,
                        onChanged: (v) => setState(() => _useSubmenu = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom tint color'),
                        value: _useCustomColor,
                        onChanged: (v) => setState(() => _useCustomColor = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom label text style'),
                        value: _useLabelTextStyle,
                        onChanged: (v) => setState(() => _useLabelTextStyle = v),
                      ),
                      Row(
                        children: [
                          const Text('Icon sz'),
                          Expanded(
                            child: Slider.adaptive(
                              min: 14,
                              max: 30,
                              divisions: 16,
                              value: _iconSize,
                              label: _iconSize.toStringAsFixed(0),
                              onChanged: (v) => setState(() => _iconSize = v),
                            ),
                          ),
                          Text(_iconSize.toStringAsFixed(0)),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Height'),
                          Expanded(
                            child: Slider.adaptive(
                              min: 36,
                              max: 60,
                              divisions: 12,
                              value: _buttonHeight,
                              label: _buttonHeight.toStringAsFixed(0),
                              onChanged: (v) => setState(() => _buttonHeight = v),
                            ),
                          ),
                          Text(_buttonHeight.toStringAsFixed(0)),
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
