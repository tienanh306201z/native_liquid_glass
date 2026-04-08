import Flutter
import SVGKit
import UIKit

/// Platform-view bridge for native UIToolbar with Liquid Glass effects.
final class LiquidGlassToolbarPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let toolbar: UIToolbar
  private let methodChannel: FlutterMethodChannel

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .clear
    containerView.clipsToBounds = true

    toolbar = UIToolbar()
    toolbar.translatesAutoresizingMaskIntoConstraints = false

    methodChannel = FlutterMethodChannel(
      name: "liquid-glass-toolbar-view/\(viewId)",
      binaryMessenger: messenger
    )

    super.init()

    configureToolbar(args: args)
    setupMethodChannelHandler()
  }

  func view() -> UIView {
    containerView
  }

  // MARK: - Color decoding

  private static func decodeColor(from value: Any?) -> UIColor? {
    guard let numericValue = value as? NSNumber else { return nil }
    let argb = UInt32(bitPattern: Int32(truncatingIfNeeded: numericValue.intValue))
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
    let red = CGFloat((argb >> 16) & 0xFF) / 255.0
    let green = CGFloat((argb >> 8) & 0xFF) / 255.0
    let blue = CGFloat(argb & 0xFF) / 255.0
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }

  private static func decodeData(from value: Any?) -> Data? {
    if let typedData = value as? FlutterStandardTypedData {
      return typedData.data
    }
    return value as? Data
  }

  private static func looksLikeSvg(_ data: Data) -> Bool {
    let header = data.prefix(2048)
    guard let headerString = String(data: header, encoding: .utf8)?.lowercased() else {
      return false
    }
    return headerString.contains("<svg")
  }

  private static func scaleImage(_ image: UIImage, to pointSize: Double, cropToAlpha: Bool)
    -> UIImage
  {
    // The PNG is rasterized on a larger canvas (e.g. 64×64) with the glyph
    // centred and padded.  Compensate by finding the tight content bounding
    // box and scaling *that* to the target size so the icon matches the
    // apparent size of an SF Symbol at the same pointSize.
    let source = cropToAlpha ? (cropToContent(image) ?? image) : image
    let size = CGSize(width: pointSize, height: pointSize)
    let format = UIGraphicsImageRendererFormat.default()
    format.scale = UIScreen.main.scale
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { context in
      context.cgContext.interpolationQuality = .high
      source.draw(in: CGRect(origin: .zero, size: size))
    }
  }

  private static func decodeToolbarImage(
    iconDataPng: Data?, assetData: Data?, iconPointSize: Double
  )
    -> UIImage?
  {
    if let assetData {
      if looksLikeSvg(assetData), let svg = SVGKImage(data: assetData) {
        svg.size = CGSize(width: iconPointSize, height: iconPointSize)
        if let rendered = svg.uiImage {
          return rendered.withRenderingMode(.alwaysTemplate)
        }
      }
      if let rasterImage = UIImage(data: assetData) {
        return scaleImage(rasterImage, to: iconPointSize, cropToAlpha: false)
          .withRenderingMode(.alwaysTemplate)
      }
    }

    if let iconDataPng, let rasterImage = UIImage(data: iconDataPng) {
      return scaleImage(rasterImage, to: iconPointSize, cropToAlpha: true)
        .withRenderingMode(.alwaysTemplate)
    }

    return nil
  }

  /// Returns the image cropped to the smallest rect that contains all
  /// non-transparent pixels, or nil if the image is fully transparent.
  private static func cropToContent(_ image: UIImage) -> UIImage? {
    guard let cgImage = image.cgImage else { return nil }
    let width = cgImage.width
    let height = cgImage.height
    guard width > 0, height > 0 else { return nil }

    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
    guard
      let context = CGContext(
        data: nil,
        width: width, height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: bitmapInfo.rawValue
      )
    else { return nil }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    guard let data = context.data else { return nil }
    let pixels = data.bindMemory(to: UInt8.self, capacity: width * height * 4)

    var minX = width
    var maxX = 0
    var minY = height
    var maxY = 0
    for y in 0..<height {
      for x in 0..<width {
        let alpha = pixels[(y * width + x) * 4 + 3]
        if alpha > 10 {  // ignore near-transparent fringe
          if x < minX { minX = x }
          if x > maxX { maxX = x }
          if y < minY { minY = y }
          if y > maxY { maxY = y }
        }
      }
    }

    guard minX <= maxX, minY <= maxY else { return nil }

    let imageScale = image.scale
    guard
      let croppedCG = cgImage.cropping(
        to: CGRect(
          x: minX, y: minY,
          width: maxX - minX + 1,
          height: maxY - minY + 1
        ))
    else { return nil }
    return UIImage(cgImage: croppedCG, scale: imageScale, orientation: image.imageOrientation)
  }

  private static func mapSymbolWeight(_ name: String?) -> UIImage.SymbolWeight {
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

  private static func mapUIFontWeight(_ value: Int) -> UIFont.Weight {
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

  private static func resolveFont(from args: [String: Any]) -> UIFont? {
    let fontSize = (args["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
    let fontWeight = (args["fontWeight"] as? NSNumber)?.intValue
    let fontFamily = (args["fontFamily"] as? String)?.trimmingCharacters(
      in: .whitespacesAndNewlines)

    let pointSize = fontSize ?? 17.0

    if let fontFamily, !fontFamily.isEmpty,
      let customFont = UIFont(name: fontFamily, size: pointSize)
    {
      return customFont
    }
    if let fontWeight {
      return UIFont.systemFont(ofSize: pointSize, weight: mapUIFontWeight(fontWeight))
    }
    if fontSize != nil {
      return UIFont.systemFont(ofSize: pointSize)
    }
    return nil
  }

  // MARK: - Toolbar configuration

  @objc
  private func handleItemTapped(_ sender: UIBarButtonItem) {
    let id = sender.accessibilityIdentifier ?? ""
    methodChannel.invokeMethod("itemTapped", arguments: id)
  }

  private func configureToolbar(args: [String: Any]?) {
    applyToolbarStyle(args: args)
    toolbar.items = buildBarItems(from: args)

    containerView.addSubview(toolbar)
    // Pin toolbar edges but let it use its intrinsic height.
    // The container clips to bounds so Flutter controls visible height.
    NSLayoutConstraint.activate([
      toolbar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      toolbar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      toolbar.topAnchor.constraint(equalTo: containerView.topAnchor),
    ])
  }

  private func applyToolbarStyle(args: [String: Any]?) {
    let tintColor = Self.decodeColor(from: args?["tintColor"])
    let backgroundColor = Self.decodeColor(from: args?["backgroundColor"])
    let translucent = (args?["translucent"] as? Bool) ?? true
    let shadowColor = Self.decodeColor(from: args?["shadowColor"])

    toolbar.tintColor = tintColor ?? UIView().tintColor
    toolbar.isTranslucent = translucent

    let appearance = UIToolbarAppearance()
    if translucent {
      appearance.configureWithDefaultBackground()
    } else {
      appearance.configureWithOpaqueBackground()
    }

    appearance.backgroundColor = backgroundColor
    appearance.shadowColor = shadowColor

    // Apply label text style
    if let labelStyleArgs = args?["labelStyle"] as? [String: Any] {
      let font = Self.resolveFont(from: labelStyleArgs)
      let letterSpacing = (labelStyleArgs["letterSpacing"] as? NSNumber).map {
        CGFloat(truncating: $0)
      }
      if font != nil || letterSpacing != nil {
        var normalAttrs: [NSAttributedString.Key: Any] = [:]
        if let font { normalAttrs[.font] = font }
        if let letterSpacing { normalAttrs[.kern] = letterSpacing }
        appearance.buttonAppearance.normal.titleTextAttributes = normalAttrs
        appearance.doneButtonAppearance.normal.titleTextAttributes = normalAttrs
      }
    }

    toolbar.standardAppearance = appearance
    if #available(iOS 15.0, *) {
      toolbar.scrollEdgeAppearance = appearance
      toolbar.compactAppearance = appearance
    }
  }

  private func buildBarItems(from args: [String: Any]?) -> [UIBarButtonItem] {
    let itemDicts = (args?["items"] as? [[String: Any]]) ?? []
    let defaultWeight = Self.mapSymbolWeight(args?["iconWeight"] as? String)

    var barItems: [UIBarButtonItem] = []
    for dict in itemDicts {
      let isSpacer = (dict["spacer"] as? Bool) ?? false
      if isSpacer {
        let flexible = (dict["flexible"] as? Bool) ?? true
        let spacer =
          flexible
          ? UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
          : UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        if !flexible {
          spacer.width = CGFloat((dict["width"] as? NSNumber)?.doubleValue ?? 16)
        }
        barItems.append(spacer)
        continue
      }

      let id = (dict["id"] as? String) ?? ""
      let sfSymbol = dict["sfSymbol"] as? String
      let label = dict["label"] as? String
      let enabled = (dict["enabled"] as? Bool) ?? true
      let iconSize = (dict["iconSize"] as? NSNumber)?.doubleValue
      let itemTintColor = Self.decodeColor(from: dict["tintColor"])
      let isDone = (dict["style"] as? String) == "done"

      let item: UIBarButtonItem
      if let sfSymbol {
        let size = iconSize ?? 20
        let cfg = UIImage.SymbolConfiguration(pointSize: size, weight: defaultWeight)
        let image = UIImage(systemName: sfSymbol, withConfiguration: cfg)
        item = UIBarButtonItem(
          image: image, style: isDone ? .done : .plain,
          target: self, action: #selector(handleItemTapped(_:))
        )
        // UIBarButtonItem only shows image OR title. Set title for accessibility.
        if let label {
          item.accessibilityLabel = label
        }
      } else if let image = Self.decodeToolbarImage(
        iconDataPng: Self.decodeData(from: dict["iconDataPng"]),
        assetData: Self.decodeData(from: dict["assetIconPng"]),
        iconPointSize: iconSize ?? 24
      ) {
        let size = iconSize ?? 24
        item = UIBarButtonItem(
          image: image,
          style: isDone ? .done : .plain,
          target: self, action: #selector(handleItemTapped(_:))
        )
        if let label {
          item.accessibilityLabel = label
        }
      } else {
        item = UIBarButtonItem(
          title: label ?? id, style: isDone ? .done : .plain,
          target: self, action: #selector(handleItemTapped(_:))
        )
      }

      item.accessibilityIdentifier = id
      item.isEnabled = enabled
      if let itemTintColor {
        item.tintColor = itemTintColor
      }

      barItems.append(item)
    }
    return barItems
  }

  // MARK: - Method channel

  private func setupMethodChannelHandler() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "updateToolbar":
        let args = call.arguments as? [String: Any]
        self.applyToolbarStyle(args: args)
        self.toolbar.items = self.buildBarItems(from: args)
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
