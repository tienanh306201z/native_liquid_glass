import SwiftUI
import UIKit

// MARK: - View Model

@available(iOS 16.0, *)
final class LiquidGlassButtonViewModel: ObservableObject {
  @Published var config: LiquidGlassButtonConfig
  var onPressed: (() -> Void)?

  init(config: LiquidGlassButtonConfig) {
    self.config = config
  }
}

// MARK: - Badge View

@available(iOS 16.0, *)
struct LiquidGlassButtonBadge: View {
  let text: String?
  var backgroundColor: Color = .red
  var textColor: Color = .white
  var size: CGFloat?

  var body: some View {
    if let text, !text.isEmpty {
      let fontSize = size ?? 12
      Text(text)
        .font(.system(size: fontSize, weight: .semibold))
        .foregroundColor(textColor)
        .padding(.horizontal, fontSize * 0.42)
        .padding(.vertical, fontSize * 0.17)
        .background(backgroundColor)
        .clipShape(Capsule())
        .frame(minWidth: fontSize * 1.67, minHeight: fontSize * 1.67)
    } else {
      let dotSize = size ?? 10
      Circle()
        .fill(backgroundColor)
        .frame(width: dotSize, height: dotSize)
    }
  }
}

// MARK: - SwiftUI Root View

/// SwiftUI view for LiquidGlassButton. Uses glass effect modifiers on iOS 26+
/// and standard SwiftUI button styles as fallback on iOS 16–25.
@available(iOS 16.0, *)
struct LiquidGlassButtonRootView: View {
  @ObservedObject var viewModel: LiquidGlassButtonViewModel
  @Namespace private var namespace

  private var config: LiquidGlassButtonConfig { viewModel.config }

  var body: some View {
    ZStack(alignment: .topTrailing) {
      if #available(iOS 26.0, *) {
        ios26Content
      } else {
        standardButtonView
      }
      if config.showBadge {
        LiquidGlassButtonBadge(
          text: config.badgeValue,
          backgroundColor: config.badgeColor.map { Color(uiColor: $0) } ?? .red,
          textColor: config.badgeTextColor.map { Color(uiColor: $0) } ?? .white,
          size: config.badgeSize
        )
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
    .accessibilityAddTraits(.isButton)
  }

  // MARK: iOS 26+ – glass effect path

  @available(iOS 26.0, *)
  @ViewBuilder
  private var ios26Content: some View {
    if isGlassStyle {
      GlassEffectContainer(spacing: 40) {
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
      }
    } else {
      standardButtonView
    }
  }

  // MARK: Standard SwiftUI button styles (iOS 16–25 and non-glass on iOS 26+)

  @ViewBuilder
  private var standardButtonView: some View {
    let tint = resolvedTintColor()
    // When the caller provides explicit contentInsets, pad the label so those insets
    // are reflected. Standard button styles add their own padding on top, so this path
    // is most accurate when the caller uses the glass style for full control.
    let styledLabel = config.contentInsets != nil
      ? AnyView(buttonLabel.padding(resolvedPadding()))
      : AnyView(buttonLabel)
    Group {
      if config.buttonStyle == "plain" {
        Button(action: handlePress) { styledLabel }
          .buttonStyle(.plain)
      } else if config.buttonStyle == "gray" {
        Button(action: handlePress) { styledLabel }
          .buttonStyle(.bordered)
          .tint(Color(.systemGray))
      } else if config.buttonStyle == "filled" || config.buttonStyle == "borderedProminent" {
        Button(action: handlePress) { styledLabel }
          .buttonStyle(.borderedProminent)
          .tint(tint)
      } else if isGlassStyle {
        // Glass fallback for iOS < 26: semi-transparent borderedProminent
        Button(action: handlePress) { styledLabel }
          .buttonStyle(.borderedProminent)
          .tint(tint?.opacity(0.22) ?? Color.accentColor.opacity(0.22))
      } else {
        // "bordered", "tinted", and others
        Button(action: handlePress) { styledLabel }
          .buttonStyle(.bordered)
          .tint(tint)
      }
    }
    .disabled(!config.enabled)
    .allowsHitTesting(config.interaction)
    .frame(width: config.width, height: resolvedFrameHeight())
    .clipShape(resolvedShape())
  }

  // MARK: Label content

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

  // MARK: Color resolution

  private var effectiveIconColor: Color? {
    // Explicit icon color always wins.
    if let c = config.iconColor { return Color(uiColor: c) }
    if config.iconOnly {
      // icon-only: labelColor > foregroundColor > tint (mirrors UIKit button.tintColor chain)
      if let c = config.labelColor { return Color(uiColor: c) }
      if let c = config.foregroundColor { return Color(uiColor: c) }
      if let c = config.tint { return Color(uiColor: c) }
      return nil
    }
    // text+icon: icon adopts the same colour as the text so both stay in sync,
    // matching UIKit's baseForegroundColor which colours both text and icon together.
    return effectiveTextColor
  }

  private var effectiveTextColor: Color? {
    let isBackgroundTintStyle = ["filled", "borderedProminent", "prominentGlass"].contains(
      config.buttonStyle)
    if isBackgroundTintStyle {
      if let c = config.labelColor { return Color(uiColor: c) }
      if let c = config.foregroundColor { return Color(uiColor: c) }
      return nil
    }
    if let c = config.labelColor { return Color(uiColor: c) }
    if let c = config.foregroundColor { return Color(uiColor: c) }
    if let c = config.tint { return Color(uiColor: c) }
    return nil
  }

  private func resolvedTintColor() -> Color? {
    if let c = config.tint { return Color(uiColor: c) }
    if let c = config.foregroundColor { return Color(uiColor: c) }
    return nil
  }

  // MARK: Font resolution

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

  // MARK: Shape, sizing, padding

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
    if config.iconOnly {
      return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
    }
    return EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
  }

  // MARK: Glass effect

  @available(iOS 26.0, *)
  private func resolvedGlass() -> Glass {
    let isProminent =
      config.buttonStyle == "prominentGlass" || config.buttonStyle == "automatic"

    var glass = Glass.regular
    if config.interactive {
      glass = glass.interactive()
    }
    if let tint = config.tint {
      glass = glass.tint(Color(uiColor: tint))
    } else if isProminent {
      glass = glass.tint(Color.accentColor.opacity(0.25))
    }
    return glass
  }

  // MARK: Helpers

  private var isGlassStyle: Bool {
    config.buttonStyle == "glass" || config.buttonStyle == "prominentGlass"
      || config.buttonStyle == "automatic"
  }

  private var accessibilityLabel: String {
    config.title ?? config.sfSymbolName ?? "Button"
  }

  private func handlePress() {
    guard config.enabled else { return }
    viewModel.onPressed?()
  }
}
