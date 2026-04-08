import Flutter
import SwiftUI
import UIKit

/// Platform-view bridge for native slider with Liquid Glass effects.
final class LiquidGlassSliderPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let methodChannel: FlutterMethodChannel

  // iOS 26+ SwiftUI path
  private var viewModel: Any?
  private var hostingController: UIViewController?

  // Pre-iOS 26 UIKit path
  private var slider: UISlider?
  private var step: Float?

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .clear

    methodChannel = FlutterMethodChannel(
      name: "liquid-glass-slider-view/\(viewId)",
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
    let vm = LiquidGlassSliderViewModel()
    vm.value = (args?["value"] as? NSNumber)?.doubleValue ?? 0
    vm.minValue = (args?["min"] as? NSNumber)?.doubleValue ?? 0
    vm.maxValue = (args?["max"] as? NSNumber)?.doubleValue ?? 1
    if let stepValue = (args?["step"] as? NSNumber)?.doubleValue, stepValue > 0 {
      vm.step = stepValue
    }
    vm.enabled = (args?["enabled"] as? Bool) ?? true

    // SwiftUI Slider uses .tint() — prefer trackColor > color
    let trackColor = Self.decodeColor(from: args?["trackColor"])
    let color = Self.decodeColor(from: args?["color"])
    vm.tintColor = (trackColor ?? color).map { Color(uiColor: $0) }

    vm.onChanged = { [weak self] newValue in
      self?.methodChannel.invokeMethod("valueChanged", arguments: newValue)
    }

    self.viewModel = vm

    let swiftUIView = LiquidGlassSliderSwiftUIView(viewModel: vm)
    let hc = UIHostingController(rootView: swiftUIView)
    hc.view.backgroundColor = .clear
    hc.view.translatesAutoresizingMaskIntoConstraints = false

    containerView.addSubview(hc.view)
    NSLayoutConstraint.activate([
      hc.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      hc.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      hc.view.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])

    self.hostingController = hc
  }

  // MARK: - Legacy UIKit path (pre-iOS 26)

  private func configureLegacyUIKit(args: [String: Any]?) {
    let uiSlider = UISlider()
    uiSlider.translatesAutoresizingMaskIntoConstraints = false
    uiSlider.minimumValue = (args?["min"] as? NSNumber)?.floatValue ?? 0
    uiSlider.maximumValue = (args?["max"] as? NSNumber)?.floatValue ?? 1
    uiSlider.value = (args?["value"] as? NSNumber)?.floatValue ?? 0
    uiSlider.isEnabled = (args?["enabled"] as? Bool) ?? true

    if let stepValue = (args?["step"] as? NSNumber)?.floatValue, stepValue > 0 {
      step = stepValue
    }

    if let color = Self.decodeColor(from: args?["color"]) {
      uiSlider.minimumTrackTintColor = color
    }
    if let thumbColor = Self.decodeColor(from: args?["thumbColor"]) {
      uiSlider.thumbTintColor = thumbColor
    }
    if let trackColor = Self.decodeColor(from: args?["trackColor"]) {
      uiSlider.minimumTrackTintColor = trackColor
    }
    if let trackBgColor = Self.decodeColor(from: args?["trackBackgroundColor"]) {
      uiSlider.maximumTrackTintColor = trackBgColor
    }

    uiSlider.addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)

    self.slider = uiSlider
    containerView.addSubview(uiSlider)
    NSLayoutConstraint.activate([
      uiSlider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      uiSlider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      uiSlider.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])
  }

  @objc
  private func handleValueChanged() {
    guard let slider else { return }
    var value = slider.value
    if let step, step > 0 {
      value = (value / step).rounded() * step
      slider.value = value
    }
    methodChannel.invokeMethod("valueChanged", arguments: Double(value))
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
          let animated = (args["animated"] as? Bool) ?? false
          if #available(iOS 26.0, *),
            let vm = self.viewModel as? LiquidGlassSliderViewModel
          {
            if animated {
              withAnimation { vm.value = value }
            } else {
              vm.value = value
            }
          } else {
            self.slider?.setValue(Float(value), animated: animated)
          }
        }
        result(nil)

      case "setRange":
        if let args = call.arguments as? [String: Any],
          let min = (args["min"] as? NSNumber)?.doubleValue,
          let max = (args["max"] as? NSNumber)?.doubleValue
        {
          if #available(iOS 26.0, *),
            let vm = self.viewModel as? LiquidGlassSliderViewModel
          {
            vm.minValue = min
            vm.maxValue = max
          } else {
            self.slider?.minimumValue = Float(min)
            self.slider?.maximumValue = Float(max)
          }
        }
        result(nil)

      case "setEnabled":
        if let args = call.arguments as? [String: Any],
          let enabled = args["enabled"] as? Bool
        {
          if #available(iOS 26.0, *),
            let vm = self.viewModel as? LiquidGlassSliderViewModel
          {
            vm.enabled = enabled
          } else {
            self.slider?.isEnabled = enabled
          }
        }
        result(nil)

      case "setStep":
        if let args = call.arguments as? [String: Any] {
          if let stepValue = (args["step"] as? NSNumber)?.doubleValue, stepValue > 0 {
            if #available(iOS 26.0, *),
              let vm = self.viewModel as? LiquidGlassSliderViewModel
            {
              vm.step = stepValue
            }
            self.step = Float(stepValue)
          } else {
            if #available(iOS 26.0, *),
              let vm = self.viewModel as? LiquidGlassSliderViewModel
            {
              vm.step = nil
            }
            self.step = nil
          }
        }
        result(nil)

      case "setStyle":
        if let args = call.arguments as? [String: Any] {
          if #available(iOS 26.0, *),
            let vm = self.viewModel as? LiquidGlassSliderViewModel
          {
            let trackColor = Self.decodeColor(from: args["trackColor"])
            let color = Self.decodeColor(from: args["color"])
            if let c = trackColor ?? color {
              vm.tintColor = Color(uiColor: c)
            }
          }
          // UIKit path
          if let slider = self.slider {
            if let color = Self.decodeColor(from: args["color"]) {
              slider.minimumTrackTintColor = color
            }
            if let thumbColor = Self.decodeColor(from: args["thumbColor"]) {
              slider.thumbTintColor = thumbColor
            }
            if let trackColor = Self.decodeColor(from: args["trackColor"]) {
              slider.minimumTrackTintColor = trackColor
            }
            if let trackBgColor = Self.decodeColor(from: args["trackBackgroundColor"]) {
              slider.maximumTrackTintColor = trackBgColor
            }
          }
        }
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
