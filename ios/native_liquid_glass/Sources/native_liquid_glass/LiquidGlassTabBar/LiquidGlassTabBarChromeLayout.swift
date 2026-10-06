import UIKit

/// Maps UIKit vertical bar traits + layout heuristics to Flutter content insets.
enum LiquidGlassTabBarChromeLayout {
  case horizontalBottom
  case verticalLeading
  case verticalTrailing

  static func resolve(for view: UIView) -> LiquidGlassTabBarChromeLayout {
    if let edge = verticalBarEdge(from: view.traitCollection) {
      switch edge {
      case .leading:
        return .verticalLeading
      case .trailing:
        return .verticalTrailing
      default:
        break
      }
    }

    guard let window = view.window else {
      return .horizontalBottom
    }

    let bounds = window.bounds
    // Heuristic for Duo / wide landscape before traits are wired.
    if bounds.width > bounds.height, bounds.width >= 700 {
      return .verticalTrailing
    }

    return .horizontalBottom
  }

  private enum ResolvedVerticalEdge {
    case leading
    case trailing
  }

  private static func verticalBarEdge(from traits: UITraitCollection) -> ResolvedVerticalEdge? {
    // `UITraitCollection.verticalBarEdge` ships with the iOS 27.1 SDK (iPhone Duo).
    if #available(iOS 27.1, *) {
      switch traits.verticalBarEdge {
      case .leading:
        return .leading
      case .trailing:
        return .trailing
      default:
        return nil
      }
    }
    return nil
  }

  var isVertical: Bool {
    switch self {
    case .horizontalBottom:
      return false
    case .verticalLeading, .verticalTrailing:
      return true
    }
  }

  func edgeName() -> String {
    switch self {
    case .horizontalBottom:
      return "none"
    case .verticalLeading:
      return "leading"
    case .verticalTrailing:
      return "trailing"
    }
  }

  /// Default platform-view width when the tab bar is vertical and we cannot measure yet.
  static let defaultVerticalHitWidth: CGFloat = 112

  func payload(
    containerBounds: CGRect,
    tabBarFrameInWindow: CGRect?,
    windowBounds: CGRect,
    safeAreaInsets: UIEdgeInsets
  ) -> [String: Any] {
    switch self {
    case .horizontalBottom:
      let bottom = max(safeAreaInsets.bottom, 16) + 72
      return [
        "isVertical": false,
        "edge": edgeName(),
        "contentPaddingLeft": safeAreaInsets.left,
        "contentPaddingRight": safeAreaInsets.right,
        "contentPaddingBottom": bottom,
        "hitTargetWidth": containerBounds.width,
        "hitTargetHeight": containerBounds.height,
      ]

    case .verticalLeading, .verticalTrailing:
      let measuredWidth: CGFloat
      if let tabBarFrameInWindow, tabBarFrameInWindow.width > 1 {
        switch self {
        case .verticalTrailing:
          measuredWidth = max(
            Self.defaultVerticalHitWidth,
            windowBounds.maxX - tabBarFrameInWindow.minX
          )
        case .verticalLeading:
          measuredWidth = max(
            Self.defaultVerticalHitWidth,
            tabBarFrameInWindow.maxX - windowBounds.minX
          )
        case .horizontalBottom:
          measuredWidth = Self.defaultVerticalHitWidth
        }
      } else {
        measuredWidth = Self.defaultVerticalHitWidth
      }

      let hitWidth = max(Self.defaultVerticalHitWidth, measuredWidth)
      let hitHeight = windowBounds.height

      var paddingLeft = safeAreaInsets.left
      var paddingRight = safeAreaInsets.right
      var paddingBottom = safeAreaInsets.bottom + 16

      switch self {
      case .verticalTrailing:
        paddingRight = hitWidth
      case .verticalLeading:
        paddingLeft = hitWidth
      case .horizontalBottom:
        break
      }

      return [
        "isVertical": true,
        "edge": edgeName(),
        "contentPaddingLeft": paddingLeft,
        "contentPaddingRight": paddingRight,
        "contentPaddingBottom": paddingBottom,
        "hitTargetWidth": hitWidth,
        "hitTargetHeight": hitHeight,
      ]
    }
  }
}
