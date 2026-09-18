import Flutter
import UIKit
import XCTest


@testable import native_liquid_glass

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

  // `testGetPlatformVersion` was removed here — it called
  // `NativeLiquidGlassPlugin.handle(_:result:)`, a method-channel handler
  // this plugin no longer implements (`register(with:)` only registers
  // platform-view factories now; there is no `FlutterMethodCall` handling
  // left to test). The test predated that refactor and no longer compiled.
  // Out of scope for this change; flagged separately rather than replaced.

}

/// Records `onTabSelected`/`onActionButtonPressed` invocations from a
/// `LiquidGlassNativeTabBarControllerView` under test.
private final class TabSelectionRecorder {
  var selectedIndices: [Int] = []
  var actionButtonPressCount = 0
}

// MARK: - LiquidGlassNativeTabBarControllerView selection-notification tests
//
// Regression coverage for the native default-tab notification leak: on the
// iOS 26+ `UITab` construction path, `UITabBarController.tabs` and
// `.selectedTab` invoke `UITabBarControllerDelegate` *synchronously*, even
// for programmatic changes made during setup. Assigning
// `tabBarController.delegate = self` before the tabs/selection were
// configured let that synchronous callback leak out as a spurious
// `onTabSelected(0)` call to Flutter before the real `currentIndex`
// selection had even been applied.
//
// On hot reload, `LiquidGlassTabBar.reassemble()` unconditionally bumps
// `_nativeTabsVersion` (see `lib/src/liquid_glass_tab_bar.dart`), which
// changes the platform view's `ValueKey` and forces Flutter to tear down and
// recreate the native view — replaying this whole setup sequence and
// re-leaking the spurious index-0 notification. The app's navigation logic
// reads that as "user tapped tab 0" and pops the stack back to the first
// screen.
final class LiquidGlassNativeTabBarControllerViewSelectionTests: XCTestCase {

  private func makeConfig(
    tabCount: Int,
    currentIndex: Int,
    withActionButton: Bool = false
  ) -> LiquidGlassTabBarConfig {
    let tabs: [[String: Any]] = (0..<tabCount).map { index in
      [
        "label": "Tab \(index)",
        "sfSymbolName": "circle",
      ]
    }

    var args: [String: Any] = [
      "tabs": tabs,
      "currentIndex": currentIndex,
    ]

    if withActionButton {
      args["actionButton"] = [
        "label": "Action",
        "sfSymbolName": "plus",
      ]
    }

    return LiquidGlassTabBarConfig(arguments: args)
  }

  private func makeView(
    config: LiquidGlassTabBarConfig,
    recorder: TabSelectionRecorder
  ) -> LiquidGlassNativeTabBarControllerView {
    LiquidGlassNativeTabBarControllerView(
      config: config,
      onTabSelected: { [weak recorder] index in
        recorder?.selectedIndices.append(index)
      },
      onActionButtonPressed: { [weak recorder] in
        recorder?.actionButtonPressCount += 1
      }
    )
  }

  // MARK: Setup must never notify Flutter

  func testInit_withNonZeroCurrentIndex_firesNoSelectionDuringSetup() {
    let recorder = TabSelectionRecorder()
    let config = makeConfig(tabCount: 3, currentIndex: 2)

    _ = makeView(config: config, recorder: recorder)

    XCTAssertTrue(
      recorder.selectedIndices.isEmpty,
      "Setup leaked onTabSelected(\(recorder.selectedIndices)) before any user " +
        "interaction; this is the default-tab notification leak that pops Flutter's " +
        "navigation stack on hot reload."
    )
  }

  func testInit_withZeroCurrentIndex_firesNoSelectionDuringSetup() {
    // Index 0 is the trap case: a spurious auto-selected-tab-0 notification
    // and a legitimate `currentIndex == 0` selection are indistinguishable
    // by value alone, so this pins down that neither fires during setup.
    let recorder = TabSelectionRecorder()
    let config = makeConfig(tabCount: 3, currentIndex: 0)

    _ = makeView(config: config, recorder: recorder)

    XCTAssertTrue(recorder.selectedIndices.isEmpty)
  }

  func testInit_withLastTabSelected_neverLeaksIntermediateIndexZero() {
    // Reproduces the exact reported symptom: currentIndex points at the last
    // tab, so a leaked auto-selected-tab-0 notification firing before the
    // real selection is unambiguous.
    let recorder = TabSelectionRecorder()
    let config = makeConfig(tabCount: 4, currentIndex: 3)

    _ = makeView(config: config, recorder: recorder)

    XCTAssertFalse(recorder.selectedIndices.contains(0))
    XCTAssertTrue(recorder.selectedIndices.isEmpty)
  }

  func testInit_withActionButton_firesNoSelectionOrActionCallbackDuringSetup() {
    let recorder = TabSelectionRecorder()
    let config = makeConfig(tabCount: 2, currentIndex: 1, withActionButton: true)

    _ = makeView(config: config, recorder: recorder)

    XCTAssertTrue(recorder.selectedIndices.isEmpty)
    XCTAssertEqual(recorder.actionButtonPressCount, 0)
  }

  func testInit_calledTwiceInSequence_neitherInstanceLeaksSelection() {
    // Simulates Flutter hot reload: the old platform view is disposed and a
    // brand-new `LiquidGlassNativeTabBarControllerView` is created in its
    // place (a fresh `UITabBarController`, delegate starting `nil`) with a
    // possibly different `currentIndex`. Each instance's own setup must stay
    // silent regardless of what the previous instance did.
    let firstRecorder = TabSelectionRecorder()
    let firstConfig = makeConfig(tabCount: 3, currentIndex: 1)
    let firstView = makeView(config: firstConfig, recorder: firstRecorder)

    let secondRecorder = TabSelectionRecorder()
    let secondConfig = makeConfig(tabCount: 3, currentIndex: 2)
    let secondView = makeView(config: secondConfig, recorder: secondRecorder)

    XCTAssertTrue(firstRecorder.selectedIndices.isEmpty)
    XCTAssertTrue(secondRecorder.selectedIndices.isEmpty)
    XCTAssertNotNil(firstView.tabBarController)
    XCTAssertNotNil(secondView.tabBarController)
  }

  // MARK: Setup still applies the configured selection natively

  func testInit_selectsConfiguredIndex_onTabsAPI() throws {
    guard #available(iOS 26.0, *) else {
      throw XCTSkip("UITab-based selection requires iOS 26+.")
    }

    let recorder = TabSelectionRecorder()
    let config = makeConfig(tabCount: 3, currentIndex: 2)
    let view = makeView(config: config, recorder: recorder)

    let tabs = view.tabBarController.tabs
    XCTAssertEqual(tabs.count, 3)
    XCTAssertEqual(view.tabBarController.selectedTab, tabs[2])
  }

  func testInit_appliesTabBarModeAndClampsOutOfRangeIndex() throws {
    guard #available(iOS 26.0, *) else {
      throw XCTSkip("UITab-based selection requires iOS 26+.")
    }

    let recorder = TabSelectionRecorder()
    // `currentIndex` arrives pre-clamped from `LiquidGlassTabBarConfig.init`
    // (99 -> 1 for a 2-tab bar); exercise the boundary explicitly too.
    let config = makeConfig(tabCount: 2, currentIndex: 99)
    let view = makeView(config: config, recorder: recorder)

    XCTAssertTrue(recorder.selectedIndices.isEmpty)
    XCTAssertEqual(config.currentIndex, 1)
    XCTAssertEqual(view.tabBarController.selectedTab, view.tabBarController.tabs[1])
    if #available(iOS 18.0, *) {
      XCTAssertEqual(view.tabBarController.mode, .tabBar)
    }
  }

  // MARK: Delegate stays live for real, post-setup interactions

  func testUserDrivenSelection_afterSetup_stillNotifiesFlutter() throws {
    guard #available(iOS 26.0, *) else {
      throw XCTSkip("UITab-based selection requires iOS 26+.")
    }

    let recorder = TabSelectionRecorder()
    let config = makeConfig(tabCount: 3, currentIndex: 0)
    let view = makeView(config: config, recorder: recorder)
    XCTAssertTrue(recorder.selectedIndices.isEmpty, "Sanity check: setup must stay silent.")

    let tabs = view.tabBarController.tabs
    XCTAssertEqual(tabs.count, 3)

    // Programmatically select a different tab the same way UIKit does in
    // response to a real user tap.
    view.tabBarController.selectedTab = tabs[1]

    XCTAssertEqual(
      recorder.selectedIndices, [1],
      "Delegate must still fire for genuine post-setup selection changes."
    )
  }

  func testUserDrivenSelection_actionButtonTap_isInterceptedNotForwardedAsTabSelection() throws {
    guard #available(iOS 26.0, *) else {
      throw XCTSkip("UISearchTab interception requires iOS 26+.")
    }

    let recorder = TabSelectionRecorder()
    let config = makeConfig(tabCount: 2, currentIndex: 0, withActionButton: true)
    let view = makeView(config: config, recorder: recorder)
    XCTAssertTrue(recorder.selectedIndices.isEmpty)

    guard let actionTab = view.tabBarController.tabs.last else {
      return XCTFail("Expected a trailing action tab.")
    }

    let shouldSelect = view.tabBarController(view.tabBarController, shouldSelectTab: actionTab)

    XCTAssertFalse(shouldSelect, "The action tab must never become the selected tab.")
    XCTAssertEqual(recorder.actionButtonPressCount, 1)
    XCTAssertTrue(recorder.selectedIndices.isEmpty)
  }

  // MARK: Programmatic selection from Dart must not echo back to Flutter

  func testSetSelectedIndex_programmatic_doesNotNotifyFlutter() throws {
    guard #available(iOS 26.0, *) else {
      throw XCTSkip("UITab-based selection requires iOS 26+.")
    }

    let recorder = TabSelectionRecorder()
    let config = makeConfig(tabCount: 3, currentIndex: 0)
    let view = makeView(config: config, recorder: recorder)
    XCTAssertTrue(recorder.selectedIndices.isEmpty, "Sanity check: setup must stay silent.")

    // Dart calls `setSelectedIndex` when the app changes `currentIndex`
    // itself (deep link, programmatic navigation, selection rollback). That
    // selection originated in Flutter, so echoing it back as `onTabSelected`
    // would make the app treat its own state change as a user tap.
    view.setSelectedIndex(2)

    XCTAssertEqual(view.tabBarController.selectedTab, view.tabBarController.tabs[2])
    XCTAssertTrue(
      recorder.selectedIndices.isEmpty,
      "setSelectedIndex echoed onTabSelected(\(recorder.selectedIndices)) back to Flutter."
    )
  }

  func testSetSelectedIndex_thenUserTap_stillNotifiesFlutter() throws {
    guard #available(iOS 26.0, *) else {
      throw XCTSkip("UITab-based selection requires iOS 26+.")
    }

    let recorder = TabSelectionRecorder()
    let config = makeConfig(tabCount: 3, currentIndex: 0)
    let view = makeView(config: config, recorder: recorder)

    view.setSelectedIndex(2)
    XCTAssertTrue(recorder.selectedIndices.isEmpty)

    // A later user-driven selection must still reach Flutter: the
    // programmatic-selection guard has to be scoped to the call, not sticky.
    view.tabBarController.selectedTab = view.tabBarController.tabs[1]
    XCTAssertEqual(recorder.selectedIndices, [1])
  }

  func testDelegateDidSelectTab_mapsIdentifierBackToCorrectIndex() throws {
    guard #available(iOS 26.0, *) else {
      throw XCTSkip("UITab identifiers require iOS 26+.")
    }

    let recorder = TabSelectionRecorder()
    let config = makeConfig(tabCount: 5, currentIndex: 0)
    let view = makeView(config: config, recorder: recorder)
    XCTAssertTrue(recorder.selectedIndices.isEmpty, "Sanity check: setup must stay silent.")

    let tabs = view.tabBarController.tabs
    view.tabBarController(view.tabBarController, didSelectTab: tabs[4], previousTab: tabs[0])

    XCTAssertEqual(recorder.selectedIndices, [4])
  }
}

// MARK: - LiquidGlassNavigationBarConfig.LabelStyle color decoding
//
// `titleTextStyle.color` support: the Dart side forwards `TextStyle.color` as
// an ARGB32 int under the `color` key; the native side must decode it into a
// `.foregroundColor` title attribute and treat a color-only style as a real
// style rather than "no style".
final class LiquidGlassNavigationBarLabelStyleTests: XCTestCase {


  func testLabelStyleDecodesColorIntoForegroundColorAttribute() {
    // ARGB32 for opaque #FF6B6B.
    let argb = 0xFFFF6B6B
    let style = LiquidGlassNavigationBarConfig.LabelStyle(arguments: ["color": argb])

    XCTAssertNotNil(style)
    let color = style?.colorAttributes[.foregroundColor] as? UIColor
    XCTAssertNotNil(color)

    var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
    color?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    XCTAssertEqual(red, 1.0, accuracy: 0.01)
    XCTAssertEqual(green, 0x6B / 255.0, accuracy: 0.01)
    XCTAssertEqual(blue, 0x6B / 255.0, accuracy: 0.01)
    XCTAssertEqual(alpha, 1.0, accuracy: 0.01)
  }

  func testLabelStyleColorAloneIsSufficientToConstructStyle() {
    // Regression: before `color` support, a title-style map with only a
    // color and no font properties would be treated as "no style" and
    // dropped entirely.
    let style = LiquidGlassNavigationBarConfig.LabelStyle(arguments: ["color": 0xFF000000])

    XCTAssertNotNil(style)
    XCTAssertNil(style?.fontSize)
    XCTAssertNil(style?.fontWeight)
    XCTAssertNil(style?.fontFamily)
    XCTAssertFalse(style?.colorAttributes.isEmpty ?? true)
  }

  func testLabelStyleWithoutColorHasNoForegroundColorAttribute() {
    let style = LiquidGlassNavigationBarConfig.LabelStyle(arguments: ["fontSize": 20])

    XCTAssertNotNil(style)
    XCTAssertTrue(style?.colorAttributes.isEmpty ?? false)
  }

  func testLabelStyleReturnsNilForEmptyArguments() {
    let style = LiquidGlassNavigationBarConfig.LabelStyle(arguments: [:])
    XCTAssertNil(style)
  }
}
