import SwiftUI
import UIKit

/// SwiftUI button view with full Liquid Glass support using glassEffect() modifier.
/// Uses LiquidGlassButtonConfig for full feature parity with standalone buttons.
@available(iOS 26.0, *)
struct LiquidGlassButtonGroupItemView: View {
  let config: LiquidGlassButtonConfig
  let onPressed: () -> Void
  var namespace: Namespace.ID

  var body: some View {
    Button(action: handlePress) {
      buttonLabel
        .padding(resolvedPadding())
        .frame(width: config.width, height: resolvedFrameHeight())
        .contentShape(resolvedShape())
        .glassEffect(resolvedGlass(), in: resolvedShape())
        .applyLiquidGlassEffectModifiers(
          unionId: config.glassEffectUnionId,
          id: config.glassEffectId,
          namespace: namespace
        )
    }
    .disabled(!config.enabled)
    .buttonStyle(LiquidGlassNoHighlightButtonStyle())
    .allowsHitTesting(config.interaction)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityAddTraits(.isButton)
  }

  // MARK: - Label content

  @ViewBuilder
  private var buttonLabel: some View {
    if config.iconOnly {
      iconView
        .foregroundColor(effectiveIconColor)
    } else if config.imagePlacement == "trailing" {
      HStack(spacing: config.imagePadding) {
        textLabel
        iconView.foregroundColor(effectiveIconColor)
      }
    } else if config.imagePlacement == "top" {
      VStack(spacing: config.imagePadding) {
        iconView.foregroundColor(effectiveIconColor)
        textLabel
      }
    } else if config.imagePlacement == "bottom" {
      VStack(spacing: config.imagePadding) {
        textLabel
        iconView.foregroundColor(effectiveIconColor)
      }
    } else {
      // "leading" (default)
      HStack(spacing: config.imagePadding) {
        iconView.foregroundColor(effectiveIconColor)
        textLabel
      }
    }
  }

  @ViewBuilder
  private var iconView: some View {
    if config.assetIconPng != nil || config.iconDataPng != nil,
      let uiImage = config.resolvedImage()
    {
      Image(uiImage: uiImage)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: config.iconSize, height: config.iconSize)
    } else if let symbolName = config.sfSymbolName {
      Image(systemName: symbolName)
        .font(.system(size: config.iconSize, weight: .semibold))
    }
  }

  private var textLabel: some View {
    Text(config.title ?? "Button")
      .lineLimit(config.maxLines)
      .multilineTextAlignment(.leading)
      .font(resolvedFont())
      .kerning(config.labelStyle?.letterSpacing ?? 0)
      .foregroundColor(effectiveTextColor)
  }

  // MARK: - Color resolution

  private var effectiveIconColor: Color? {
    if let c = config.iconColor { return Color(uiColor: c) }
    if config.iconOnly {
      if let c = config.labelColor { return Color(uiColor: c) }
      if let c = config.foregroundColor { return Color(uiColor: c) }
      if let c = config.tint { return Color(uiColor: c) }
      return nil
    }
    return effectiveTextColor
  }

  private var effectiveTextColor: Color? {
    if let c = config.labelColor { return Color(uiColor: c) }
    if let c = config.foregroundColor { return Color(uiColor: c) }
    if let c = config.tint { return Color(uiColor: c) }
    return nil
  }

  // MARK: - Font resolution

  private func resolvedFont() -> Font? {
    guard let style = config.labelStyle else { return nil }
    let size = style.fontSize ?? 17.0
    if let family = style.fontFamily {
      return .custom(family, size: size)
    }
    let weight = style.fontWeight.map { mapToSwiftUIWeight($0) } ?? .regular
    return .system(size: size, weight: weight)
  }

  private func mapToSwiftUIWeight(_ uiWeight: UIFont.Weight) -> Font.Weight {
    switch uiWeight {
    case .ultraLight: return .ultraLight
    case .thin: return .thin
    case .light: return .light
    case .medium: return .medium
    case .semibold: return .semibold
    case .bold: return .bold
    case .heavy: return .heavy
    case .black: return .black
    default: return .regular
    }
  }

  // MARK: - Shape, sizing, padding

  private func resolvedShape() -> AnyShape {
    if let r = config.borderRadius {
      return AnyShape(RoundedRectangle(cornerRadius: r))
    }
    return AnyShape(Capsule())
  }

  private func resolvedFrameHeight() -> CGFloat? {
    config.height > 0 ? config.height : nil
  }

  private func resolvedPadding() -> EdgeInsets {
    if let insets = config.contentInsets {
      return EdgeInsets(
        top: insets.top,
        leading: insets.leading,
        bottom: insets.bottom,
        trailing: insets.trailing
      )
    }
    // Group buttons always need padding for proper capsule shape,
    // including icon-only buttons (standalone uses explicit size instead).
    return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
  }

  // MARK: - Glass effect

  private func resolvedGlass() -> Glass {
    var glass = Glass.regular
    if config.interactive {
      glass = glass.interactive()
    }
    if let tint = config.tint {
      glass = glass.tint(Color(uiColor: tint))
    }
    return glass
  }

  // MARK: - Helpers

  private var accessibilityLabel: String {
    config.title ?? config.sfSymbolName ?? "Button"
  }

  private func handlePress() {
    guard config.enabled else { return }
    onPressed()
  }
}

// MARK: - Helper extensions

@available(iOS 26.0, *)
extension View {
  @ViewBuilder
  func applyLiquidGlassEffectModifiers(
    unionId: String?,
    id: String?,
    namespace: Namespace.ID
  ) -> some View {
    if let unionId = unionId {
      if let id = id {
        self
          .glassEffectUnion(id: unionId, namespace: namespace)
          .glassEffectID(id, in: namespace)
      } else {
        self
          .glassEffectUnion(id: unionId, namespace: namespace)
      }
    } else if let id = id {
      self
        .glassEffectID(id, in: namespace)
    } else {
      self
    }
  }
}

/// Custom button style that removes all highlights and press effects,
/// letting the glass effect handle visual feedback.
@available(iOS 26.0, *)
struct LiquidGlassNoHighlightButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
  }
}
