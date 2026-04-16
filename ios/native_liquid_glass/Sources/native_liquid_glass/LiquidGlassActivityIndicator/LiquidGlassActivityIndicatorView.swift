import Flutter
import UIKit

/// Platform-view bridge for native UIActivityIndicatorView.
final class LiquidGlassActivityIndicatorPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let methodChannel: FlutterMethodChannel
  private let indicator: UIActivityIndicatorView
  private var suppressObserver: GlassSuppressObserver?

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .clear

    methodChannel = FlutterMethodChannel(
      name: "liquid-glass-activity-indicator-view/\(viewId)",
      binaryMessenger: messenger
    )

    let styleName = args?["style"] as? String ?? "medium"
    let style: UIActivityIndicatorView.Style = styleName == "large" ? .large : .medium
    indicator = UIActivityIndicatorView(style: style)
    indicator.translatesAutoresizingMaskIntoConstraints = false
    indicator.hidesWhenStopped = (args?["hidesWhenStopped"] as? Bool) ?? true

    super.init()
    suppressObserver = GlassSuppressObserver(view: containerView)

    if let color = Self.decodeColor(from: args?["color"]) {
      indicator.color = color
    }

    containerView.addSubview(indicator)
    NSLayoutConstraint.activate([
      indicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      indicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])

    if (args?["animating"] as? Bool) ?? true {
      indicator.startAnimating()
    }

    setupMethodChannelHandler()
  }

  func view() -> UIView { containerView }

  private static func decodeColor(from value: Any?) -> UIColor? {
    guard let numericValue = value as? NSNumber else { return nil }
    let argb = UInt32(bitPattern: Int32(truncatingIfNeeded: numericValue.intValue))
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
    let red = CGFloat((argb >> 16) & 0xFF) / 255.0
    let green = CGFloat((argb >> 8) & 0xFF) / 255.0
    let blue = CGFloat(argb & 0xFF) / 255.0
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }

  private func setupMethodChannelHandler() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "setAnimating":
        if let args = call.arguments as? [String: Any],
          let animating = args["animating"] as? Bool
        {
          if animating {
            self.indicator.startAnimating()
          } else {
            self.indicator.stopAnimating()
          }
        }
        result(nil)

      case "setColor":
        if let args = call.arguments as? [String: Any],
          let color = Self.decodeColor(from: args["color"])
        {
          self.indicator.color = color
        }
        result(nil)

      case "setSuppressed":
        let suppressed = (call.arguments as? [String: Any])?["suppressed"] as? Bool ?? false
        self.suppressObserver?.setRouteSuppressed(suppressed)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
