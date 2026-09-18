# native_liquid_glass

[![pub package](https://img.shields.io/pub/v/native_liquid_glass.svg)](https://pub.dev/packages/native_liquid_glass)
[![pub points](https://img.shields.io/pub/points/native_liquid_glass)](https://pub.dev/packages/native_liquid_glass/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![platform: iOS 26+](https://img.shields.io/badge/platform-iOS%2026%2B-lightgrey)

**Apple's Liquid Glass, in Flutter, from the real UIKit controls.** Every widget in this package hosts a native `UIView` — `UITabBarController`, `UINavigationBar`, `UIButton`, `UISwitch`… — through a Flutter platform view, so on iOS 26+ you get the exact material, motion and behaviour Apple ships, not a shader that imitates it.

<table>
  <tr>
    <td align="center"><img src="https://raw.githubusercontent.com/tienanh306201z/native_liquid_glass/main/doc/screenshots/Showcase-light.png" alt="Showcase-light" width="320"><br><sub>Light theme</sub></td>
    <td align="center"><img src="https://raw.githubusercontent.com/tienanh306201z/native_liquid_glass/main/doc/screenshots/Showcase-dark.png" alt="Showcase-dark" width="320"><br><sub>Dark theme</sub></td>
  </tr>
</table>

<sub>Every control above is a native UIKit view. Run <code>example/</code> → <em>Showcase</em> to try it.</sub>

## Why native?

- **It is the real thing.** The glass samples what is behind it, refracts, and reacts to touch exactly like the system bars — because it *is* a system bar. When Apple tunes the material in a point release, your app picks it up for free.
- **Accessibility and behaviour come along.** VoiceOver labels, Dynamic Type, haptics, the tab bar's iOS 27 split action button, sheet detents, menu physics: all UIKit, nothing re-implemented.
- **Flutter still owns the app.** State, navigation and pages stay in Dart; the native views are chrome. Selection, taps and values come back through callbacks like any Flutter widget.

**What it costs — read this before you adopt it**

- **iOS 26+ only for the glass look.** On older iOS the same UIKit controls render with their standard system appearance. On Android, web and desktop the widgets render **nothing** (an empty `SizedBox`), so gate them with [`NativeLiquidGlassUtils.supportsLiquidGlass`](#platform-support-and-fallbacks) and provide your own widget elsewhere.
- **Platform views are not free.** Hosting a `UIView` inside Flutter has a whole-screen compositing cost. One bar or a couple of controls per screen is fine; one per list row is not. See [Performance](#performance).
- **Glass over Flutter overlays needs care.** A native view sits above Flutter's surface. The package hides glass automatically around route pushes and popups; single-route transitions (tab switches) need the manual hook. See [Overlay suppression](#overlay-suppression).

## Quick start

```yaml
dependencies:
  native_liquid_glass: ^0.3.0
```

```dart
import 'package:native_liquid_glass/native_liquid_glass.dart';

MaterialApp(
  // Fades glass out under bottom sheets, dialogs and other popup routes.
  navigatorObservers: [LiquidGlassNavigatorObserver()],
  home: const HomePage(),
);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: const [FeedPage(), SearchPage(), ProfilePage()]),
      bottomNavigationBar: NativeLiquidGlassUtils.supportsLiquidGlass
          ? LiquidGlassTabBar(
              items: const [
                LiquidGlassTabItem(label: 'Feed', icon: NativeLiquidGlassIcon.sfSymbol('house')),
                LiquidGlassTabItem(label: 'Search', icon: NativeLiquidGlassIcon.sfSymbol('magnifyingglass')),
                LiquidGlassTabItem(label: 'Profile', icon: NativeLiquidGlassIcon.sfSymbol('person')),
              ],
              currentIndex: _index,
              onTabSelected: (i) => setState(() => _index = i),
            )
          : NavigationBar(/* your non-iOS bar */),
    );
  }
}
```

**Requirements:** Flutter 3.41.2+, iOS/iPadOS 26.0+ for Liquid Glass (older iOS falls back to standard system styling). Works with both **CocoaPods** (default) and **Swift Package Manager** (`ios/native_liquid_glass/Package.swift`, Flutter 3.19+). No native setup steps.

## Widgets

| Widget | Native UIKit component |
|---|---|
| [`LiquidGlassTabBar`](#liquidglasstabbar) | `UITabBarController` |
| [`LiquidGlassButton`](#liquidglassbutton) | `UIButton` with glass configurations |
| [`LiquidGlassButtonGroup`](#liquidglassbuttongroup) | Row/column of `UIButton`s with unified glass blending |
| [`LiquidGlassContainer`](#liquidglasscontainer) | Glass-effect `UIView` with custom shapes, animated transitions, and interactive press |
| [`LiquidGlassNavigationBar`](#liquidglassnavigationbar) | `UINavigationBar` |
| [`LiquidGlassToolbar`](#liquidglasstoolbar) | `UIToolbar` |
| [`LiquidGlassSearchBar`](#search) | Expandable `UISearchTextField` |
| [`LiquidGlassSearchScaffold`](#search) | Full-screen scaffold with native tab bar + `UISearchTab` |
| [`LiquidGlassToggle`](#controls) | `UISwitch` |
| [`LiquidGlassSlider`](#controls) | `UISlider` |
| [`LiquidGlassStepper`](#controls) | `UIStepper` |
| [`LiquidGlassSegmentedControl`](#controls) | `UISegmentedControl` |
| [`LiquidGlassColorPicker`](#pickers) | `UIColorWell` |
| [`LiquidGlassDatePicker`](#pickers) | `UIDatePicker` |
| [`LiquidGlassMenu`](#context-menu) | `UIButton` + `UIMenu` context menu |
| [`LiquidGlassSheet`](#modals) | `UISheetPresentationController` |
| [`LiquidGlassAlert`](#modals) | `UIAlertController` |
| [`LiquidGlassPopover`](#modals) | `UIPopoverPresentationController` |
| [`LiquidGlassActivityIndicator`](#indicators) | `UIActivityIndicatorView` |
| [`LiquidGlassProgressView`](#indicators) | `UIProgressView` |

<table>
  <tr>
    <td align="center"><img src="https://raw.githubusercontent.com/tienanh306201z/native_liquid_glass/main/doc/screenshots/gallery/TabBar.png" alt="gallery/TabBar" width="300"><br><sub><a href="#liquidglasstabbar">LiquidGlassTabBar</a> — split action button on iOS 26/27</sub></td>
    <td align="center"><img src="https://raw.githubusercontent.com/tienanh306201z/native_liquid_glass/main/doc/screenshots/gallery/NavigationBar.png" alt="gallery/NavigationBar" width="300"><br><sub><a href="#liquidglassnavigationbar">LiquidGlassNavigationBar</a></sub></td>
    <td align="center"><img src="https://raw.githubusercontent.com/tienanh306201z/native_liquid_glass/main/doc/screenshots/gallery/Toolbar.png" alt="gallery/Toolbar" width="300"><br><sub><a href="#liquidglasstoolbar">LiquidGlassToolbar</a></sub></td>
  </tr>
  <tr>
    <td align="center"><img src="https://raw.githubusercontent.com/tienanh306201z/native_liquid_glass/main/doc/screenshots/gallery/MenuOpen.png" alt="gallery/MenuOpen" width="300"><br><sub><a href="#context-menu">LiquidGlassMenu</a></sub></td>
    <td align="center"><img src="https://raw.githubusercontent.com/tienanh306201z/native_liquid_glass/main/doc/screenshots/gallery/SheetOpen.png" alt="gallery/SheetOpen" width="300"><br><sub><a href="#modals">LiquidGlassSheet</a></sub></td>
    <td align="center"><img src="https://raw.githubusercontent.com/tienanh306201z/native_liquid_glass/main/doc/screenshots/gallery/AlertOpen.png" alt="gallery/AlertOpen" width="300"><br><sub><a href="#modals">LiquidGlassAlert</a></sub></td>
  </tr>
  <tr>
    <td align="center"><img src="https://raw.githubusercontent.com/tienanh306201z/native_liquid_glass/main/doc/screenshots/gallery/SegmentedControl.png" alt="gallery/SegmentedControl" width="300"><br><sub><a href="#controls">LiquidGlassSegmentedControl</a></sub></td>
    <td align="center"><img src="https://raw.githubusercontent.com/tienanh306201z/native_liquid_glass/main/doc/screenshots/gallery/DatePicker.png" alt="gallery/DatePicker" width="300"><br><sub><a href="#pickers">LiquidGlassDatePicker</a></sub></td>
    <td align="center"><img src="https://raw.githubusercontent.com/tienanh306201z/native_liquid_glass/main/doc/screenshots/gallery/ColorPicker.png" alt="gallery/ColorPicker" width="300"><br><sub><a href="#pickers">LiquidGlassColorPicker</a></sub></td>
  </tr>
</table>

## Usage

All snippets below are lifted from the `example/` app, which has a live preview page per widget.

### LiquidGlassTabBar

```dart
LiquidGlassTabBar(
  items: const [
    LiquidGlassTabItem(
      label: 'Home',
      icon: NativeLiquidGlassIcon.sfSymbol('house'),
      selectedIcon: NativeLiquidGlassIcon.sfSymbol('house.fill'),
      selectedItemColor: Color(0xFF007AFF),
      iosBadgeValue: '3',
    ),
    LiquidGlassTabItem(
      label: 'Search',
      icon: NativeLiquidGlassIcon.sfSymbol('magnifyingglass'),
    ),
    LiquidGlassTabItem(
      label: 'Profile',
      icon: NativeLiquidGlassIcon.iconData(Icons.person_outline),
      selectedIcon: NativeLiquidGlassIcon.iconData(Icons.person),
    ),
  ],
  currentIndex: _selectedIndex,
  onTabSelected: (index) => setState(() => _selectedIndex = index),
  height: 72,
  selectedItemColor: Colors.blue,
  labelTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
)
```

### LiquidGlassButton

```dart
// Text button
LiquidGlassButton(
  label: 'Continue',
  onPressed: () {},
  icon: NativeLiquidGlassIcon.sfSymbol('arrow.right'),
  style: LiquidGlassButtonStyle.prominentGlass,
)

// Icon-only button
LiquidGlassButton.icon(
  onPressed: () {},
  icon: NativeLiquidGlassIcon.sfSymbol('heart.fill'),
  tint: const Color(0xFFFF375F),
  size: 50,
)
```

### LiquidGlassButtonGroup

```dart
LiquidGlassButtonGroup(
  buttons: [
    LiquidGlassButtonData(
      label: 'Bold',
      icon: NativeLiquidGlassIcon.sfSymbol('bold'),
      onPressed: () {},
    ),
    LiquidGlassButtonData(
      label: 'Italic',
      icon: NativeLiquidGlassIcon.sfSymbol('italic'),
      onPressed: () {},
    ),
  ],
  axis: Axis.horizontal,
  spacing: 8,
)
```

### LiquidGlassContainer

```dart
// Basic container
LiquidGlassContainer(
  config: const LiquidGlassConfig(
    effect: LiquidGlassEffect.regular,
    shape: LiquidGlassEffectShape.capsule,
    tint: Color(0xFF007AFF),
    interactive: true,
  ),
  width: 200,
  height: 80,
  onTap: () => print('tapped'),
  child: const Center(child: Text('Glass!')),
)

// Wraps child when width/height omitted (like Flutter Container)
LiquidGlassContainer(
  config: const LiquidGlassConfig(shape: LiquidGlassEffectShape.rect),
  child: Padding(
    padding: EdgeInsets.all(20),
    child: Text('Wraps content'),
  ),
)

// Custom SVG shape (hand-built)
LiquidGlassContainer(
  config: LiquidGlassConfig(
    shape: LiquidGlassEffectShape.custom,
    customPath: [
      LiquidGlassPathOp.moveTo(50, 0),
      LiquidGlassPathOp.lineTo(150, 0),
      LiquidGlassPathOp.lineTo(200, 60),
      LiquidGlassPathOp.lineTo(150, 120),
      LiquidGlassPathOp.lineTo(50, 120),
      LiquidGlassPathOp.lineTo(0, 60),
      LiquidGlassPathOp.close(),
    ],
    customPathSize: Size(200, 120),
  ),
  width: 200,
  height: 120,
  child: const Center(child: Text('Diamond')),
)

// Custom shape from an SVG path string (`d` attribute of <path>)
LiquidGlassContainer(
  config: LiquidGlassConfig(
    shape: LiquidGlassEffectShape.custom,
    customPath: 'M50 0 L150 0 L200 60 L150 120 L50 120 L0 60 Z'
        .toLiquidGlassPath(),
    customPathSize: const Size(200, 120),
  ),
  width: 200,
  height: 120,
  child: const Center(child: Text('Diamond')),
)

// Animated transitions between shapes/effects
LiquidGlassContainer(
  config: LiquidGlassConfig(shape: _currentShape),
  animateChanges: true, // spring transition on config changes
  child: myContent,
)
```

### LiquidGlassNavigationBar

```dart
LiquidGlassNavigationBar(
  title: 'Settings',
  leadingItems: const [
    LiquidGlassNavBarItem(
      id: 'back',
      icon: NativeLiquidGlassIcon.sfSymbol('chevron.left'),
      label: 'Back',
    ),
  ],
  trailingItems: const [LiquidGlassNavBarItem(id: 'done', label: 'Done')],
  // Optional. Null (default) follows the device appearance; pass the app
  // theme's brightness if your app drives its own ThemeMode.
  brightness: Theme.of(context).brightness,
  onItemTapped: (id) {},
)
```

### LiquidGlassToolbar

```dart
LiquidGlassToolbar(
  items: const [
    LiquidGlassToolbarItem(id: 'share', icon: NativeLiquidGlassIcon.sfSymbol('square.and.arrow.up')),
    LiquidGlassToolbarSpacer(),
    LiquidGlassToolbarItem(id: 'done', label: 'Done'),
  ],
  onItemTapped: (id) {},
)
```

### Controls

```dart
// Toggle
LiquidGlassToggle(value: _isOn, onChanged: (v) => setState(() => _isOn = v))

// Slider
LiquidGlassSlider(value: _volume, min: 0, max: 1, onChanged: (v) => setState(() => _volume = v))

// Stepper
LiquidGlassStepper(value: _count, min: 0, max: 10, onChanged: (v) => setState(() => _count = v))

// Segmented control
LiquidGlassSegmentedControl(
  labels: const ['Day', 'Week', 'Month'],
  selectedIndex: _period,
  onValueChanged: (i) => setState(() => _period = i),
)
```

### Search

```dart
LiquidGlassSearchBar(
  placeholder: 'Search',
  expandable: true,
  onChanged: (query) {},
  onSubmitted: (query) {},
)
```

`LiquidGlassSearchScaffold` wraps a native tab bar with an inline `UISearchTab` for full-screen search layouts; see `example/lib/pages/liquid_glass_search_scaffold_preview_page.dart`.

### Pickers

```dart
LiquidGlassColorPicker(
  selectedColor: _selectedColor,
  onColorChanged: (color) => setState(() => _selectedColor = color),
)

LiquidGlassDatePicker(
  mode: LiquidGlassDatePickerMode.date,
  initialDate: DateTime.now(),
  onDateChanged: (date) {},
)
```

### Context Menu

```dart
LiquidGlassMenu(
  items: const [
    LiquidGlassMenuItem(
      id: 'copy',
      title: 'Copy',
      icon: NativeLiquidGlassIcon.sfSymbol('doc.on.doc'),
    ),
    LiquidGlassMenuItem(id: 'delete', title: 'Delete', isDestructive: true),
  ],
  onItemSelected: (id) {},
  label: 'Actions',
)
```

The trigger is a plain system `UIButton`; the Liquid Glass look belongs to the system menu popup that UIKit presents. Use **one trigger per screen** — multiple instances (e.g. one per `ListView` row) interfere with each other, because the native menu interaction competes with Flutter's gesture arena ([#11](https://github.com/tienanh306201z/native_liquid_glass/issues/11)). For per-row menus, use `PopupMenuButton` or `CupertinoContextMenu`.

### Modals

```dart
// Alert
final actionId = await LiquidGlassAlert.show(
  context: context,
  title: 'Delete?',
  message: 'This cannot be undone.',
  actions: [
    const LiquidGlassAlertAction(id: 'delete', title: 'Delete', isDestructive: true),
    const LiquidGlassAlertAction(id: 'cancel', title: 'Cancel', isCancel: true),
  ],
);

// Sheet
LiquidGlassSheet.show(
  context: context,
  title: 'Options',
  detents: [LiquidGlassSheetDetent.medium],
);

// Popover
LiquidGlassPopover.show(
  context: context,
  builder: (_) => const Text('Popover content'),
  anchorRect: Offset.zero & const Size(50, 50),
);
```

### Indicators

```dart
LiquidGlassActivityIndicator(animating: _isLoading)

LiquidGlassProgressView(progress: _uploadProgress, progressTintColor: Colors.blue)
```

## Icons

All icon-bearing widgets accept `NativeLiquidGlassIcon`, which supports three sources:

```dart
NativeLiquidGlassIcon.sfSymbol('star.fill')    // Native SF Symbol (preferred on iOS)
NativeLiquidGlassIcon.iconData(Icons.star)      // Flutter IconData (PNG-encoded for iOS)
NativeLiquidGlassIcon.asset('assets/star.png')  // App bundle asset (PNG or SVG)
```

On iOS, source resolution priority is **asset → IconData → SF Symbol**.

## Things to know

### Platform support and fallbacks

- **iOS 26+**: full Liquid Glass.
- **iOS < 26**: the same UIKit controls with their standard system appearance — functional, just not glass.
- **Android / web / desktop**: the widgets render an empty `SizedBox` and take no layout space. Branch on the qualification check and supply your own widget:

```dart
if (NativeLiquidGlassUtils.supportsLiquidGlass) {
  // Running on iOS 26+ — full Liquid Glass behaviour active.
}
```

### Overlay suppression

Native glass platform views sit above Flutter's rendering surface. When Flutter shows overlays (`showModalBottomSheet`, `showDialog`, page transitions), the glass can bleed through.

This is handled **automatically** — every glass widget hides itself when its route is no longer current and restores when it is. Glass items _inside_ the overlay stay visible. No setup required.

For custom overlays that don't go through the Navigator, use the manual API:

```dart
NativeLiquidGlassLifecycle.suppressGlassEffects();
await showMyCustomOverlay();
NativeLiquidGlassLifecycle.unsuppressGlassEffects();
```

#### Transitions that don't push a route

The automatic path keys off `ModalRoute.of(context).isCurrent`, so it covers route pushes and popup routes — but **not** transitions that happen inside a single route. Switching tabs with an `IndexedStack` or a `TabBarView` keeps the same route, so nothing fires, and the glass material can flash a flat dark tone for a frame: it samples the content behind it, and mid-transition Flutter's surface isn't readable.

Wrap those transitions manually:

```dart
void _onTabChanged(int index) async {
  await NativeLiquidGlassLifecycle.suppressGlassEffects();
  setState(() => _index = index);
  await Future<void>.delayed(_transitionDuration);
  await NativeLiquidGlassLifecycle.unsuppressGlassEffects();
}
```

This trades the flash for a fade, which reads far better but does not eliminate the underlying limitation — the glass is a real `UIView` composited above Flutter's Metal layer, and the plugin cannot control what that layer exposes mid-transition.

### Theme brightness

Native views resolve their colors against the **device** appearance, like any UIKit control. `LiquidGlassTabBar` always follows the Flutter theme instead. `LiquidGlassNavigationBar` follows the device by default and can be pinned to the app theme with `brightness: Theme.of(context).brightness` — do that if your app drives its own `ThemeMode`, or a light app on a dark device gets a white title on a light page.

### Performance

Every widget in this package is a real `UIView` hosted through Flutter's `UiKitView`. That is what makes the glass genuinely native, and it is also a cost that a Flutter-drawn widget does not have:

- **Compositing.** Flutter cannot draw a native view into its own surface. While a platform view is on screen, Flutter splits its output around it and keeps its frames in step with UIKit's view hierarchy on the main thread, so rasterization no longer runs fully in parallel with your Dart and UIKit work. This affects the **whole screen** for as long as any platform view is visible, not only the platform view itself.
- **Overlay surfaces.** Any Flutter content painted *on top of* a platform view (later in paint order and overlapping its rect) forces an extra overlay surface. Keep glass views last in the paint order — `Scaffold.bottomNavigationBar`, or the final child of a `Stack` with nothing drawn over it — so no overlay is needed.
- **Glass sampling.** On iOS 26+ the material samples the content behind it every frame. That is GPU work UIKit does for its own bars too, but it is not free.

What helps in practice:

- One or two platform views per screen, not one per list row. Prefer Flutter widgets for anything that repeats.
- Nothing painted over the glass view. If content must scroll under a bottom bar, make sure it is *under* it in paint order, not over it.
- Measure with the DevTools performance overlay / timeline on a **release** build on a device; simulator and debug numbers are not representative for platform views.

If a page is noticeably janky with a glass bar and smooth without it, and none of the above applies, please open an issue with a DevTools timeline capture.

### Known limitations

- Tab bar background, shadow, and badge styling are system-driven by design.
- `LiquidGlassMenu` is meant for one trigger per screen; multiple triggers interfere ([#11](https://github.com/tienanh306201z/native_liquid_glass/issues/11)).
- Widgets with non-SF-Symbol icons rasterize or load the asset asynchronously before the platform view appears; a same-size placeholder is shown meanwhile.

## Extras

### Spring animation

Cupertino-style spring physics for Flutter animations, built on `SpringSimulation`.

### Presets

| Preset | Duration | Bounce | Use case |
| --- | --- | --- | --- |
| `LiquidGlassSpring.bouncy()` | 500ms | 0.3 | Playful, expressive |
| `LiquidGlassSpring.snappy()` | 500ms | 0.15 | Quick UI transitions |
| `LiquidGlassSpring.smooth()` | 500ms | 0.0 | Critically-damped, no overshoot |
| `LiquidGlassSpring.interactive()` | 150ms | 0.14 | Tracking a pointer |

### SpringBuilder

```dart
SpringBuilder(
  value: _expanded ? 1.5 : 1.0,
  spring: LiquidGlassSpring.bouncy(),
  builder: (context, value, child) {
    return Transform.scale(scale: value, child: child);
  },
  child: myWidget,
)
```

### VelocitySpringBuilder (drag + release)

```dart
VelocitySpringBuilder(
  value: _dragOffset,
  active: _isDragging,
  springWhenActive: LiquidGlassSpring.interactive(),
  springWhenReleased: LiquidGlassSpring.snappy(),
  builder: (context, value, velocity, child) {
    return Transform.translate(offset: Offset(value, 0), child: child);
  },
  child: myWidget,
)
```

### Controllers (imperative API)

```dart
final ctrl = SingleSpringController(
  vsync: this,
  spring: LiquidGlassSpring.snappy(),
  initialValue: 0.0,
);

ctrl.animateTo(1.0); // spring to target, preserving velocity
ctrl.setValue(0.5);   // instant jump
```

### SVG path utility

`SvgPathExtension` on `String` parses SVG path data (the `d` attribute of an `<path>` element) into Flutter paths or `LiquidGlassConfig.customPath` ops — so you can take an SVG straight from a design tool and drop it into a glass container.

```dart
// Flutter Path
final path = 'M10 10 L20 20 Z'.toPath();

// Scaled Flutter Path (from SVG viewBox to target size)
final scaled = 'M10 10 L20 20 Z'.toPathScaled(
  viewBox: const Size(30, 30),
  target: const Size(120, 120),
);

// Direct to LiquidGlassConfig.customPath
LiquidGlassContainer(
  config: LiquidGlassConfig(
    shape: LiquidGlassEffectShape.custom,
    customPath: 'M50 0 L150 0 L200 60 L150 120 L50 120 L0 60 Z'
        .toLiquidGlassPath(),
    customPathSize: const Size(200, 120),
  ),
  child: ...,
)

// Handles non-zero-origin viewBoxes (e.g. "1 0 24 226")
LiquidGlassContainer(
  config: LiquidGlassConfig(
    shape: LiquidGlassEffectShape.custom,
    customPath: svgD.toLiquidGlassPathScaled(
      viewBox: const Rect.fromLTWH(1, 0, 24, 226),
      target: const Size(48, 452),
    ),
    customPathSize: const Size(48, 452),
  ),
  child: ...,
)
```

Leading whitespace, newlines, comments, or stray characters before the first `M`/`m` are stripped automatically, so pasted SVG strings "just work". Quadratic Béziers are normalized to cubic Béziers to match iOS's path rendering.

## How it works

Each widget creates a `UiKitView` that Flutter embeds into the render tree. The iOS plugin registers a native `FlutterPlatformViewFactory` for each view type. Initial configuration is passed through `creationParams`; subsequent changes are pushed over a per-view `FlutterMethodChannel`.

On iOS 26+, all native UIKit controls automatically receive Apple's Liquid Glass styling. On older iOS versions, the same controls render with their standard system appearance.

## Contributing

Bug reports with a minimal reproduction are the most useful thing you can send — especially anything involving overlays, transitions or a specific iOS version. Pull requests are welcome; please keep the Swift XCTests in `example/ios/RunnerTests` green (`xcodebuild test` against an iOS 26+ simulator) and `flutter test` passing.

## License

[MIT](LICENSE) © Tran Tien Anh
