import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

void _noop(int _) {}

void main() {
  testWidgets('tab bar returns empty fallback on non-iOS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: LiquidGlassTabBar(
                items: const [
                  LiquidGlassTabItem(icon: NativeLiquidGlassIcon.iconData(Icons.home_outlined), label: 'Home'),
                  LiquidGlassTabItem(icon: NativeLiquidGlassIcon.iconData(Icons.search_rounded), label: 'Search'),
                ],
                currentIndex: 0,
                onTabSelected: _noop,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsNothing);
    expect(find.text('Search'), findsNothing);
  });

  test('device qualification utility returns false on non-iOS test runtime', () {
    final isQualified = NativeLiquidGlassUtils.supportsLiquidGlass;
    expect(isQualified, isFalse);
  });

  testWidgets('tab bar remains empty with showLabels false on non-iOS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: LiquidGlassTabBar(
                items: const [
                  LiquidGlassTabItem(icon: NativeLiquidGlassIcon.iconData(Icons.home_outlined), label: 'Home'),
                  LiquidGlassTabItem(icon: NativeLiquidGlassIcon.iconData(Icons.search_rounded), label: 'Search'),
                ],
                currentIndex: 0,
                onTabSelected: _noop,
                showLabels: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsNothing);
    expect(find.text('Search'), findsNothing);
  });

  testWidgets('tab bar accepts iOS action button config', (tester) async {
    var actionTapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: LiquidGlassTabBar(
                items: const [
                  LiquidGlassTabItem(icon: NativeLiquidGlassIcon.iconData(Icons.home_outlined), label: 'Home'),
                  LiquidGlassTabItem(icon: NativeLiquidGlassIcon.iconData(Icons.search_rounded), label: 'Search'),
                ],
                iosActionButton: const LiquidGlassTabItem(icon: NativeLiquidGlassIcon.sfSymbol('plus'), label: 'Add'),
                currentIndex: 0,
                onTabSelected: _noop,
                onActionButtonPressed: () {
                  actionTapCount++;
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsNothing);
    expect(find.text('Search'), findsNothing);
    expect(actionTapCount, 0);
  });

  // Regression coverage for the native default-tab notification leak fixed
  // in `LiquidGlassNativeTabBarControllerView.configureTabBarController`
  // (iOS `RunnerTests`): `tabBarController.delegate = self` was assigned
  // before tabs/selection were configured, so the UITab API's synchronous
  // delegate callback on programmatic selection leaked a spurious
  // `onTabSelected(0)` to Flutter *before* the real `currentIndex` was
  // applied. Flutter's `LiquidGlassTabBar.reassemble()` (called on every hot
  // reload) unconditionally rebuilds the native tabs payload, which forces
  // the platform view to be torn down and recreated — replaying that setup
  // sequence and re-leaking the spurious notification. These tests exercise
  // the Dart side of that reload path: `flutter test` runs on a non-iOS host
  // so `NativeLiquidGlassUtils.supportsLiquidGlass` is always false here and
  // the widget never actually creates the `UiKitView`/native channel (see
  // the "no Flutter fallback" tests above) — so `onTabSelected` cannot be
  // invoked at all in this environment. What *is* verifiable here is that
  // `reassemble()`, `didUpdateWidget`, and a non-zero/last-tab
  // `currentIndex` never crash and never call `onTabSelected` on their own.
  group('LiquidGlassTabBar hot-reload / reassemble regression coverage', () {
    Widget buildTabBar({
      required int currentIndex,
      required ValueChanged<int> onTabSelected,
      int itemCount = 3,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: LiquidGlassTabBar(
                items: List.generate(
                  itemCount,
                  (i) => LiquidGlassTabItem(
                    icon: NativeLiquidGlassIcon.iconData(Icons.home_outlined),
                    label: 'Tab $i',
                  ),
                ),
                currentIndex: currentIndex,
                onTabSelected: onTabSelected,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders empty fallback with a non-zero currentIndex, never fires onTabSelected', (tester) async {
      var selectedCount = 0;

      await tester.pumpWidget(
        buildTabBar(currentIndex: 2, onTabSelected: (_) => selectedCount++),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Tab 0'), findsNothing);
      expect(find.text('Tab 2'), findsNothing);
      expect(selectedCount, 0, reason: 'no native platform view exists on this host; nothing should invoke onTabSelected');
    });

    testWidgets('currentIndex pinned to the last tab never leaks an index-0 callback', (tester) async {
      // Mirrors the native regression case: currentIndex at the last tab
      // makes a leaked "auto-selected tab 0" notification unambiguous from
      // the real selection.
      final observedIndices = <int>[];

      await tester.pumpWidget(
        buildTabBar(currentIndex: 3, itemCount: 4, onTabSelected: observedIndices.add),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(observedIndices, isEmpty);
      expect(observedIndices, isNot(contains(0)));
    });

    // NOTE: an earlier version of this coverage drove this via
    // `tester.binding.reassembleApplication()` (the literal hot-reload
    // hook). That call deadlocks under `flutter test`'s
    // `AutomatedTestWidgetsFlutterBinding` on this Flutter version — it
    // never returns even after `pumpAndSettle()`, hanging each test for the
    // full 10-minute framework timeout. Tearing down and remounting the
    // widget (what a hot reload's new `ValueKey` on the `UiKitView`
    // actually causes: `dispose()` then a fresh `initState()` on a new
    // `_LiquidGlassTabBarState`) is both safe to run here and the more
    // accurate simulation of the production mechanism described at the top
    // of this group.
    testWidgets('tearing down and remounting the tab bar (as hot reload does) never fires onTabSelected', (tester) async {
      final observedIndices = <int>[];

      await tester.pumpWidget(
        buildTabBar(currentIndex: 2, onTabSelected: observedIndices.add),
      );
      await tester.pumpAndSettle();
      expect(observedIndices, isEmpty);

      // Unmount (disposes `_LiquidGlassTabBarState`) then remount a brand
      // new instance with the same `currentIndex` — analogous to Flutter
      // swapping in a new `ValueKey` on hot reload and recreating the
      // platform view from scratch.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await tester.pumpWidget(
        buildTabBar(currentIndex: 2, onTabSelected: observedIndices.add),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        observedIndices, isEmpty,
        reason: 'remounting after teardown must not synthesize a tab selection on its own',
      );
    });

    testWidgets('repeated teardown/remount cycles stay stable across multiple simulated hot reloads', (tester) async {
      final observedIndices = <int>[];

      await tester.pumpWidget(
        buildTabBar(currentIndex: 1, onTabSelected: observedIndices.add),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
        await tester.pumpWidget(
          buildTabBar(currentIndex: 1, onTabSelected: observedIndices.add),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'teardown/remount cycle #$i must not throw');
      }

      expect(observedIndices, isEmpty);
      expect(find.text('Tab 1'), findsNothing);
    });

    testWidgets('changing currentIndex via didUpdateWidget does not crash without a live native channel', (tester) async {
      final observedIndices = <int>[];

      await tester.pumpWidget(
        buildTabBar(currentIndex: 0, onTabSelected: observedIndices.add),
      );
      await tester.pumpAndSettle();

      // Rebuild with a new `currentIndex`, exercising
      // `_LiquidGlassTabBarState.didUpdateWidget`'s
      // `_syncNativeSelectedIndex` branch, which is a no-op when
      // `_nativeChannel` was never established (fallback path).
      await tester.pumpWidget(
        buildTabBar(currentIndex: 2, onTabSelected: observedIndices.add),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(observedIndices, isEmpty);
    });
  });

  testWidgets('tab items accept per-item icon size and selected color', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: LiquidGlassTabBar(
                items: const [
                  LiquidGlassTabItem(
                    icon: NativeLiquidGlassIcon.iconData(Icons.home_outlined),
                    label: 'Home',
                    iconSize: 22,
                    selectedItemColor: Color(0xFFFF6B6B),
                  ),
                  LiquidGlassTabItem(
                    icon: NativeLiquidGlassIcon.iconData(Icons.search_rounded),
                    label: 'Search',
                    iconSize: 28,
                    selectedItemColor: Color(0xFF4CD964),
                  ),
                ],
                currentIndex: 0,
                onTabSelected: _noop,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsNothing);
    expect(find.text('Search'), findsNothing);
  });

  // The widgets in this package render native platform views and have no
  // Flutter fallback: off iOS 26+ they return an empty `SizedBox`. The
  // tests below pin that contract down, because it's easy to reintroduce a
  // fallback by accident and easy to document one that doesn't exist —
  // both docstrings claiming a `PopupMenuButton` / `FilledButton` fallback
  // have been wrong at some point in this package's history.

  testWidgets('liquid glass button renders nothing on non-iOS', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: LiquidGlassButton(
              label: 'Continue',
              onPressed: () {
                tapCount++;
              },
              icon: const NativeLiquidGlassIcon.iconData(Icons.arrow_forward_rounded),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    expect(tapCount, 0);
  });

  testWidgets('liquid glass icon button renders nothing on non-iOS', (tester) async {
    var tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: LiquidGlassButton.icon(
              onPressed: () {
                tapCount++;
              },
              icon: const NativeLiquidGlassIcon.iconData(Icons.favorite_border_rounded),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(tapCount, 0);
  });

  testWidgets('liquid glass menu renders nothing on non-iOS', (tester) async {
    var selectedCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: LiquidGlassMenu(
              label: 'Actions',
              items: const [
                LiquidGlassMenuItem(id: 'edit', title: 'Edit'),
                LiquidGlassMenuItem(id: 'delete', title: 'Delete', isDestructive: true),
              ],
              onItemSelected: (_) {
                selectedCount++;
              },
            ),
          ),
        ),
      ),
    );

    // The docstring used to promise a `PopupMenuButton` fallback here.
    expect(find.text('Actions'), findsNothing);
    expect(find.byType(PopupMenuButton<dynamic>), findsNothing);
    expect(selectedCount, 0);
  });

  test('liquid glass button accepts expanded icon and color parameters', () {
    final button = LiquidGlassButton(
      label: 'Continue',
      onPressed: () {},
      icon: const NativeLiquidGlassIcon.asset('assets/icons/continue.svg'),
      iconColor: const Color(0xFFFF6B6B),
      foregroundColor: const Color(0xFF111111),
      tint: const Color(0xFF4CD964),
      imagePadding: 12,
      interactive: true,
    );

    expect(button.icon?.assetPath, 'assets/icons/continue.svg');
    expect(button.iconColor, const Color(0xFFFF6B6B));
    expect(button.foregroundColor, const Color(0xFF111111));
    expect(button.tint, const Color(0xFF4CD964));
    expect(button.imagePadding, 12);
    expect(button.interactive, isTrue);
    expect(button.width, isNull);
    expect(button.height, isNull);
  });

  testWidgets('liquid glass button takes no layout space on non-iOS', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: LiquidGlassButton(label: 'Go', onPressed: () {}),
          ),
        ),
      ),
    );

    // Without a fallback there is no intrinsic size to wrap; the widget
    // must collapse rather than reserve space for a button that isn't
    // there. `Align` gives it a loose constraint so a non-zero size here
    // would mean something is actually being laid out.
    expect(tester.getSize(find.byType(LiquidGlassButton)), Size.zero);
  });

  test('liquid glass icon button retains an SF Symbol source', () {
    const button = LiquidGlassButton.icon(
      onPressed: null,
      icon: NativeLiquidGlassIcon.sfSymbol('heart'),
      iconColor: Color(0xFFFF375F),
    );

    expect(button.icon?.sfSymbolName, 'heart');
    expect(button.icon?.iconDataValue, isNull);
    expect(button.icon?.assetPath, isNull);
    expect(button.iconColor, const Color(0xFFFF375F));
  });

  testWidgets('liquid glass button in its disabled state renders nothing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              children: [
                LiquidGlassButton(label: 'Continue', onPressed: null, icon: const NativeLiquidGlassIcon.iconData(Icons.arrow_forward_rounded)),
                LiquidGlassButton.icon(onPressed: null, icon: const NativeLiquidGlassIcon.iconData(Icons.favorite_border_rounded)),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Continue'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
  });
}
