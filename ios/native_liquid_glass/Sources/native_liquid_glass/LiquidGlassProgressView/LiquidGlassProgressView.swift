import Flutter
import UIKit

/// Platform-view bridge for native UIProgressView.
final class LiquidGlassProgressViewPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let methodChannel: FlutterMethodChannel
  private let progressView: UIProgressView
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
      name: "liquid-glass-progress-view/\(viewId)",
      binaryMessenger: messenger
    )

    progressView = UIProgressView(progressViewStyle: .default)
    progressView.translatesAutoresizingMaskIntoConstraints = false
    progressView.progress = (args?["progress"] as? NSNumber)?.floatValue ?? 0

    super.init()
    suppressObserver = GlassSuppressObserver(view: containerView)

    if let pt = Self.decodeColor(from: args?["progressTintColor"]) {
      progressView.progressTintColor = pt
    }
    if let tt = Self.decodeColor(from: args?["trackTintColor"]) {
      progressView.trackTintColor = tt
    }

    containerView.addSubview(progressView)
    NSLayoutConstraint.activate([
      progressView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      progressView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      progressView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])

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
      case "setProgress":
        if let args = call.arguments as? [String: Any],
          let progress = (args["progress"] as? NSNumber)?.floatValue
        {
          self.progressView.setProgress(progress, animated: true)
        }
        result(nil)

      case "setColors":
        if let args = call.arguments as? [String: Any] {
          if let pt = Self.decodeColor(from: args["progressTintColor"]) {
            self.progressView.progressTintColor = pt
          }
          if let tt = Self.decodeColor(from: args["trackTintColor"]) {
            self.progressView.trackTintColor = tt
          }
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
