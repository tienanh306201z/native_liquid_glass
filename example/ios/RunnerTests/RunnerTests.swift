import Flutter
import UIKit
import XCTest


@testable import native_liquid_glass

// This demonstrates a simple unit test of the Swift portion of this plugin's implementation.
//
// See https://developer.apple.com/documentation/xctest for more information about using XCTest.

class RunnerTests: XCTestCase {

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
