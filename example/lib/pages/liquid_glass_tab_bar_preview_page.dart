import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassTabBarPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassTabBarPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassTabBarPreviewPage> createState() => _LiquidGlassTabBarPreviewPageState();
}

class _LiquidGlassTabBarPreviewPageState extends State<LiquidGlassTabBarPreviewPage> {
  int _currentIndex = 0;
  bool _showLabels = true;
  bool _showActionButton = true;
  bool _useCustomColors = true;
  bool _useBadgeColor = false;
  LiquidGlassTabBarItemPositioning _positioning = LiquidGlassTabBarItemPositioning.automatic;
  double _iconSize = 24;
  double _labelFontSize = 10;
  FontWeight _labelFontWeight = FontWeight.w500;
  double _labelLetterSpacing = 0.0;

  Color? _selectedColorForItem(int index) {
    if (!_useCustomColors) {
      return null;
    }

    const palette = <Color>[Color(0xFFFF6B6B), Color(0xFF4CD964), Color(0xFFFFC107), Color(0xFF5AC8FA)];

    return palette[index % palette.length];
  }

  List<LiquidGlassTabItem> _buildTabItems() {
    return [
      LiquidGlassTabItem(
        label: 'Home',
        icon: const NativeLiquidGlassIcon.sfSymbol('house'),
        selectedIcon: const NativeLiquidGlassIcon.sfSymbol('house.fill'),
        iconSize: _iconSize,
        selectedItemColor: _selectedColorForItem(0),
      ),
      LiquidGlassTabItem(
        label: 'Explore',
        icon: const NativeLiquidGlassIcon.sfSymbol('magnifyingglass'),
        iconSize: _iconSize,
        selectedItemColor: _selectedColorForItem(1),
      ),
      LiquidGlassTabItem(
        label: 'Saved',
        icon: const NativeLiquidGlassIcon.sfSymbol('bookmark'),
        selectedIcon: const NativeLiquidGlassIcon.sfSymbol('bookmark.fill'),
        iosBadgeValue: '3',
        iosBadgeColor: _useBadgeColor ? const Color(0xFF007AFF) : null,
        iosBadgeTextColor: _useBadgeColor ? Colors.white : null,
        iconSize: _iconSize,
        selectedItemColor: _selectedColorForItem(2),
      ),
      LiquidGlassTabItem(
        label: 'Profile',
        icon: const NativeLiquidGlassIcon.sfSymbol('person'),
        selectedIcon: const NativeLiquidGlassIcon.sfSymbol('person.fill'),
        iconSize: _iconSize,
        selectedItemColor: _selectedColorForItem(3),
      ),
    ];
  }

  LiquidGlassTabItem _buildActionButton() {
    return LiquidGlassTabItem(label: 'Add', icon: const NativeLiquidGlassIcon.sfSymbol('plus'), iconSize: _iconSize);
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildTabItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassTabBar preview'),
        actions: [ThemeModeActionButton(onThemeChanged: widget.onThemeChanged)],
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A0E2D), Color(0xFF1F4A73), Color(0xFF6D4FB3), Color(0xFFF07C73)],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Selected tab: ${items[_currentIndex].label}', style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  backgroundColor: Colors.white,
                                  context: context,
                                  builder: (context) => SizedBox(
                                    height: 300,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Bottom Sheet', style: Theme.of(context).textTheme.headlineSmall),
                                          const SizedBox(height: 16),
                                          const Text('Check if the tab bar glass effect is clipped below.'),
                                          const SizedBox(height: 24),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Show Bottom Sheet'),
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Dialog'),
                                    content: const Text('Check if the tab bar glass effect is clipped behind this dialog.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: const Text('Show Dialog'),
                            ),
                          ],
                        ),
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
                            title: const Text('Show labels'),
                            value: _showLabels,
                            onChanged: (value) {
                              setState(() {
                                _showLabels = value;
                              });
                            },
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Show trailing action button'),
                            value: _showActionButton,
                            onChanged: (value) {
                              setState(() {
                                _showActionButton = value;
                              });
                            },
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Custom badge color (Saved tab)'),
                            value: _useBadgeColor,
                            onChanged: (value) {
                              setState(() {
                                _useBadgeColor = value;
                              });
                            },
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Use custom selected colors'),
                            value: _useCustomColors,
                            onChanged: (value) {
                              setState(() {
                                _useCustomColors = value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Item positioning: '),
                              const SizedBox(width: 8),
                              Expanded(
                                child: DropdownButton<LiquidGlassTabBarItemPositioning>(
                                  isExpanded: true,
                                  value: _positioning,
                                  items: const [
                                    DropdownMenuItem(value: LiquidGlassTabBarItemPositioning.automatic, child: Text('automatic')),
                                    DropdownMenuItem(value: LiquidGlassTabBarItemPositioning.fill, child: Text('fill')),
                                    DropdownMenuItem(value: LiquidGlassTabBarItemPositioning.centered, child: Text('centered')),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    setState(() {
                                      _positioning = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Icon size'),
                              Expanded(
                                child: Slider.adaptive(
                                  min: 16,
                                  max: 34,
                                  divisions: 9,
                                  value: _iconSize,
                                  label: _iconSize.toStringAsFixed(0),
                                  onChanged: (value) {
                                    setState(() {
                                      _iconSize = value;
                                    });
                                  },
                                ),
                              ),
                              Text(_iconSize.toStringAsFixed(0)),
                            ],
                          ),
                          if (_showLabels) ...[
                            Row(
                              children: [ 
                                Expanded(
                                  child: Slider.adaptive(
                                    min: 9,
                                    max: 14, 
                                    divisions: 10,
                                    value: _labelFontSize,
                                    label: _labelFontSize.toStringAsFixed(1),
                                    onChanged: (value) {
                                      setState(() {
                                        _labelFontSize = value;
                                      });
                                    },
                                  ),
                                ),
                                Text(_labelFontSize.toStringAsFixed(1)),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('Label weight: '),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButton<FontWeight>(
                                    isExpanded: true,
                                    value: _labelFontWeight,
                                    items: const [
                                      DropdownMenuItem(value: FontWeight.w400, child: Text('w400')),
                                      DropdownMenuItem(value: FontWeight.w500, child: Text('w500')),
                                      DropdownMenuItem(value: FontWeight.w600, child: Text('w600')),
                                      DropdownMenuItem(value: FontWeight.w700, child: Text('w700')),
                                    ],
                                    onChanged: (value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() {
                                        _labelFontWeight = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('Letter spacing'),
                                Expanded(
                                  child: Slider.adaptive(
                                    min: -0.5,
                                    max: 2.0,
                                    divisions: 10,
                                    value: _labelLetterSpacing,
                                    label: _labelLetterSpacing.toStringAsFixed(1),
                                    onChanged: (value) {
                                      setState(() {
                                        _labelLetterSpacing = value;
                                      });
                                    },
                                  ),
                                ),
                                Text(_labelLetterSpacing.toStringAsFixed(1)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: LiquidGlassTabBar(
          items: items,
          iosActionButton: _showActionButton ? _buildActionButton() : null,
          currentIndex: _currentIndex,
          onTabSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          onActionButtonPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Action button tapped')));
          },
          showLabels: _showLabels,
          labelTextStyle: TextStyle(fontSize: _labelFontSize, fontWeight: _labelFontWeight, letterSpacing: _labelLetterSpacing),
          iosItemPositioning: _positioning,
          iosItemSpacing: _positioning == LiquidGlassTabBarItemPositioning.centered ? 24 : null,
          iosItemWidth: _positioning == LiquidGlassTabBarItemPositioning.centered ? 72 : null,
        ),
      ),
    );
  }
}
