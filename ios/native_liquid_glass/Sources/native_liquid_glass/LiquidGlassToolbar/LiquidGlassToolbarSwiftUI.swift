import SwiftUI
import UIKit

// MARK: - Observable ViewModel

@available(iOS 26.0, *)
final class LiquidGlassToolbarViewModel: ObservableObject {
  /// A resolved toolbar item ready to render in SwiftUI.
  ///
  /// Icon assets (PNG / IconData / SVG) are pre-decoded to `UIImage` by the
  /// platform-view layer so this struct stays free of decoding concerns.
  struct Item: Identifiable {
    enum Kind {
      case sfSymbol(String)
      case image(UIImage)
      case textOnly
      case flexibleSpacer
      case fixedSpacer(width: CGFloat)
    }

    let id: String
    let kind: Kind
    let label: String?
    let enabled: Bool
    let iconPointSize: CGFloat
    let tintColor: UIColor?
  }

  struct LabelStyle {
    var font: Font?
    var fontWeight: Font.Weight?
    var letterSpacing: CGFloat?

    static let empty = LabelStyle(font: nil, fontWeight: nil, letterSpacing: nil)
  }

  @Published var items: [Item] = []
  @Published var iconSymbolWeight: Font.Weight = .regular
  @Published var labelStyle: LabelStyle = .empty
  @Published var glassOverflow: CGFloat = 0

  var onItemTapped: ((String) -> Void)?

  /// Rebuilds all @Published state from a fresh creation-params dict.
  ///
  /// The PNG / asset / SVG decoding helpers live on the platform-view
  /// side (so they're shared with the pre-iOS-26 UIKit path). This
  /// ViewModel receives them as closures to stay Flutter-agnostic — it
  /// never references `FlutterStandardTypedData` directly, only the
  /// caller-supplied `imageDecoder(iconRaw, assetRaw, pointSize)`.
  func apply(
    args: [String: Any]?,
    imageDecoder: (Any?, Any?, Double) -> UIImage?,
    colorDecoder: (Any?) -> UIColor?
  ) {
    items = Self.makeItems(
      from: args,
      imageDecoder: imageDecoder,
      colorDecoder: colorDecoder
    )
    iconSymbolWeight = Self.mapFontWeight(args?["iconWeight"] as? String)
    labelStyle = Self.makeLabelStyle(from: args?["labelStyle"] as? [String: Any])
    glassOverflow = (args?["glassOverflow"] as? NSNumber).map { CGFloat(truncating: $0) } ?? 0
  }

  // MARK: Builders

  private static func makeItems(
    from args: [String: Any]?,
    imageDecoder: (Any?, Any?, Double) -> UIImage?,
    colorDecoder: (Any?) -> UIColor?
  ) -> [Item] {
    let itemDicts = (args?["items"] as? [[String: Any]]) ?? []
    var items: [Item] = []

    for (index, dict) in itemDicts.enumerated() {
      let isSpacer = (dict["spacer"] as? Bool) ?? false
      if isSpacer {
        let flexible = (dict["flexible"] as? Bool) ?? true
        if flexible {
          items.append(
            Item(
              id: "__spacer_\(index)__",
              kind: .flexibleSpacer,
              label: nil, enabled: true, iconPointSize: 0,
              tintColor: nil
            )
          )
        } else {
          let width = CGFloat((dict["width"] as? NSNumber)?.doubleValue ?? 16)
          items.append(
            Item(
              id: "__spacer_\(index)__",
              kind: .fixedSpacer(width: width),
              label: nil, enabled: true, iconPointSize: 0,
              tintColor: nil
            )
          )
        }
        continue
      }

      let id = (dict["id"] as? String) ?? ""
      let sfSymbol = dict["sfSymbol"] as? String
      let label = dict["label"] as? String
      let enabled = (dict["enabled"] as? Bool) ?? true
      let iconSize = (dict["iconSize"] as? NSNumber)?.doubleValue
      let itemTintColor = colorDecoder(dict["tintColor"])

      let kind: Item.Kind
      let pointSize: CGFloat
      if let sfSymbol {
        kind = .sfSymbol(sfSymbol)
        pointSize = CGFloat(iconSize ?? 20)
      } else if let image = imageDecoder(
        dict["iconDataPng"],
        dict["assetIconPng"],
        iconSize ?? 24
      ) {
        kind = .image(image)
        pointSize = CGFloat(iconSize ?? 24)
      } else {
        kind = .textOnly
        pointSize = 0
      }

      items.append(
        Item(
          id: id,
          kind: kind,
          label: label,
          enabled: enabled,
          iconPointSize: pointSize,
          tintColor: itemTintColor
        )
      )
    }

    return items
  }

  private static func makeLabelStyle(from dict: [String: Any]?) -> LabelStyle {
    guard let dict else { return .empty }

    let fontSize = (dict["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
    let fontWeightRaw = (dict["fontWeight"] as? NSNumber)?.intValue
    let fontFamily = (dict["fontFamily"] as? String)?.trimmingCharacters(
      in: .whitespacesAndNewlines)
    let letterSpacing = (dict["letterSpacing"] as? NSNumber).map { CGFloat(truncating: $0) }

    let weight = fontWeightRaw.map { mapFlutterWeightToFontWeight($0) }

    let font: Font?
    if let fontFamily, !fontFamily.isEmpty {
      font = .custom(fontFamily, size: fontSize ?? 17)
    } else if let fontSize {
      if let weight {
        font = .system(size: fontSize, weight: weight)
      } else {
        font = .system(size: fontSize)
      }
    } else {
      font = nil
    }

    return LabelStyle(font: font, fontWeight: weight, letterSpacing: letterSpacing)
  }

  // MARK: Weight mapping

  private static func mapFontWeight(_ name: String?) -> Font.Weight {
    switch name {
    case "ultraLight": return .ultraLight
    case "thin": return .thin
    case "light": return .light
    case "medium": return .medium
    case "semibold": return .semibold
    case "bold": return .bold
    case "heavy": return .heavy
    case "black": return .black
    default: return .regular
    }
  }

  /// Maps Flutter's `FontWeight` integer (100–900) onto SwiftUI's `Font.Weight`.
  private static func mapFlutterWeightToFontWeight(_ value: Int) -> Font.Weight {
    switch value {
    case ...100: return .ultraLight
    case ...200: return .thin
    case ...300: return .light
    case ...400: return .regular
    case ...500: return .medium
    case ...600: return .semibold
    case ...700: return .bold
    case ...800: return .heavy
    default: return .black
    }
  }
}

// MARK: - Group splitting

@available(iOS 26.0, *)
fileprivate enum ToolbarGroup: Identifiable {
  case items(id: Int, [LiquidGlassToolbarViewModel.Item])
  case flexibleSpacer(id: Int)

  var id: Int {
    switch self {
    case .items(let id, _): return id
    case .flexibleSpacer(let id): return id
    }
  }
}

/// Splits a flat item list on each `.flexibleSpacer` into separate groups.
///
/// Each non-empty run of items becomes its own glass capsule; flexible
/// spacers become `Spacer()` between capsules. Fixed spacers stay
/// *inside* a group and render as internal gaps. This matches the iOS 26
/// split-toolbar pattern you see in e.g. Mail / Safari.
@available(iOS 26.0, *)
fileprivate func splitIntoGroups(
  _ items: [LiquidGlassToolbarViewModel.Item]
) -> [ToolbarGroup] {
  var groups: [ToolbarGroup] = []
  var buffer: [LiquidGlassToolbarViewModel.Item] = []
  var nextId = 0

  func flushBuffer() {
    if !buffer.isEmpty {
      groups.append(.items(id: nextId, buffer))
      nextId += 1
      buffer = []
    }
  }

  for item in items {
    if case .flexibleSpacer = item.kind {
      flushBuffer()
      groups.append(.flexibleSpacer(id: nextId))
      nextId += 1
    } else {
      buffer.append(item)
    }
  }
  flushBuffer()
  return groups
}

// MARK: - SwiftUI Root View

/// iOS 26+ Liquid Glass toolbar rendered as a SwiftUI `HStack` of one or
/// more glass capsules split on flexible spacers.
///
/// The whole bar fills its hosting view, so the `SizedBox(height:)`
/// supplied from Flutter directly controls the visible glass bar height.
@available(iOS 26.0, *)
struct LiquidGlassToolbarSwiftUIView: View {
  @ObservedObject var viewModel: LiquidGlassToolbarViewModel

  var body: some View {
    GeometryReader { geometry in
      GlassEffectContainer(spacing: 0) {
        HStack(spacing: 0) {
          ForEach(splitIntoGroups(viewModel.items)) { group in
            switch group {
            case .flexibleSpacer:
              Spacer(minLength: 0)
            case .items(_, let groupItems):
              ToolbarGroupCapsule(
                items: groupItems,
                iconSymbolWeight: viewModel.iconSymbolWeight,
                labelStyle: viewModel.labelStyle,
                onItemTapped: { id in viewModel.onItemTapped?(id) }
              )
            }
          }
        }
        // Inset uniformly by the Flutter-supplied overflow so each capsule
        // has room to spring out in every direction without being clipped.
        // The visible capsule height still equals `widget.height`; the
        // horizontal inset just means capsules don't touch the widget's
        // left/right edges — which also matches iOS 26 floating-toolbar
        // design (bars breathe on all sides).
        .padding(viewModel.glassOverflow)
        .frame(width: geometry.size.width, height: geometry.size.height)
      }
    }
  }
}

// MARK: - Group Capsule

/// A single glass capsule containing one run of toolbar items.
///
/// Uses Apple's native `Glass.regular.interactive()` so the press
/// feedback matches `LiquidGlassButton` exactly — the iOS 26 Liquid
/// Glass system handles the spring-out + tint on press internally. No
/// manual gesture / scale / spring is layered on top.
@available(iOS 26.0, *)
fileprivate struct ToolbarGroupCapsule: View {
  let items: [LiquidGlassToolbarViewModel.Item]
  let iconSymbolWeight: Font.Weight
  let labelStyle: LiquidGlassToolbarViewModel.LabelStyle
  let onItemTapped: (String) -> Void

  var body: some View {
    HStack(spacing: 0) {
      ForEach(Array(items.enumerated()), id: \.offset) { _, item in
        itemView(for: item)
      }
    }
    .frame(maxHeight: .infinity)
    .glassEffect(.regular.interactive(), in: Capsule())
  }

  // MARK: Item rendering

  @ViewBuilder
  private func itemView(for item: LiquidGlassToolbarViewModel.Item) -> some View {
    switch item.kind {
    case .fixedSpacer(let width):
      Spacer().frame(width: width)
    case .flexibleSpacer:
      // Flexible spacers are consumed during group splitting and never
      // reach a group capsule.
      EmptyView()
    default:
      Button(action: { onItemTapped(item.id) }) {
        itemContent(for: item)
          .frame(minWidth: 44, minHeight: 44)
          .padding(.horizontal, 4)
          .contentShape(Rectangle())
      }
      .disabled(!item.enabled)
      .buttonStyle(ToolbarItemButtonStyle())
      .accessibilityLabel(item.label ?? item.id)
    }
  }

  @ViewBuilder
  private func itemContent(for item: LiquidGlassToolbarViewModel.Item) -> some View {
    // Apply `foregroundStyle` directly to the visible element. `.tint` on a
    // `Button` doesn't propagate through the `ToolbarItemButtonStyle`
    // (which only returns `configuration.label`), so per-item tint has to
    // be painted on the Image/Text itself.
    let tint = item.tintColor.map { Color(uiColor: $0) }
    switch item.kind {
    case .sfSymbol(let name):
      Image(systemName: name)
        .font(.system(size: item.iconPointSize, weight: iconSymbolWeight))
        .applyForegroundIfPresent(tint)
    case .image(let uiImage):
      Image(uiImage: uiImage)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: item.iconPointSize, height: item.iconPointSize)
        .applyForegroundIfPresent(tint)
    case .textOnly:
      Text(item.label ?? item.id)
        .font(labelStyle.font ?? .body)
        .fontWeight(labelStyle.fontWeight ?? .regular)
        .kerning(labelStyle.letterSpacing ?? 0)
        .applyForegroundIfPresent(tint)
    case .flexibleSpacer, .fixedSpacer:
      EmptyView()
    }
  }
}

// MARK: - Button style

/// Suppresses SwiftUI's default button highlight so the capsule's spring
/// scale is the only visual press feedback.
@available(iOS 26.0, *)
fileprivate struct ToolbarItemButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
  }
}

// MARK: - Helpers

@available(iOS 26.0, *)
extension View {
  /// Applies `.foregroundStyle(color)` only when a non-nil color is
  /// supplied so that items without an override inherit the ambient
  /// foreground color from the host.
  @ViewBuilder
  fileprivate func applyForegroundIfPresent(_ color: Color?) -> some View {
    if let color {
      self.foregroundStyle(color)
    } else {
      self
    }
  }
}
