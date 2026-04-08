import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassSearchScaffoldPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassSearchScaffoldPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassSearchScaffoldPreviewPage> createState() => _LiquidGlassSearchScaffoldPreviewPageState();
}

class _LiquidGlassSearchScaffoldPreviewPageState extends State<LiquidGlassSearchScaffoldPreviewPage> {
  int _selectedIndex = 0;
  bool _searchEnabled = true;
  bool _useSelectedItemColor = false;
  bool _showLabels = true;
  bool _useLabelTextStyle = false;
  bool _useBadge = false;
  bool _useBadgeColor = false;
  bool _useActionButton = true;
  String _searchQuery = '';
  String _lastAction = '';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassSearchScaffold preview'),
        actions: [ThemeModeActionButton(onThemeChanged: widget.onThemeChanged)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LiquidGlassSearchScaffold(
                  selectedIndex: _selectedIndex,
                  searchEnabled: _searchEnabled,
                  searchHint: 'Search items…',
                  showLabels: _showLabels,
                  selectedItemColor: _useSelectedItemColor ? colorScheme.secondary : null,
                  labelTextStyle: _useLabelTextStyle ? const TextStyle(fontSize: 11, fontWeight: FontWeight.w600) : null,
                  iosActionButton: _useActionButton ? const LiquidGlassTabItem(icon: NativeLiquidGlassIcon.sfSymbol('plus.circle.fill'), label: 'Add') : null,
                  onActionButtonPressed: () => setState(() {
                    _lastAction = 'Add tapped!';
                  }),
                  onTabChanged: (i) => setState(() => _selectedIndex = i),
                  onSearchChanged: (q) => setState(() => _searchQuery = q),
                  tabs: [
                    LiquidGlassTabItem(
                      icon: const NativeLiquidGlassIcon.sfSymbol('house'),
                      selectedIcon: const NativeLiquidGlassIcon.sfSymbol('house.fill'),
                      label: 'Home',
                      iosBadgeValue: _useBadge ? '3' : null,
                      iosBadgeColor: _useBadgeColor ? const Color(0xFF007AFF) : null,
                      iosBadgeTextColor: _useBadgeColor ? Colors.red : null,
                    ),
                    LiquidGlassTabItem(
                      icon: const NativeLiquidGlassIcon.sfSymbol('heart'),
                      selectedIcon: const NativeLiquidGlassIcon.sfSymbol('heart.fill'),
                      label: 'Favorites',
                      iosShowBadge: _useBadge,
                      iosBadgeColor: _useBadgeColor ? const Color(0xFF34C759) : null,
                    ),
                    LiquidGlassTabItem(
                      icon: const NativeLiquidGlassIcon.sfSymbol('person'),
                      selectedIcon: const NativeLiquidGlassIcon.sfSymbol('person.fill'),
                      label: 'Profile',
                    ),
                  ],
                  tabBuilders: [
                    (ctx) => _TabContent(label: 'Home', icon: Icons.home_rounded, searchQuery: _searchQuery, action: _lastAction),
                    (ctx) => _TabContent(label: 'Favorites', icon: Icons.favorite_rounded, searchQuery: _searchQuery, action: _lastAction),
                    (ctx) => _TabContent(label: 'Profile', icon: Icons.person_rounded, searchQuery: _searchQuery, action: _lastAction),
                  ],
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
                        title: const Text('Search enabled'),
                        value: _searchEnabled,
                        onChanged: (v) => setState(() => _searchEnabled = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Show labels'),
                        value: _showLabels,
                        onChanged: (v) => setState(() => _showLabels = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom selected item color'),
                        value: _useSelectedItemColor,
                        onChanged: (v) => setState(() => _useSelectedItemColor = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom label text style'),
                        value: _useLabelTextStyle,
                        onChanged: (v) => setState(() => _useLabelTextStyle = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Badge on Home tab (count) & Favorites (dot)'),
                        value: _useBadge,
                        onChanged: (v) => setState(() => _useBadge = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom badge colors'),
                        value: _useBadgeColor,
                        onChanged: _useBadge ? (v) => setState(() => _useBadgeColor = v) : null,
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Action button (Add)'),
                        value: _useActionButton,
                        onChanged: (v) => setState(() => _useActionButton = v),
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

class _TabContent extends StatelessWidget {
  final String label;
  final IconData icon;
  final String searchQuery;
  final String action;

  const _TabContent({required this.label, required this.icon, required this.searchQuery, this.action = ''});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 12),
        Text(label, style: Theme.of(context).textTheme.titleLarge),
        if (searchQuery.isNotEmpty) ...[const SizedBox(height: 8), Text('Query: "$searchQuery"', style: Theme.of(context).textTheme.bodyMedium)],
        if (action.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(action, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary)),
        ],
      ],
    );
  }
}
