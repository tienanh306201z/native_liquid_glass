import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

/// Everything on one screen, over a background the glass can actually
/// sample. Used for the README hero image and as a composed demo.
class ShowcasePage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const ShowcasePage({super.key, required this.onThemeChanged});

  @override
  State<ShowcasePage> createState() => _ShowcasePageState();
}

class _ShowcasePageState extends State<ShowcasePage> {
  int _tab = 0;
  int _period = 1;
  bool _notifications = true;
  double _volume = 0.6;
  int _likes = 12;

  static const _tabs = [
    LiquidGlassTabItem(label: 'Home', icon: NativeLiquidGlassIcon.sfSymbol('house'), selectedIcon: NativeLiquidGlassIcon.sfSymbol('house.fill')),
    LiquidGlassTabItem(label: 'Explore', icon: NativeLiquidGlassIcon.sfSymbol('magnifyingglass')),
    LiquidGlassTabItem(label: 'Saved', icon: NativeLiquidGlassIcon.sfSymbol('bookmark'), selectedIcon: NativeLiquidGlassIcon.sfSymbol('bookmark.fill'), iosBadgeValue: '3'),
    LiquidGlassTabItem(label: 'Profile', icon: NativeLiquidGlassIcon.sfSymbol('person'), selectedIcon: NativeLiquidGlassIcon.sfSymbol('person.fill')),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onGlass = isDark ? Colors.white : const Color(0xFF14172B);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? const [Color(0xFF05070F), Color(0xFF13234A), Color(0xFF4A2E7A), Color(0xFF8E3B5C)]
                      : const [Color(0xFF6FB6FF), Color(0xFF9D8CFF), Color(0xFFF08CC0), Color(0xFFFFC08A)],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: LiquidGlassNavigationBar(
                    title: 'Liquid Glass',
                    brightness: Theme.of(context).brightness,
                    leadingItems: const [
                      LiquidGlassNavBarItem(id: 'back', icon: NativeLiquidGlassIcon.sfSymbol('chevron.left'), label: 'Back'),
                    ],
                    trailingItems: [
                      LiquidGlassNavBarItem(id: 'theme', icon: NativeLiquidGlassIcon.sfSymbol(isDark ? 'sun.max' : 'moon')),
                      const LiquidGlassNavBarItem(id: 'search', icon: NativeLiquidGlassIcon.sfSymbol('magnifyingglass')),
                    ],
                    onItemTapped: (id) {
                      if (id == 'back') Navigator.of(context).maybePop();
                      if (id == 'theme') widget.onThemeChanged(!isDark);
                    },
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    children: [
                      LiquidGlassContainer(
                        height: 132,
                        config: const LiquidGlassConfig(shape: LiquidGlassEffectShape.rect, cornerRadius: 28),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Real UIKit. Real glass.', style: TextStyle(color: onGlass, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
                              const SizedBox(height: 6),
                              Text('Native Liquid Glass widgets for Flutter on iOS 26+.', style: TextStyle(color: onGlass.withValues(alpha: 0.8), fontSize: 15)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: LiquidGlassButton(
                              label: 'Get started',
                              icon: const NativeLiquidGlassIcon.sfSymbol('arrow.right'),
                              style: LiquidGlassButtonStyle.prominentGlass,
                              height: 50,
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          LiquidGlassButton.icon(
                            icon: const NativeLiquidGlassIcon.sfSymbol('heart.fill'),
                            tint: const Color(0xFFFF375F),
                            size: 50,
                            onPressed: () => setState(() => _likes++),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      LiquidGlassSegmentedControl(
                        labels: const ['Day', 'Week', 'Month'],
                        selectedIndex: _period,
                        onValueChanged: (i) => setState(() => _period = i),
                      ),
                      const SizedBox(height: 18),
                      LiquidGlassContainer(
                        height: 64,
                        config: const LiquidGlassConfig(shape: LiquidGlassEffectShape.capsule),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Row(
                            children: [
                              Expanded(child: Text('Notifications', style: TextStyle(color: onGlass, fontSize: 17, fontWeight: FontWeight.w600))),
                              SizedBox(
                                width: 64,
                                child: LiquidGlassToggle(value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      LiquidGlassContainer(
                        height: 64,
                        config: const LiquidGlassConfig(shape: LiquidGlassEffectShape.capsule),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          child: Row(
                            children: [
                              Icon(Icons.volume_up_rounded, color: onGlass),
                              const SizedBox(width: 12),
                              Expanded(child: LiquidGlassSlider(value: _volume, onChanged: (v) => setState(() => _volume = v))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      LiquidGlassButtonGroup(
                        spacing: 10,
                        buttons: [
                          LiquidGlassButtonData(label: 'Share', icon: const NativeLiquidGlassIcon.sfSymbol('square.and.arrow.up'), onPressed: () {}),
                          LiquidGlassButtonData(label: 'Edit', icon: const NativeLiquidGlassIcon.sfSymbol('pencil'), onPressed: () {}),
                          LiquidGlassButtonData(label: '$_likes', icon: const NativeLiquidGlassIcon.sfSymbol('heart'), onPressed: () => setState(() => _likes++)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: LiquidGlassTabBar(
                  items: _tabs,
                  iosActionButton: const LiquidGlassTabItem(label: 'Add', icon: NativeLiquidGlassIcon.sfSymbol('plus')),
                  currentIndex: _tab,
                  onTabSelected: (i) => setState(() => _tab = i),
                  onActionButtonPressed: () {},
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
