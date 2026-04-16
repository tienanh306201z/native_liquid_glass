# Changelog

## 0.2.6

### Glass overlay suppression (automatic)

- **New**: all glass platform views automatically hide when a Flutter overlay (bottom sheet, dialog, page push) covers them, preventing the native glass from bleeding through Flutter-drawn content. Glass items *inside* the overlay stay visible.
- Uses `ModalRoute.of(context).isCurrent` — fully automatic, zero setup required. Each widget manages its own visibility via the new `LiquidGlassRouteSuppression` mixin.
- Two suppression layers that can coexist:
  - **Route-based (automatic)**: per-widget, driven by Flutter's `InheritedWidget` mechanism. Works with any navigator, handles nested popups via the route's own `isCurrent` state.
  - **Global (manual)**: `NativeLiquidGlassLifecycle.suppressGlassEffects()` / `.unsuppressGlassEffects()` for custom overlays that don't use the Navigator. Reference-counted for safe nesting.
- Optional `LiquidGlassNavigatorObserver` still available for apps that prefer the observer pattern.
- Example app: container preview page now includes "Bottom Sheet" and "Push Screen" test buttons.

## 0.2.5

### LiquidGlassContainer
- Add `LiquidGlassConfig.backgroundColor` — a solid color drawn **inside the same shape** but **behind** the glass material. Two complementary effects:
  - **Density**: the alpha channel controls how dense the glass reads. `Color(...).withValues(alpha: 0.4)` gives a denser pill than the bare-glass default; `alpha: 1.0` produces an effectively solid colored surface with the glass material's highlight + shadow on top. Apple's iOS 26 `Glass` API doesn't expose a density/intensity knob, so this controlled backdrop is the supported way to thicken the visible material.
  - **Stable color**: fixes the "colors below the glass appear inverted as I scroll" issue on iOS 26. The Liquid Glass material runs an adaptive-contrast pass that samples the brightness of whatever's behind it and inverts the material's tone for legibility — over varying Flutter content this can read as flickering. With `backgroundColor` set, the glass refracts your fixed backdrop instead and stays stable.
- iOS implementation: rendered as `shape.fill(color)` inside a `.background { ... }` modifier applied **after** `.glassEffect(...)`, so the z-order is `backdrop → glass material → border overlay → Flutter child`. The backdrop uses the same `BuiltInGlassShape` / `AnimatableCustomPathShape` reference as the glass fill, so it animates with shape changes (corner radius, custom-path morph) under `animateChanges: true`.

## 0.2.4

### Custom border
- Add new `LiquidGlassBorder` class (shared) — a stroked outline that follows the widget's underlying shape (capsule, rounded rect, circle, or custom path). Exposes `color` and `width`. Exported from `package:native_liquid_glass/native_liquid_glass.dart`.
- `LiquidGlassContainer`: new `LiquidGlassConfig.border` field. Border traces every supported shape including animatable custom paths (the stroke animates with the shape via the same `animatableData` used by the glass fill).
- `LiquidGlassButton`: new `border` widget property on both constructors (text + icon-only). Stroke follows `borderRadius` (capsule when null, rounded rect otherwise).
- `LiquidGlassToolbar`: new `border` widget property. Applied **per capsule** so every pill in a split toolbar gets the same outline.
- iOS side: border renders as `shape.stroke(color, lineWidth:)` inside an `.overlay { ... }` after `.glassEffect(...)`, so the stroke sits on top of the glass material and matches the fill geometry exactly.

### LiquidGlassContainer
- Fix: re-added the `GlassEffectContainer(spacing: 0)` wrapper around the container's SwiftUI body. This was claimed in the 0.2.0 CHANGELOG but the actual wrapping was missing from the shipped code, with three visible consequences: (a) `Glass.clear` rendered as a frosted white panel in light mode instead of the proper translucent material, (b) `glassEffectUnion(id:)` / `glassEffectID(_:)` — applied via `applyLiquidGlassContainerModifiers` — silently did nothing because they require a `GlassEffectContainer` ancestor, and (c) interactive glass under-rendered. All three now work as documented.
- Defensive: `hostingController.view.clipsToBounds = false` (and `layer.masksToBounds = false`) so the glass material's subtle drop-shadow doesn't clip at the host-view boundary (matches the toolbar's existing treatment).
- Doc: clarified that `glass.interactive()` on the native side is effectively dead because the `UiKitView` is wrapped in `IgnorePointer` to let Flutter child widgets inside the container still receive taps. Touches never reach the native glass view, so the visual press feedback is produced Flutter-side via `SpringBuilder` + `Transform.scale`. The `.interactive()` call is kept anyway because it subtly adjusts the baseline material, keeping the rendered look consistent with `LiquidGlassButton` / `LiquidGlassToolbar`.

## 0.2.3

### LiquidGlassButton
- Fix: the Dart-side wrap-content estimator (`_estimateWrapContentSize`) was measuring text with a hardcoded `TextStyle(fontSize: 17, fontWeight: .w600)` and ignoring `widget.labelTextStyle`. That mismatched what the native `UIButton` actually renders when the caller passes a scaled `labelTextStyle` (e.g. a ScreenUtil-scaled style on iPad) — the button would sit at a stale estimated width until the async `getIntrinsicSize` round-trip caught up, which in timing-sensitive layouts looked like the button was "frozen" at the wrong width. Estimator now resolves `labelTextStyle.fontSize` / `.fontWeight` / `.fontFamily` / `.letterSpacing` before measuring, falling back to the 17pt / semibold iOS default only when the caller omits them.
- Deprecated: `LiquidGlassButton.shrinkWrap`. The field was never wired into layout — it's a no-op — but was documented as functional, which was misleading. Actual wrap-content behavior comes from leaving `width: null` (triggers an `UnconstrainedBox` internally). Now `@Deprecated` with the correct guidance; retained for source compatibility.

### SVG asset icons
- Fix: `NativeLiquidGlassIcon.asset(...)` no longer crashes the app when the SVG has a wide viewBox (e.g. `0 0 1000 1000`) being rendered into a small icon target (e.g. 20pt). The button and toolbar decoders previously called `svgImage.size = CGSize(width: iconSize, height: iconSize)` before reading `.uiImage`, which triggers an SVGKit rendering crash at very small scale factors with certain SVG content (transforms, gradients, path numerics). Both decoders now let SVGKit render at the SVG's natural viewBox size and scale down with UIKit (matching what the tab bar decoder already does), plus gate on the rendered image having a non-zero size.

### LiquidGlassToolbar
- `height` now maps 1:1 to the visible glass bar height. Reverted the 12pt vertical overflow padding added in 0.2.0 — the outer widget footprint now equals `widget.height` with no implicit margin. Setting a small `height` (e.g. 32) actually shrinks the bar instead of just shrinking the surrounding padding.
- Dropped the implicit 44pt minimum height on toolbar items (only the horizontal 44pt floor is kept for a comfortable tap target), so heights below 44 truly shrink the bar.
- Each capsule now snaps to an explicit `height` (from the Flutter-supplied `widget.height`) instead of relying on `.frame(maxHeight: .infinity)`, which didn't always force the full height through every SwiftUI layout path.
- Add `itemSpacing` parameter (default `8`, in points) — the horizontal gap between adjacent items. Implemented as `itemSpacing / 2` of horizontal padding per item, so `itemSpacing` is both the gap between adjacent items and the inset from each end of the capsule.
- Add `padding` parameter (`EdgeInsetsGeometry`, default `EdgeInsets.zero`) applied **inside each glass capsule** (CSS-style padding of the capsule container), so the pill grows around its items rather than inserting an outer margin around the widget. In wrap-content mode the widget still wraps the capsule(s) tightly. Horizontal padding is the typical use; vertical padding shrinks the item content area while the capsule keeps `height`. Supports `EdgeInsetsDirectional` for RTL.
- Fix: wrap-content (`width: null`) no longer silently swells to the parent's width when the toolbar sits inside a tight-horizontal parent (e.g. `Column(crossAxisAlignment: .stretch)` or a `Padding` inside one). Flutter clamps a child's preferred size up to the parent's tight constraint; that left the `UiKitView` wider than the capsule(s) and rendered the leftover space as if `padding`/`itemSpacing` had leaked *outside* the glass pill. The widget now wraps itself in `UnconstrainedBox(constrainedAxis: Axis.vertical, alignment: Alignment.center)` in wrap-content mode, so the bar shrinks to the estimated content width and centers within its parent slot (matching Apple's iOS 26 floating-toolbar visual). Pass `width: double.infinity` for explicit fill-parent.
- `width: null` now **auto-promotes to fill-parent** when [items] contains a flexible `LiquidGlassToolbarSpacer`. Without this, a flex spacer in wrap-content mode silently collapsed to `0` and left the split capsules stuck together at one edge — almost never what a caller using a flex spacer wants. With a flex spacer in items, the toolbar now fills the parent's width so the spacer can distribute the capsule groups (the iOS 26 split-toolbar pattern). Without a flex spacer, wrap-content behavior is unchanged.
- **Behavior change:** `LiquidGlassToolbarSpacer(flexible: false, width: X)` now also splits the toolbar into separate capsules (with an `X`-point fixed gap between them), matching the behavior of flexible spacers. Previously fixed spacers stayed inside one capsule as an in-pill gap; now both spacer kinds produce the iOS 26 split-toolbar pattern. The `flexible` flag controls only whether the *gap* between capsules is variable (`Spacer()`) or a fixed width.
- Fix: the leading capsule in a split toolbar (items separated by a flexible `LiquidGlassToolbarSpacer`) is no longer clipped/invisible. Each `ToolbarGroupCapsule` now wraps its own `.glassEffect(.regular.interactive(), in: Capsule())` in a dedicated `GlassEffectContainer(spacing: 0)`. A single shared outer container was merging sibling pills into one fused surface and clipping the leading one; omitting the container entirely left `Glass.interactive()` without the compositing context it needs to render fully (which is why other interactive-glass widgets like `LiquidGlassButton` always pair `.interactive()` with a `GlassEffectContainer`). Per-capsule containment gives each pill an independent, fully-rendered glass surface.

### LiquidGlassButton
- Fix: icon-only buttons with `size: null` and text buttons with `width: null` no longer swell to the parent's width when placed inside a tight-horizontal parent. Same `UnconstrainedBox(constrainedAxis: Axis.vertical)` treatment as the toolbar — this was observable on iPad where layout contexts more often pass tight horizontal constraints. Pass an explicit `size` / `width` (or `double.infinity`) to opt out.

## 0.2.0

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
- Press feedback on `interactive: true` now scales **up** to 1.04 (was: down to 0.96) so it visually mirrors the "spring out" aesthetic of Apple's native `Glass.interactive()` used by `LiquidGlassButton` and `LiquidGlassToolbar`. The container can't use native `.interactive()` directly (its `UiKitView` is `IgnorePointer`-wrapped so Flutter child widgets inside can still receive taps), so this keeps the press-response visually consistent across the plugin. Same `LiquidGlassSpring.interactive()` preset as before.

### LiquidGlassButton
- `LiquidGlassButton.icon` now wraps its content when `size` is not provided, matching Flutter button semantics. The default for `size` changed from `50` to `null`; when null, the button is sized from `iconSize` plus a minimum 44pt touch target, then refined to the native intrinsic size reported by the platform view. **Breaking** for callers that relied on the implicit `size: 50` default — pass `size: 50` explicitly to preserve the old behavior.
- The native `getIntrinsicSize` round-trip now runs for icon-only buttons too (previously only text buttons requested it), so icon buttons with null `size` settle to the exact size Apple's Liquid Glass rendering prefers.

### LiquidGlassTabBar
- Fix: per-tab `selectedItemColor` (from `LiquidGlassTabItem.selectedItemColor`) no longer reverts to the global `selectedItemColor` after a Flutter navigation push/pop. The tab bar's `UITabBarAppearance.selected` colors are now kept in sync with the currently-applied per-tab tint, and the tint is re-applied when the view re-attaches to a window.

### LiquidGlassToolbar
- On iOS 26+ the toolbar is now rendered as a SwiftUI `HStack` with `.glassEffect(.regular, in: Capsule())` (hosted via `UIHostingController`). `height` now actually resizes the visible Liquid Glass bar — previously the underlying `UIToolbar` locked its glass rendering to the system-intrinsic 44pt and any extra height became transparent padding.
- Each run of items between flexible `LiquidGlassToolbarSpacer`s is now rendered as its own independent glass capsule, matching the iOS 26 split-toolbar pattern (multiple floating pill bars side-by-side). Fixed spacers stay inside their group as internal gaps.
- Press feedback now uses Apple's native `Glass.regular.interactive()` on each capsule — the same mechanism `LiquidGlassButton` uses. iOS 26's system handles the spring-out + tint response internally, so behavior (timing, scale, damping) is identical across `LiquidGlassButton`, `LiquidGlassButtonGroup`, and `LiquidGlassToolbar`. Sibling capsules in a split toolbar are unaffected when one is pressed.
- Fix: `LiquidGlassToolbarItem.tintColor` now actually colors the item's icon/text. Previously `.tint(...)` was applied to the item's `Button`, but our custom `ButtonStyle` only re-emits `configuration.label`, so the tint never reached the `Image`/`Text`. Tint is now applied directly via `.foregroundStyle(color)` on the visible element.
- **Breaking:** removed `LiquidGlassToolbarItem.style` and the `LiquidGlassToolbarItemStyle` enum. Text items now render with `LiquidGlassToolbar.labelTextStyle`'s weight (or `.regular` if none supplied) — there's no longer a `.done` bold variant. If you need bold text for a specific item, pass a `labelTextStyle` on the whole toolbar.
- The widget now reserves vertical overflow padding so the capsule's drop shadow and spring scale-down are not clipped. The visible bar still honors the supplied `height`; only the outer widget footprint grows to accommodate the overflow.
- Item spacing tightened to match UIToolbar's visual rhythm (minimum 44pt hit targets with 4pt inter-item padding instead of the previous 12pt HStack gap).
- Add optional `width` parameter. When null (default), the toolbar **wraps its content** — width is estimated from item sizes (`TextPainter` for labels, `iconSize` for icons, fixed spacer widths, plus glass overflow padding). Pass `double.infinity` or wrap in `Expanded` for full-parent-width behavior. Flexible spacers only expand when an explicit or `double.infinity` width is provided; in wrap-content mode they collapse to 0.
- On iOS 15–25 the existing `UIToolbar` path is kept as a fallback (still constrained to 44pt, which matches the non-Liquid-Glass system behavior).

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
