# native_liquid_glass

A Flutter plugin that exposes iOS native Liquid Glass widgets through Flutter Platform Views (`UiKitView`).

On iOS 26+, all widgets automatically adopt Apple's Liquid Glass visual style. On older iOS versions and non-iOS platforms, graceful fallbacks are provided.

## Widgets

| Widget                         | Native UIKit component                                   |
| ------------------------------ | -------------------------------------------------------- |
| `LiquidGlassTabBar`            | `UITabBarController`                                     |
| `LiquidGlassButton`            | `UIButton` with glass configurations                     |
| `LiquidGlassButtonGroup`       | Row/column of `UIButton`s with unified glass blending    |
| `LiquidGlassContainer`         | Glass-effect `UIView` wrapping Flutter children          |
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

## Installation

```yaml
dependencies:
    native_liquid_glass: ^0.0.1
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
LiquidGlassContainer(
  config: const LiquidGlassConfig(
    effect: LiquidGlassEffect.regular,
    shape: LiquidGlassEffectShape.capsule,
    tint: Color(0xFF007AFF),
    interactive: true,
  ),
  width: 200,
  height: 80,
  child: const Center(child: Text('Glass!')),
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
    LiquidGlassToolbarItem(id: 'done', label: 'Done', style: LiquidGlassToolbarItemStyle.done),
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

## How it works

Each widget creates a `UiKitView` that Flutter embeds into the render tree. The iOS plugin registers a native `FlutterPlatformViewFactory` for each view type. Initial configuration is passed through `creationParams`; subsequent changes are pushed over a per-view `FlutterMethodChannel`.

On iOS 26+, all native UIKit controls automatically receive Apple's Liquid Glass styling. On older iOS versions, the same controls render with their standard system appearance.

## Notes

- Tab bar background, shadow, and badge styling are intentionally system-driven.
- Widgets that require custom icon data (non-SF Symbol) rasterize or load assets asynchronously before the platform view is shown; a same-size placeholder is displayed during resolution.
- See `example/` for a working demo of all widgets.

Happy building.
Thanks for trying `native_liquid_glass`.
