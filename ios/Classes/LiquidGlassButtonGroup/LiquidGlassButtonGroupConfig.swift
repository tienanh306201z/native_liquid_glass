import SwiftUI

/// Configuration for LiquidGlassButtonSwiftUI with default values.
@available(iOS 26.0, *)
struct LiquidGlassButtonGroupConfig {
  let borderRadius: CGFloat?
  let padding: EdgeInsets
  let minHeight: CGFloat
  let spacing: CGFloat

  init(
    borderRadius: CGFloat? = nil,
    padding: EdgeInsets = EdgeInsets(top: 8.0, leading: 12.0, bottom: 8.0, trailing: 12.0),
    minHeight: CGFloat = 44.0,
    spacing: CGFloat = 8.0
  ) {
    self.borderRadius = borderRadius
    self.padding = padding
    self.minHeight = minHeight
    self.spacing = spacing
  }

  /// Convenience initializer for individual padding values.
  init(
    borderRadius: CGFloat? = nil,
    top: CGFloat? = nil,
    bottom: CGFloat? = nil,
    left: CGFloat? = nil,
    right: CGFloat? = nil,
    horizontal: CGFloat? = nil,
    vertical: CGFloat? = nil,
    minHeight: CGFloat = 44.0,
    spacing: CGFloat = 8.0
  ) {
    self.borderRadius = borderRadius
    self.minHeight = minHeight
    self.spacing = spacing

    let defaultPadding = EdgeInsets(top: 8.0, leading: 12.0, bottom: 8.0, trailing: 12.0)
    self.padding = EdgeInsets(
      top: top ?? vertical ?? defaultPadding.top,
      leading: left ?? horizontal ?? defaultPadding.leading,
      bottom: bottom ?? vertical ?? defaultPadding.bottom,
      trailing: right ?? horizontal ?? defaultPadding.trailing
    )
  }
}
