# native_liquid_glass

A Flutter plugin that exposes iOS native Liquid Glass widgets through Flutter Platform Views (`UiKitView`).

On iOS 26+, all widgets automatically adopt Apple's Liquid Glass visual style. On older iOS versions and non-iOS platforms, graceful fallbacks are provided.

## Widgets

| Widget                         | Native UIKit component                                   |
| ------------------------------ | -------------------------------------------------------- |
| `LiquidGlassTabBar`            | `UITabBarController`                                     |
| `LiquidGlassButton`            | `UIButton` with glass configurations                     |
| `LiquidGlassButtonGroup`       | Row/column of `UIButton`s with unified glass blending    |
| `LiquidGlassContainer`         | Glass-effect `UIView` with custom shapes, animated transitions, and interactive press |
| `LiquidGlassNavigationBar`     | `UINavigationBar`                                        |
| `LiquidGlassToolbar`           | `UIToolbar`                                              |
| `LiquidGlassSearchBar`         | Expandable `UISearchTextField`                           |
| `LiquidGlassSearchScaffold`    | Full-screen scaffold with native tab bar + `UISearchTab` |
| `LiquidGlassToggle`            | `UISwitch`                                               |
| `LiquidGlassSlider`            | `UISlider`                                               |
| `LiquidGlassStepper`           | `UIStepper`                                              |
| `LiquidGlassSegmentedControl`  | `UISegmentedControl`                                     |
| `LiquidGlassColorPicker`       | `UIColorWell`                                            |
| `LiquidGlassDatePicker`        | `UIDatePicker`                                           |
| `LiquidGlassMenu`              | `UIButton` + `UIMenu` context menu                       |
| `LiquidGlassSheet`             | `UISheetPresentationController`                          |
| `LiquidGlassAlert`             | `UIAlertController`                                      |
| `LiquidGlassPopover`           | `UIPopoverPresentationController`                        |
| `LiquidGlassActivityIndicator` | `UIActivityIndicatorView`                                |
| `LiquidGlassProgressView`      | `UIProgressView`                                         |

## Requirements

- Flutter **3.41.2+**
- iOS/iPadOS **26.0+** for full Liquid Glass behavior
  _(older iOS versions fall back to standard system styles)_

## Integration

This plugin supports both **CocoaPods** and **Swift Package Manager (SPM)**.

- **CocoaPods** (default) — works automatically with `flutter pub get`
- **SPM** — supported from Flutter 3.19+ via `ios/native_liquid_glass/Package.swift`

## Installation

```yaml
dependencies:
    native_liquid_glass: ^0.2.3
```

Then run `flutter pub get`.

## Icons

All icon-bearing widgets accept `NativeLiquidGlassIcon`, which supports three sources:

```dart
NativeLiquidGlassIcon.sfSymbol('star.fill')    // Native SF Symbol (preferred on iOS)
NativeLiquidGlassIcon.iconData(Icons.star)      // Flutter IconData (PNG-encoded for iOS)
NativeLiquidGlassIcon.asset('assets/star.png')  // App bundle asset (PNG or SVG)
```

On iOS, source resolution priority is **asset → IconData → SF Symbol**.

## Usage

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

### Indicators

```dart
LiquidGlassActivityIndicator(animating: _isLoading)

LiquidGlassProgressView(progress: _uploadProgress, progressTintColor: Colors.blue)
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

## Device qualification check

```dart
if (NativeLiquidGlassUtils.supportsLiquidGlass) {
  // Running on iOS 26+ — full Liquid Glass behavior active.
}
```

## Spring Animation System

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

## SVG Path Utility

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

## Notes

- Tab bar background, shadow, and badge styling are intentionally system-driven.
- Widgets that require custom icon data (non-SF Symbol) rasterize or load assets asynchronously before the platform view is shown; a same-size placeholder is displayed during resolution.
- See `example/` for a working demo of all widgets.

Happy building.
Thanks for trying `native_liquid_glass`.
