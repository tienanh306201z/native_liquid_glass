import Flutter
import SVGKit
import UIKit

/// Maps Flutter creation params into strongly-typed native tab bar configuration.
struct LiquidGlassTabBarConfig {
  /// Native representation of each tab item received from Flutter.
  struct TabItem {
    let label: String
    let sfSymbolName: String
    let selectedSfSymbolName: String?
    let iconDataPng: Data?
    let selectedIconDataPng: Data?
    let assetIconPng: Data?
    let selectedAssetIconPng: Data?
    let badgeValue: String?
    let showBadge: Bool
    let badgeColor: UIColor?
    let badgeTextColor: UIColor?
    let iconSize: CGFloat?
    let selectedItemColor: UIColor?

    private func preferredImageData(forSelectedState selected: Bool)
      -> (data: Data, fromIconData: Bool)?
    {
      if selected {
        if let selectedAssetIconPng {
          return (selectedAssetIconPng, false)
        }
        if let selectedIconDataPng {
          return (selectedIconDataPng, true)
        }
        if let assetIconPng {
          return (assetIconPng, false)
        }
        if let iconDataPng {
          return (iconDataPng, true)
        }
        return nil
      }

      if let assetIconPng {
        return (assetIconPng, false)
      }
      if let iconDataPng {
        return (iconDataPng, true)
      }

      return nil
    }

    func image(forSelectedState selected: Bool, iconSize fallbackIconSize: CGFloat? = nil)
      -> UIImage?
    {
      let resolvedIconSize = iconSize ?? fallbackIconSize

      if let preferredImageData = preferredImageData(forSelectedState: selected),
        let image = decodeImage(
          from: preferredImageData.data,
          iconSize: resolvedIconSize,
          trimTransparentInsets: preferredImageData.fromIconData
        )
      {
        return image.withRenderingMode(.alwaysTemplate)
      }

      let symbolName = selected ? (selectedSfSymbolName ?? sfSymbolName) : sfSymbolName
      if let resolvedIconSize {
        let configuration = UIImage.SymbolConfiguration(pointSize: resolvedIconSize)
        return UIImage(systemName: symbolName, withConfiguration: configuration)
      }

      return UIImage(systemName: symbolName)
    }

    private func decodeImage(
      from data: Data,
      iconSize: CGFloat?,
      trimTransparentInsets: Bool
    ) -> UIImage? {
      if let rasterImage = UIImage(data: data) {
        return resizedImageIfNeeded(
          rasterImage,
          iconSize: iconSize,
          trimTransparentInsets: trimTransparentInsets
        )
      }

      guard Self.looksLikeSvg(data), let svgImage = SVGKImage(data: data) else {
        return nil
      }

      guard let image = svgImage.uiImage else {
        return nil
      }

      return resizedImageIfNeeded(image, iconSize: iconSize, trimTransparentInsets: false)
    }

    private static func looksLikeSvg(_ data: Data) -> Bool {
      let header = data.prefix(2048)
      guard let headerString = String(data: header, encoding: .utf8)?.lowercased() else {
        return false
      }

      return headerString.contains("<svg")
    }

    private func resizedImageIfNeeded(
      _ image: UIImage,
      iconSize: CGFloat?,
      trimTransparentInsets: Bool
    ) -> UIImage {
      guard let iconSize else {
        return image
      }

      let sourceImage = trimTransparentInsets ? trimmedImageByAlphaBounds(image) : image
      guard sourceImage.size.width > 0, sourceImage.size.height > 0 else {
        return sourceImage
      }

      let targetSize = CGSize(width: iconSize, height: iconSize)
      let rendererFormat = UIGraphicsImageRendererFormat.default()
      rendererFormat.scale = max(sourceImage.scale, UIScreen.main.scale)
      let renderer = UIGraphicsImageRenderer(size: targetSize, format: rendererFormat)

      let scale = min(iconSize / sourceImage.size.width, iconSize / sourceImage.size.height)
      let drawSize = CGSize(
        width: sourceImage.size.width * scale, height: sourceImage.size.height * scale)
      let drawRect = CGRect(
        x: (iconSize - drawSize.width) / 2,
        y: (iconSize - drawSize.height) / 2,
        width: drawSize.width,
        height: drawSize.height
      )

      return renderer.image { _ in
        sourceImage.draw(in: drawRect)
      }
    }

    private func trimmedImageByAlphaBounds(_ image: UIImage) -> UIImage {
      guard let cgImage = image.cgImage else {
        return image
      }

      let width = cgImage.width
      let height = cgImage.height
      guard width > 0, height > 0 else {
        return image
      }

      guard let alphaComponentIndex = alphaComponentIndex(for: cgImage.alphaInfo) else {
        return image
      }

      guard let dataProvider = cgImage.dataProvider,
        let data = dataProvider.data,
        let bytes = CFDataGetBytePtr(data)
      else {
        return image
      }

      let bytesPerPixel = cgImage.bitsPerPixel / 8
      let bytesPerRow = cgImage.bytesPerRow
      guard bytesPerPixel >= 4 else {
        return image
      }

      var minX = width
      var minY = height
      var maxX = -1
      var maxY = -1

      for y in 0..<height {
        let rowOffset = y * bytesPerRow
        for x in 0..<width {
          let offset = rowOffset + (x * bytesPerPixel) + alphaComponentIndex
          let alpha = bytes[offset]
          if alpha == 0 {
            continue
          }

          minX = min(minX, x)
          minY = min(minY, y)
          maxX = max(maxX, x)
          maxY = max(maxY, y)
        }
      }

      guard maxX >= minX, maxY >= minY else {
        return image
      }

      if minX == 0, minY == 0, maxX == width - 1, maxY == height - 1 {
        return image
      }

      let cropRect = CGRect(
        x: minX,
        y: minY,
        width: (maxX - minX) + 1,
        height: (maxY - minY) + 1
      )
      guard let croppedImage = cgImage.cropping(to: cropRect) else {
        return image
      }

      return UIImage(cgImage: croppedImage, scale: image.scale, orientation: image.imageOrientation)
    }

    private func alphaComponentIndex(for alphaInfo: CGImageAlphaInfo) -> Int? {
      switch alphaInfo {
      case .premultipliedFirst, .first, .noneSkipFirst:
        return 0
      case .premultipliedLast, .last, .noneSkipLast:
        return 3
      default:
        return nil
      }
    }
  }

  /// Optional native label typography customization.
  struct LabelStyle {
    let fontSize: CGFloat?
    let fontWeight: UIFont.Weight?
    let fontFamily: String?
    let letterSpacing: CGFloat?

    init?(arguments args: [String: Any]?) {
      guard let args else {
        return nil
      }

      let parsedFontSize = (args["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
      let parsedFontWeight = (args["fontWeight"] as? NSNumber).map {
        Self.mapFontWeight($0.intValue)
      }
      let parsedFontFamily = (args["fontFamily"] as? String)?.trimmingCharacters(
        in: .whitespacesAndNewlines)
      let parsedLetterSpacing = (args["letterSpacing"] as? NSNumber).map { CGFloat(truncating: $0) }

      if parsedFontSize == nil
        && parsedFontWeight == nil
        && (parsedFontFamily == nil || parsedFontFamily?.isEmpty == true)
        && parsedLetterSpacing == nil
      {
        return nil
      }

      fontSize = parsedFontSize
      fontWeight = parsedFontWeight
      fontFamily = (parsedFontFamily?.isEmpty == false) ? parsedFontFamily : nil
      letterSpacing = parsedLetterSpacing
    }

    func resolvedFont(defaultSize: CGFloat = 10.0) -> UIFont? {
      let pointSize = fontSize ?? defaultSize

      if let fontFamily, let customFont = UIFont(name: fontFamily, size: pointSize) {
        return customFont
      }

      if let fontWeight {
        return UIFont.systemFont(ofSize: pointSize, weight: fontWeight)
      }

      if fontSize != nil || fontFamily != nil {
        return UIFont.systemFont(ofSize: pointSize)
      }

      return nil
    }

    private static func mapFontWeight(_ value: Int) -> UIFont.Weight {
      switch value {
      case ...100:
        return .ultraLight
      case ...200:
        return .thin
      case ...300:
        return .light
      case ...400:
        return .regular
      case ...500:
        return .medium
      case ...600:
        return .semibold
      case ...700:
        return .bold
      case ...800:
        return .heavy
      default:
        return .black
      }
    }
  }

  let tabs: [TabItem]
  let actionButton: TabItem?
  let currentIndex: Int
  let showLabels: Bool
  let selectedItemColor: UIColor?
  let iconSize: CGFloat?
  let labelStyle: LabelStyle?
  let itemPositioning: UITabBar.ItemPositioning
  let itemSpacing: CGFloat?
  let itemWidth: CGFloat?
  let glassOverflow: CGFloat

  private static func decodeData(from value: Any?) -> Data? {
    if let typedData = value as? FlutterStandardTypedData {
      return typedData.data
    }

    if let data = value as? Data {
      return data
    }

    return nil
  }

  private static func decodeOptionalCGFloat(from value: Any?) -> CGFloat? {
    guard let numericValue = (value as? NSNumber)?.doubleValue, numericValue > 0 else {
      return nil
    }

    return CGFloat(numericValue)
  }

  private static func decodeColor(from value: Any?) -> UIColor? {
    guard let numericValue = value as? NSNumber else {
      return nil
    }

    return UIColor(argb: numericValue.intValue)
  }

  private static func parseTabItem(from rawTab: [String: Any]) -> TabItem {
    let rawBadgeValue = rawTab["badgeValue"] as? String
    let explicitShowBadge = rawTab["showBadge"] as? Bool
    // Resolve badge display value: empty string triggers a dot badge on UITabBarItem.
    let resolvedBadgeValue: String?
    if let value = rawBadgeValue, !value.isEmpty {
      resolvedBadgeValue = value
    } else if explicitShowBadge == true {
      resolvedBadgeValue = ""
    } else {
      resolvedBadgeValue = nil
    }
    return TabItem(
      label: rawTab["label"] as? String ?? "",
      sfSymbolName: rawTab["sfSymbolName"] as? String ?? "circle",
      selectedSfSymbolName: rawTab["selectedSfSymbolName"] as? String,
      iconDataPng: Self.decodeData(from: rawTab["iconDataPng"]),
      selectedIconDataPng: Self.decodeData(from: rawTab["selectedIconDataPng"]),
      assetIconPng: Self.decodeData(from: rawTab["assetIconPng"]),
      selectedAssetIconPng: Self.decodeData(from: rawTab["selectedAssetIconPng"]),
      badgeValue: resolvedBadgeValue,
      showBadge: resolvedBadgeValue != nil,
      badgeColor: Self.decodeColor(from: rawTab["badgeColor"]),
      badgeTextColor: Self.decodeColor(from: rawTab["badgeTextColor"]),
      iconSize: Self.decodeOptionalCGFloat(from: rawTab["iconSize"]),
      selectedItemColor: Self.decodeColor(from: rawTab["selectedItemColor"])
    )
  }

  /// Parses platform-view arguments from Flutter and applies safe defaults.
  init(arguments args: [String: Any]?) {
    // Parse tab definitions first; each tab may optionally include badge styling.
    let parsedTabs = (args?["tabs"] as? [[String: Any]] ?? []).map(Self.parseTabItem)
    actionButton = (args?["actionButton"] as? [String: Any]).map(Self.parseTabItem)

    // Keep a deterministic fallback so native rendering is never empty.
    if parsedTabs.isEmpty {
      tabs = [
        TabItem(
          label: "Tab 1",
          sfSymbolName: "circle",
          selectedSfSymbolName: "circle.fill",
          iconDataPng: nil,
          selectedIconDataPng: nil,
          assetIconPng: nil,
          selectedAssetIconPng: nil,
          badgeValue: nil,
          showBadge: false,
          badgeColor: nil,
          badgeTextColor: nil,
          iconSize: nil,
          selectedItemColor: nil
        ),
        TabItem(
          label: "Tab 2",
          sfSymbolName: "circle",
          selectedSfSymbolName: "circle.fill",
          iconDataPng: nil,
          selectedIconDataPng: nil,
          assetIconPng: nil,
          selectedAssetIconPng: nil,
          badgeValue: nil,
          showBadge: false,
          badgeColor: nil,
          badgeTextColor: nil,
          iconSize: nil,
          selectedItemColor: nil
        ),
      ]
    } else {
      tabs = parsedTabs
    }

    let requestedIndex = (args?["currentIndex"] as? NSNumber)?.intValue ?? 0
    // Clamp selection to a valid tab index in case Flutter sends an out-of-range value.
    currentIndex = min(max(0, requestedIndex), max(tabs.count - 1, 0))

    showLabels = (args?["showLabels"] as? Bool) ?? true

    // Colors are passed from Dart as ARGB integers.
    let selectedColorValue = (args?["selectedItemColor"] as? NSNumber)?.intValue

    selectedItemColor = selectedColorValue != nil ? UIColor(argb: selectedColorValue!) : nil

    if let iconSizeValue = (args?["iconSize"] as? NSNumber)?.doubleValue, iconSizeValue > 0 {
      iconSize = CGFloat(iconSizeValue)
    } else {
      iconSize = nil
    }

    labelStyle = LabelStyle(arguments: args?["labelStyle"] as? [String: Any])

    switch args?["itemPositioning"] as? String {
    case "fill":
      itemPositioning = .fill
    case "centered":
      itemPositioning = .centered
    default:
      itemPositioning = .automatic
    }

    if let spacing = (args?["itemSpacing"] as? NSNumber)?.doubleValue {
      itemSpacing = CGFloat(spacing)
    } else {
      itemSpacing = nil
    }

    if let width = (args?["itemWidth"] as? NSNumber)?.doubleValue {
      itemWidth = CGFloat(width)
    } else {
      itemWidth = nil
    }

    if let overflow = (args?["glassOverflow"] as? NSNumber)?.doubleValue, overflow > 0 {
      glassOverflow = CGFloat(overflow)
    } else {
      glassOverflow = 0
    }
  }
}

/// Converts Dart ARGB integers into `UIColor` values.
extension UIColor {
  fileprivate convenience init(argb value: Int) {
    let bitPattern = UInt32(bitPattern: Int32(truncatingIfNeeded: value))

    let alpha = CGFloat((bitPattern >> 24) & 0xFF) / 255.0
    let red = CGFloat((bitPattern >> 16) & 0xFF) / 255.0
    let green = CGFloat((bitPattern >> 8) & 0xFF) / 255.0
    let blue = CGFloat(bitPattern & 0xFF) / 255.0

    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}
