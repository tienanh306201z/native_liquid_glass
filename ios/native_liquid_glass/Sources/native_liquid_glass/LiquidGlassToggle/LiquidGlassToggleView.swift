import Flutter
import SwiftUI
import UIKit

/// Platform-view bridge for native toggle with Liquid Glass effects.
final class LiquidGlassTogglePlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let methodChannel: FlutterMethodChannel

  // iOS 26+ SwiftUI path
  private var viewModel: Any?
  private var hostingController: UIViewController?

  // Pre-iOS 26 UIKit path
  private var toggle: UISwitch?

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .clear

    methodChannel = FlutterMethodChannel(
      name: "liquid-glass-toggle-view/\(viewId)",
      binaryMessenger: messenger
    )

    super.init()

    if #available(iOS 26.0, *) {
      configureSwiftUI(args: args)
    } else {
      configureLegacyUIKit(args: args)
    }

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

  // MARK: - SwiftUI path (iOS 26+)

  @available(iOS 26.0, *)
  private func configureSwiftUI(args: [String: Any]?) {
    let vm = LiquidGlassToggleViewModel()
    vm.isOn = (args?["value"] as? Bool) ?? false
    vm.enabled = (args?["enabled"] as? Bool) ?? true
    vm.tintColor = Self.decodeColor(from: args?["color"]).map { Color(uiColor: $0) }

    vm.onChanged = { [weak self] newValue in
      self?.methodChannel.invokeMethod("valueChanged", arguments: newValue)
    }

    self.viewModel = vm

    let swiftUIView = LiquidGlassToggleSwiftUIView(viewModel: vm)
    let hc = UIHostingController(rootView: swiftUIView)
    hc.view.backgroundColor = .clear
    hc.view.translatesAutoresizingMaskIntoConstraints = false

    containerView.addSubview(hc.view)
    NSLayoutConstraint.activate([
      hc.view.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      hc.view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])

    self.hostingController = hc
  }

  // MARK: - Legacy UIKit path (pre-iOS 26)

  private func configureLegacyUIKit(args: [String: Any]?) {
    let uiToggle = UISwitch()
    uiToggle.translatesAutoresizingMaskIntoConstraints = false
    uiToggle.isOn = (args?["value"] as? Bool) ?? false
    uiToggle.isEnabled = (args?["enabled"] as? Bool) ?? true
    if let color = Self.decodeColor(from: args?["color"]) {
      uiToggle.onTintColor = color
    }
    uiToggle.addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)

    self.toggle = uiToggle
    containerView.addSubview(uiToggle)
    NSLayoutConstraint.activate([
      uiToggle.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      uiToggle.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])
  }

  @objc
  private func handleValueChanged() {
    guard let toggle else { return }
    methodChannel.invokeMethod("valueChanged", arguments: toggle.isOn)
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
          let value = args["value"] as? Bool
        {
          let animated = (args["animated"] as? Bool) ?? false
          if #available(iOS 26.0, *),
            let vm = self.viewModel as? LiquidGlassToggleViewModel
          {
            if animated {
              withAnimation { vm.isOn = value }
            } else {
              vm.isOn = value
            }
          } else {
            self.toggle?.setOn(value, animated: animated)
          }
        }
        result(nil)

      case "setEnabled":
        if let args = call.arguments as? [String: Any],
          let enabled = args["enabled"] as? Bool
        {
          if #available(iOS 26.0, *),
            let vm = self.viewModel as? LiquidGlassToggleViewModel
          {
            vm.enabled = enabled
          } else {
            self.toggle?.isEnabled = enabled
          }
        }
        result(nil)

      case "setColor":
        if let args = call.arguments as? [String: Any] {
          let color = Self.decodeColor(from: args["color"])
          if #available(iOS 26.0, *),
            let vm = self.viewModel as? LiquidGlassToggleViewModel
          {
            vm.tintColor = color.map { Color(uiColor: $0) }
          } else {
            self.toggle?.onTintColor = color
          }
        }
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
