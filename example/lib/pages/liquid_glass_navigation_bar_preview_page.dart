import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassNavigationBarPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassNavigationBarPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassNavigationBarPreviewPage> createState() => _LiquidGlassNavigationBarPreviewPageState();
}

class _LiquidGlassNavigationBarPreviewPageState extends State<LiquidGlassNavigationBarPreviewPage> {
  bool _largeTitle = false;
  bool _useTintColor = false;
  bool _useBackgroundColor = false;
  bool _useTitleTextStyle = false;
  double _titleFontSize = 17;
  double _itemIconSize = 20;
  String? _lastTappedItem;

  static const _tintColor = Color(0xFF007AFF);
  static const _backgroundColor = Color(0xFFF2F2F7);

  List<LiquidGlassNavBarItem> get _trailingItems => [
    LiquidGlassNavBarItem(id: 'compose', icon: const NativeLiquidGlassIcon.sfSymbol('square.and.pencil'), iconSize: _itemIconSize),
    LiquidGlassNavBarItem(id: 'search', icon: const NativeLiquidGlassIcon.sfSymbol('magnifyingglass'), iconSize: _itemIconSize),
  ];

  List<LiquidGlassNavBarItem> get _leadingItems => [
    LiquidGlassNavBarItem(id: 'back', icon: const NativeLiquidGlassIcon.sfSymbol('chevron.left'), label: 'Back', iconSize: _itemIconSize),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassNavigationBar preview'),
        actions: [ThemeModeActionButton(onThemeChanged: widget.onThemeChanged)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LiquidGlassNavigationBar(
                title: 'Inbox',
                largeTitle: _largeTitle,
                leadingItems: _leadingItems,
                trailingItems: _trailingItems,
                tintColor: _useTintColor ? _tintColor : null,
                backgroundColor: _useBackgroundColor ? _backgroundColor : null,
                titleTextStyle: _useTitleTextStyle ? TextStyle(fontSize: _titleFontSize, fontWeight: FontWeight.bold, letterSpacing: 0.3) : null,
                onItemTapped: (id) => setState(() => _lastTappedItem = id),
              ),
              const SizedBox(height: 12),
              if (_lastTappedItem != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Tapped: "$_lastTappedItem"', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                ),
              Expanded(
                child: Center(
                  child: Text('Navigation bar is shown above', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
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
                        title: const Text('Large title'),
                        value: _largeTitle,
                        onChanged: (v) => setState(() => _largeTitle = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom tint color (blue)'),
                        value: _useTintColor,
                        onChanged: (v) => setState(() => _useTintColor = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom background color'),
                        value: _useBackgroundColor,
                        onChanged: (v) => setState(() => _useBackgroundColor = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom title text style'),
                        value: _useTitleTextStyle,
                        onChanged: (v) => setState(() => _useTitleTextStyle = v),
                      ),
                      if (_useTitleTextStyle)
                        Row(
                          children: [
                            const Text('Title sz'),
                            Expanded(
                              child: Slider.adaptive(
                                min: 12,
                                max: 24,
                                divisions: 12,
                                value: _titleFontSize,
                                label: _titleFontSize.toStringAsFixed(0),
                                onChanged: (v) => setState(() => _titleFontSize = v),
                              ),
                            ),
                            Text(_titleFontSize.toStringAsFixed(0)),
                          ],
                        ),
                      Row(
                        children: [
                          const Text('Item icon sz'),
                          Expanded(
                            child: Slider.adaptive(
                              min: 14,
                              max: 28,
                              divisions: 14,
                              value: _itemIconSize,
                              label: _itemIconSize.toStringAsFixed(0),
                              onChanged: (v) => setState(() => _itemIconSize = v),
                            ),
                          ),
                          Text(_itemIconSize.toStringAsFixed(0)),
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
