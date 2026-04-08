import UIKit

/// Optional title typography customization for the navigation bar.
struct LiquidGlassNavigationBarConfig {
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
}
