import Flutter
import SVGKit
import UIKit

/// Strongly typed config for native Liquid Glass button views.
struct LiquidGlassButtonConfig {
  let title: String?
  let sfSymbolName: String?
  let iconDataPng: Data?
  let assetIconPng: Data?
  let width: CGFloat?
  let height: CGFloat
  let enabled: Bool
  let iconOnly: Bool
  let iconSize: CGFloat
  let foregroundColor: UIColor?
  let iconColor: UIColor?
  let tint: UIColor?
  let imagePadding: CGFloat
  let interactive: Bool
  let glassEffectUnionId: String?
  let glassEffectId: String?
  let imagePlacement: String
  let badgeValue: String?
  let showBadge: Bool
  let badgeColor: UIColor?
  let badgeTextColor: UIColor?
  let badgeSize: CGFloat?
  let labelStyle: LabelStyle?
  let buttonStyle: String
  let borderRadius: CGFloat?
  let contentInsets: NSDirectionalEdgeInsets?
  let interaction: Bool
  let labelColor: UIColor?
  let maxLines: Int?
  let borderColor: UIColor?
  let borderWidth: CGFloat

  /// Optional label typography customization.
  struct LabelStyle {
    let fontSize: CGFloat?
    let fontWeight: UIFont.Weight?
    let fontFamily: String?
    let letterSpacing: CGFloat?

    init?(arguments args: [String: Any]?) {
      guard let args else { return nil }
      let parsedFontSize = (args["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
      let parsedFontWeight = (args["fontWeight"] as? NSNumber).map {
        Self.mapFontWeight($0.intValue)
      }
      let parsedFontFamily = (args["fontFamily"] as? String)?.trimmingCharacters(
        in: .whitespacesAndNewlines)
      let parsedLetterSpacing = (args["letterSpacing"] as? NSNumber).map { CGFloat(truncating: $0) }
      if parsedFontSize == nil && parsedFontWeight == nil
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

    func resolvedFont(defaultSize: CGFloat = 17.0) -> UIFont? {
      let pointSize = fontSize ?? defaultSize
      if let fontFamily, let customFont = UIFont(name: fontFamily, size: pointSize) {
        return customFont
      }
      if let fontWeight { return UIFont.systemFont(ofSize: pointSize, weight: fontWeight) }
      if fontSize != nil || fontFamily != nil { return UIFont.systemFont(ofSize: pointSize) }
      return nil
    }

    private static func mapFontWeight(_ value: Int) -> UIFont.Weight {
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

  private static func decodeData(from value: Any?) -> Data? {
    if let typedData = value as? FlutterStandardTypedData {
      return typedData.data
    }
    if let data = value as? Data {
      return data
    }
    return nil
  }

  private static func decodeColor(from value: Any?) -> UIColor? {
    guard let numericValue = value as? NSNumber else {
      return nil
    }
    let argb = UInt32(bitPattern: Int32(truncatingIfNeeded: numericValue.intValue))
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
    let red = CGFloat((argb >> 16) & 0xFF) / 255.0
    let green = CGFloat((argb >> 8) & 0xFF) / 255.0
    let blue = CGFloat(argb & 0xFF) / 255.0
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }

  init(arguments args: [String: Any]?, defaultIconOnly: Bool) {
    let rawTitle = (args?["title"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    title = (rawTitle?.isEmpty == false) ? rawTitle : nil

    let rawSymbol = (args?["sfSymbolName"] as? String)?.trimmingCharacters(
      in: .whitespacesAndNewlines)
    if let rawSymbol, !rawSymbol.isEmpty {
      sfSymbolName = rawSymbol
    } else if defaultIconOnly {
      sfSymbolName = "plus"
    } else {
      sfSymbolName = nil
    }

    iconDataPng = Self.decodeData(from: args?["iconDataPng"])
    assetIconPng = Self.decodeData(from: args?["assetIconPng"])

    if let widthValue = (args?["width"] as? NSNumber)?.doubleValue, widthValue > 0 {
      width = CGFloat(widthValue)
    } else {
      width = nil
    }

    if let heightValue = (args?["height"] as? NSNumber)?.doubleValue, heightValue > 0 {
      height = CGFloat(max(32.0, heightValue))
    } else {
      height = 50
    }

    enabled = (args?["enabled"] as? Bool) ?? true
    iconOnly = (args?["iconOnly"] as? Bool) ?? defaultIconOnly

    if let iconSizeValue = (args?["iconSize"] as? NSNumber)?.doubleValue, iconSizeValue > 0 {
      iconSize = CGFloat(max(12.0, iconSizeValue))
    } else {
      iconSize = iconOnly ? 20 : 18
    }

    foregroundColor = Self.decodeColor(from: args?["foregroundColor"])
    iconColor = Self.decodeColor(from: args?["iconColor"])
    tint = Self.decodeColor(from: args?["tint"])

    if let rawImagePadding = (args?["imagePadding"] as? NSNumber)?.doubleValue, rawImagePadding >= 0
    {
      imagePadding = CGFloat(rawImagePadding)
    } else {
      imagePadding = 8
    }

    interactive = (args?["interactive"] as? Bool) ?? true

    if let unionId = args?["glassEffectUnionId"] as? String, !unionId.isEmpty {
      glassEffectUnionId = unionId
    } else {
      glassEffectUnionId = nil
    }

    if let effectId = args?["glassEffectId"] as? String, !effectId.isEmpty {
      glassEffectId = effectId
    } else {
      glassEffectId = nil
    }

    imagePlacement = (args?["imagePlacement"] as? String) ?? "leading"

    if let bv = args?["badgeValue"] as? String, !bv.isEmpty {
      badgeValue = bv
    } else {
      badgeValue = nil
    }

    showBadge = (args?["showBadge"] as? Bool) ?? (badgeValue != nil)
    badgeColor = Self.decodeColor(from: args?["badgeColor"])
    badgeTextColor = Self.decodeColor(from: args?["badgeTextColor"])

    if let bs = (args?["badgeSize"] as? NSNumber)?.doubleValue, bs > 0 {
      badgeSize = CGFloat(bs)
    } else {
      badgeSize = nil
    }

    labelStyle = LabelStyle(arguments: args?["labelStyle"] as? [String: Any])
    buttonStyle = (args?["buttonStyle"] as? String) ?? "prominentGlass"

    if let br = (args?["borderRadius"] as? NSNumber)?.doubleValue, br > 0 {
      borderRadius = CGFloat(br)
    } else {
      borderRadius = nil
    }

    let top = (args?["paddingTop"] as? NSNumber).map { CGFloat(truncating: $0) }
    let bottom = (args?["paddingBottom"] as? NSNumber).map { CGFloat(truncating: $0) }
    let left = (args?["paddingLeft"] as? NSNumber).map { CGFloat(truncating: $0) }
    let right = (args?["paddingRight"] as? NSNumber).map { CGFloat(truncating: $0) }
    if top != nil || bottom != nil || left != nil || right != nil {
      contentInsets = NSDirectionalEdgeInsets(
        top: top ?? 0, leading: left ?? 0, bottom: bottom ?? 0, trailing: right ?? 0)
    } else {
      contentInsets = nil
    }

    interaction = (args?["interaction"] as? Bool) ?? true
    labelColor = Self.decodeColor(from: args?["labelColor"])

    if let ml = (args?["maxLines"] as? NSNumber)?.intValue, ml > 0 {
      maxLines = ml
    } else {
      maxLines = nil
    }

    borderColor = Self.decodeColor(from: args?["borderColor"])
    borderWidth = (args?["borderWidth"] as? NSNumber).map { CGFloat(truncating: $0) } ?? 0
  }

  private static func looksLikeSvg(_ data: Data) -> Bool {
    let header = data.prefix(2048)
    guard let headerString = String(data: header, encoding: .utf8)?.lowercased() else {
      return false
    }
    return headerString.contains("<svg")
  }

  /// Returns `(data, isIconData)`. `isIconData` is true for Flutter-rasterized
  /// iconData PNGs, which need alpha-trimming to compensate for canvas padding.
  private func preferredImageData() -> (data: Data, isIconData: Bool)? {
    if let assetIconPng { return (assetIconPng, false) }
    if let iconDataPng { return (iconDataPng, true) }
    return nil
  }

  private func resizedImageIfNeeded(_ image: UIImage, trimAlpha: Bool) -> UIImage {
    let targetSize = iconSize
    guard targetSize > 0, image.size.width > 0, image.size.height > 0 else { return image }

    let sourceImage = trimAlpha ? trimmedImageByAlphaBounds(image) : image
    guard sourceImage.size.width > 0, sourceImage.size.height > 0 else { return image }

    let rendererSize = CGSize(width: targetSize, height: targetSize)
    let rendererFormat = UIGraphicsImageRendererFormat.default()
    rendererFormat.scale = max(sourceImage.scale, UIScreen.main.scale)
    let renderer = UIGraphicsImageRenderer(size: rendererSize, format: rendererFormat)

    let scale = min(targetSize / sourceImage.size.width, targetSize / sourceImage.size.height)
    let drawSize = CGSize(
      width: sourceImage.size.width * scale, height: sourceImage.size.height * scale)
    let drawRect = CGRect(
      x: (targetSize - drawSize.width) / 2,
      y: (targetSize - drawSize.height) / 2,
      width: drawSize.width,
      height: drawSize.height
    )
    return renderer.image { ctx in
      ctx.cgContext.interpolationQuality = .high
      sourceImage.draw(in: drawRect)
    }
  }

  private func decodeImage(from data: Data, isIconData: Bool) -> UIImage? {
    // Try raster first (PNG/JPEG). For SVG assets UIImage(data:) will fail,
    // falling through to the SVGKit path.
    if let rasterImage = UIImage(data: data) {
      return resizedImageIfNeeded(rasterImage, trimAlpha: isIconData)
    }
    // SVG asset.
    //
    // We deliberately do **not** call `svgImage.size = <small target>`
    // before `uiImage`. SVGKit's size setter recomputes the CALayer
    // tree with the resulting affine scale, and when the viewBox is
    // wide (e.g. `0 0 1000 1000`) against a tiny target (e.g. 20pt)
    // the ~0.02 scale factor crashes during render on some content
    // (transforms, gradients, path numerics). Letting SVGKit render
    // at the SVG's natural viewBox size and then scaling with UIKit
    // in `resizedImageIfNeeded` is crash-safe and produces the same
    // visual result.
    guard Self.looksLikeSvg(data) else { return nil }
    guard let svgImage = SVGKImage(data: data),
      let image = svgImage.uiImage,
      image.size.width > 0, image.size.height > 0
    else { return nil }
    return resizedImageIfNeeded(image, trimAlpha: false)
  }

  /// Trims fully-transparent padding from all four edges of a raster image.
  private func trimmedImageByAlphaBounds(_ image: UIImage) -> UIImage {
    guard let cgImage = image.cgImage else { return image }
    let width = cgImage.width
    let height = cgImage.height
    guard width > 0, height > 0 else { return image }

    guard let alphaIndex = alphaComponentIndex(for: cgImage.alphaInfo),
      let dataProvider = cgImage.dataProvider,
      let data = dataProvider.data,
      let bytes = CFDataGetBytePtr(data)
    else { return image }

    let bytesPerPixel = cgImage.bitsPerPixel / 8
    let bytesPerRow = cgImage.bytesPerRow
    guard bytesPerPixel >= 4 else { return image }

    var minX = width
    var minY = height
    var maxX = -1
    var maxY = -1

    for y in 0..<height {
      let rowOffset = y * bytesPerRow
      for x in 0..<width {
        let alpha = bytes[rowOffset + x * bytesPerPixel + alphaIndex]
        if alpha == 0 { continue }
        if x < minX { minX = x }
        if x > maxX { maxX = x }
        if y < minY { minY = y }
        if y > maxY { maxY = y }
      }
    }

    guard maxX >= minX, maxY >= minY else { return image }
    if minX == 0, minY == 0, maxX == width - 1, maxY == height - 1 { return image }

    let cropRect = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
    guard let croppedCg = cgImage.cropping(to: cropRect) else { return image }
    return UIImage(cgImage: croppedCg, scale: image.scale, orientation: image.imageOrientation)
  }

  private func alphaComponentIndex(for alphaInfo: CGImageAlphaInfo) -> Int? {
    switch alphaInfo {
    case .premultipliedFirst, .first, .noneSkipFirst: return 0
    case .premultipliedLast, .last, .noneSkipLast: return 3
    default: return nil
    }
  }

  func resolvedImage() -> UIImage? {
    if let (data, isIconData) = preferredImageData(),
      let image = decodeImage(from: data, isIconData: isIconData)
    {
      return image.withRenderingMode(.alwaysTemplate)
    }
    guard let sfSymbolName else { return nil }
    let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .semibold)
    return UIImage(systemName: sfSymbolName, withConfiguration: symbolConfiguration)?
      .withRenderingMode(.alwaysTemplate)
  }
}
