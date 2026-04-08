import Flutter
import UIKit

/// Platform-view bridge for native UIColorWell with Liquid Glass effects.
///
/// UIColorWell shows an inline color swatch that, when tapped, opens the
/// system color picker (UIColorPickerViewController) automatically.
@available(iOS 14.0, *)
final class LiquidGlassColorPickerPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let colorWell: UIColorWell
  private let methodChannel: FlutterMethodChannel

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .clear

    colorWell = UIColorWell()
    colorWell.translatesAutoresizingMaskIntoConstraints = false

    methodChannel = FlutterMethodChannel(
      name: "liquid-glass-color-picker-view/\(viewId)",
      binaryMessenger: messenger
    )

    super.init()

    configureColorWell(args: args)
    setupMethodChannelHandler()
  }

  func view() -> UIView {
    containerView
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

  private static func encodeColor(_ color: UIColor) -> Int {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    color.getRed(&r, green: &g, blue: &b, alpha: &a)
    let ai = Int(a * 255) & 0xFF
    let ri = Int(r * 255) & 0xFF
    let gi = Int(g * 255) & 0xFF
    let bi = Int(b * 255) & 0xFF
    return (ai << 24) | (ri << 16) | (gi << 8) | bi
  }

  private func configureColorWell(args: [String: Any]?) {
    if let color = Self.decodeColor(from: args?["color"]) {
      colorWell.selectedColor = color
    }

    if let title = args?["title"] as? String {
      colorWell.title = title
    }

    if let supportsAlpha = args?["supportsAlpha"] as? Bool {
      colorWell.supportsAlpha = supportsAlpha
    }

    colorWell.addTarget(self, action: #selector(handleColorChanged), for: .valueChanged)

    containerView.addSubview(colorWell)
    NSLayoutConstraint.activate([
      colorWell.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      colorWell.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
      colorWell.widthAnchor.constraint(equalToConstant: 44),
      colorWell.heightAnchor.constraint(equalToConstant: 44),
    ])
  }

  @objc
  private func handleColorChanged() {
    if let color = colorWell.selectedColor {
      methodChannel.invokeMethod("colorChanged", arguments: Self.encodeColor(color))
    }
  }

  private func setupMethodChannelHandler() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "setColor":
        if let args = call.arguments as? [String: Any],
          let color = Self.decodeColor(from: args["color"])
        {
          self.colorWell.selectedColor = color
        }
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
