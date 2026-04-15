# Changelog

## 0.1.1

### SVG Path Utility
- Add `SvgPathExtension` on `String` for converting SVG path data into Flutter `Path` or `LiquidGlassConfig.customPath` ops.
- `toPath()` / `toPathScaled({viewBox, target})` — parse SVG path data into a Flutter `Path`, with optional scaling.
- `toLiquidGlassPath()` — parse directly into `List<LiquidGlassPathOp>` for `LiquidGlassConfig.customPath`.
- `toLiquidGlassPathScaled({viewBox, target})` — handles non-zero-origin viewBoxes (e.g. `"1 0 24 226"`) by translating then scaling every coordinate.
- Accepts paths with leading whitespace, newlines, comments, or stray characters (everything before the first `M`/`m` is stripped).
- Quadratic Béziers are normalized to cubic Béziers to match the native iOS path rendering.
- Add `path_parsing: ^1.1.0` as a direct dependency.

### LiquidGlassContainer
- Wrap SwiftUI glass content in `GlassEffectContainer` so `Glass.clear` renders with its proper translucent appearance in light mode instead of falling back to a frosted white panel, and so `glassEffectUnionId` / `glassEffectId` modifiers work as documented.

### LiquidGlassTabBar
- Fix: per-tab `selectedItemColor` (from `LiquidGlassTabItem.selectedItemColor`) no longer reverts to the global `selectedItemColor` after a Flutter navigation push/pop. The tab bar's `UITabBarAppearance.selected` colors are now kept in sync with the currently-applied per-tab tint, and the tint is re-applied when the view re-attaches to a window.

## 0.1.0

### Spring Animation System
- Add `LiquidGlassSpring` with four presets: `bouncy`, `snappy`, `smooth`, `interactive`.
- Add `SingleSpringController` and `OffsetSpringController` for imperative spring-driven values.
- Add `SpringBuilder`, `VelocitySpringBuilder`, and `OffsetSpringBuilder` declarative widgets.
- All builders respect `MediaQuery.disableAnimationsOf` for accessibility (reduce motion).

### Custom Shape Support for LiquidGlassContainer
- Add `LiquidGlassEffectShape.custom` for arbitrary glass container shapes.
- Add `LiquidGlassPathOp` sealed class (`moveTo`, `lineTo`, `cubicTo`, `quadTo`, `close`) for defining custom paths.
- Add `customPath` and `customPathSize` to `LiquidGlassConfig` — coordinates are in your SVG/design space, the native side scales automatically.
- Native `CustomPathShape` (SwiftUI `Shape`) renders the custom path on iOS 26+.

### Animated Config Transitions
- Add `animateChanges` property to `LiquidGlassContainer`.
- When enabled, shape/effect/tint/cornerRadius changes animate with a native SwiftUI spring transition.
- Refactored native side from view recreation to `ObservableObject` ViewModel — the SwiftUI view stays alive across config updates.
- Built-in shape transitions (rect/capsule/circle) use `Animatable` corner radius interpolation.
- Custom shape transitions use `AnimatableCustomPathShape` with control point morphing via `VectorArithmetic`.
- Built-in to/from custom transitions use opacity crossfade.

### Interactive Container
- `LiquidGlassContainer` now shows a spring press animation (scale down/bounce back) when `config.interactive` is true, matching `LiquidGlassButton` behavior.
- Add `onTap` callback to `LiquidGlassContainer` — uses Flutter's gesture system so child widgets receive touches normally.
- Native `UiKitView` is wrapped in `IgnorePointer`; all gesture handling is Flutter-side.

### Container Sizing
- `LiquidGlassContainer` now wraps its child size when `width`/`height` are omitted, matching Flutter `Container` behavior.
- Native glass view uses `Positioned.fill` to match the child-determined size.

## 0.0.3

- Add Swift Package Manager (SPM) support for iOS.

## 0.0.2

- Switch iOS tab bar implementation from custom SwiftUI rendering to system `UITabBarController`.
- Rely on iOS system Liquid Glass appearance on iOS 26+ instead of custom `.glassEffect()` drawing.
- Remove unsupported action-button and custom-shape parameters from `LiquidGlassTabBar` API.
- Add supported native customization: selected color and item positioning/spacing/width.
- Remove `backgroundColor` and `shadowColor`; tab bar background and shadow visuals are now system-driven.
- Remove `unselectedItemColor` parameter so unselected item appearance is system-driven by iOS Liquid Glass behavior.
- Add iOS tab badge support per item (`iosBadgeValue`).
- Remove `iosBadgeColor` and `iosBadgeTextColor`; badge styling is now system-driven.
- Add three icon source options for `LiquidGlassTabItem`: `sfSymbolName`, `iconData`, and `assetIconPath` (plus selected variants).
- Rename icon parameters to meaningful source-based names while keeping deprecated aliases (`icon`, `activeIcon`, `iosSystemImage`, `iosActiveSystemImage`).
- Add reusable static synchronous utility `NativeLiquidGlassUtils.isDeviceQualifiedForLiquidGlassWidget()` for iOS 26+ qualification checks before rendering native widgets (no `await` required).
- Add native customization for tab icon size via `LiquidGlassTabBar.iconSize`.
- Add per-item icon size override via `LiquidGlassTabItem.iconSize`.
- Add native label typography customization via `LiquidGlassTabBar.labelTextStyle` (font size/weight/family/letter spacing).
- Add per-item selected color override via `LiquidGlassTabItem.selectedItemColor`.
- Add SVG decoding support for `assetIconPath` and `selectedAssetIconPath` on iOS.
- Add optional iOS action button support via `iosActionButton` and `onActionButtonPressed`.
- Remove iOS search feature and related callbacks (`iosShowSearchButton`, `onSearchButtonPressed`, `onSearchQueryChanged`, `onSearchSubmitted`, `onSearchDismissed`).
- Add `LiquidGlassButton` with iOS native platform-view rendering and Flutter fallback.
- Add `LiquidGlassIconButton` with iOS native platform-view rendering and Flutter fallback.
- Add three icon source options for buttons (`sfSymbolName`, `iconData`, `assetIconPath`) with iOS native source-priority resolution.
- Add native button visual parameters: `iconColor`, `foregroundColor`, `glassTintColor`, `imagePadding`, and `glassInteractive`.
- Use default UIKit button configuration APIs for button rendering; on iOS/iPadOS 26+ use `UIButton.Configuration.prominentGlass()` with interactive `UIGlassEffect`.
- Performance: `LiquidGlassButtonGroup` icon payload resolution is now gated by an icon signature — payloads are not re-resolved unless icons actually change between widget rebuilds.
- Performance: `LiquidGlassButtonGroup` resolves icon payloads for all buttons concurrently with `Future.wait` instead of sequentially.
- Performance: `LiquidGlassButton` skips `TextPainter` layout cost during `build` when both explicit `width` and `height` are provided.
- Fix: `LiquidGlassNavigationBar` now correctly syncs changes to `leadingItems`, `trailingItems`, and `titleTextStyle` to the native bar after initial creation; a matching `setItems` channel method was added on the Swift side.

## 0.0.1

- Convert package template to Flutter iOS plugin scaffolding.
- Add native Liquid Glass-style tab bar behavior for iOS.
- Add runtime fallback rendering for non-iOS platforms.
- Expose `LiquidGlassTabBar` Flutter widget API.
- Add interactive example app showcasing the tab bar.
- Remove standalone `LiquidGlassView` item from the package API.
