import Flutter
import UIKit

/// Platform-view bridge for native UIStepper with Liquid Glass effects.
final class LiquidGlassStepperPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let methodChannel: FlutterMethodChannel
  private let stepper: UIStepper
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
      name: "liquid-glass-stepper-view/\(viewId)",
      binaryMessenger: messenger
    )

    stepper = UIStepper()
    stepper.translatesAutoresizingMaskIntoConstraints = false

    super.init()
    suppressObserver = GlassSuppressObserver(view: containerView)

    configure(with: args)
    stepper.addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)

    containerView.addSubview(stepper)
    NSLayoutConstraint.activate([
      stepper.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      stepper.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])

    setupMethodChannelHandler()
  }

  func view() -> UIView { containerView }

  // MARK: - Configuration

  private func configure(with args: [String: Any]?) {
    stepper.minimumValue = (args?["min"] as? NSNumber)?.doubleValue ?? 0
    stepper.maximumValue = (args?["max"] as? NSNumber)?.doubleValue ?? 100
    stepper.stepValue = (args?["step"] as? NSNumber)?.doubleValue ?? 1
    stepper.value = (args?["value"] as? NSNumber)?.doubleValue ?? 0
    stepper.wraps = (args?["wraps"] as? Bool) ?? false
    stepper.isEnabled = (args?["enabled"] as? Bool) ?? true

    if let color = Self.decodeColor(from: args?["color"]) {
      stepper.tintColor = color
    }
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

  @objc
  private func handleValueChanged() {
    methodChannel.invokeMethod("valueChanged", arguments: stepper.value)
  }

  // MARK: - Method channel

  private func setupMethodChannelHandler() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "setValue":
        if let args = call.arguments as? [String: Any],
          let value = (args["value"] as? NSNumber)?.doubleValue
        {
          self.stepper.value = value
        }
        result(nil)

      case "setRange":
        if let args = call.arguments as? [String: Any] {
          if let min = (args["min"] as? NSNumber)?.doubleValue {
            self.stepper.minimumValue = min
          }
          if let max = (args["max"] as? NSNumber)?.doubleValue {
            self.stepper.maximumValue = max
          }
          if let step = (args["step"] as? NSNumber)?.doubleValue {
            self.stepper.stepValue = step
          }
        }
        result(nil)

      case "setWraps":
        if let args = call.arguments as? [String: Any],
          let wraps = args["wraps"] as? Bool
        {
          self.stepper.wraps = wraps
        }
        result(nil)

      case "setEnabled":
        if let args = call.arguments as? [String: Any],
          let enabled = args["enabled"] as? Bool
        {
          self.stepper.isEnabled = enabled
        }
        result(nil)

      case "setColor":
        if let args = call.arguments as? [String: Any],
          let color = Self.decodeColor(from: args["color"])
        {
          self.stepper.tintColor = color
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
