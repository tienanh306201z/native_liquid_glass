import UIKit

/// Optional title typography customization for the navigation bar.
struct LiquidGlassNavigationBarConfig {
  struct LabelStyle {
    let fontSize: CGFloat?
    let fontWeight: UIFont.Weight?
    let fontFamily: String?
    let letterSpacing: CGFloat?
    let color: UIColor?

    init?(arguments args: [String: Any]?) {
      guard let args else { return nil }
      let parsedFontSize = (args["fontSize"] as? NSNumber).map { CGFloat(truncating: $0) }
      let parsedFontWeight = (args["fontWeight"] as? NSNumber).map {
        Self.mapFontWeight($0.intValue)
      }
      let parsedFontFamily = (args["fontFamily"] as? String)?.trimmingCharacters(
        in: .whitespacesAndNewlines)
      let parsedLetterSpacing = (args["letterSpacing"] as? NSNumber).map { CGFloat(truncating: $0) }
      let parsedColor = Self.decodeColor(from: args["color"])
      if parsedFontSize == nil && parsedFontWeight == nil
        && (parsedFontFamily == nil || parsedFontFamily?.isEmpty == true)
        && parsedLetterSpacing == nil && parsedColor == nil
      {
        return nil
      }
      fontSize = parsedFontSize
      fontWeight = parsedFontWeight
      fontFamily = (parsedFontFamily?.isEmpty == false) ? parsedFontFamily : nil
      letterSpacing = parsedLetterSpacing
      color = parsedColor
    }

    private static func decodeColor(from value: Any?) -> UIColor? {
      guard let numericValue = value as? NSNumber else { return nil }
      let argb = UInt32(bitPattern: Int32(truncatingIfNeeded: numericValue.intValue))
      let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
      let red = CGFloat((argb >> 16) & 0xFF) / 255.0
      let green = CGFloat((argb >> 8) & 0xFF) / 255.0
      let blue = CGFloat(argb & 0xFF) / 255.0
      return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Title-attribute dictionary contributed by [color], if set.
    var colorAttributes: [NSAttributedString.Key: Any] {
      guard let color else { return [:] }
      return [.foregroundColor: color]
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
}
