import Flutter
import SwiftUI
import UIKit

/// Platform-view bridge for native segmented control with Liquid Glass effects.
final class LiquidGlassSegmentedControlPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let methodChannel: FlutterMethodChannel

  // iOS 26+ SwiftUI path
  private var viewModel: Any?
  private var hostingController: UIViewController?

  // Pre-iOS 26 UIKit path
  private var segmentedControl: UISegmentedControl?
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
      name: "liquid-glass-segmented-control-view/\(viewId)",
      binaryMessenger: messenger
    )

    super.init()
    suppressObserver = GlassSuppressObserver(view: containerView)

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
    let vm = LiquidGlassSegmentedControlViewModel()
    applySegmentParams(args, to: vm)
    vm.selection = (args?["selectedIndex"] as? NSNumber)?.intValue ?? 0
    vm.enabled = (args?["enabled"] as? Bool) ?? true
    vm.tintColor = Self.decodeColor(from: args?["color"]).map { Color(uiColor: $0) }

    vm.onChanged = { [weak self] newIndex in
      self?.methodChannel.invokeMethod("valueChanged", arguments: newIndex)
    }

    self.viewModel = vm

    let swiftUIView = LiquidGlassSegmentedControlSwiftUIView(viewModel: vm)
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

  @available(iOS 26.0, *)
  private func applySegmentParams(
    _ args: [String: Any]?, to vm: LiquidGlassSegmentedControlViewModel
  ) {
    vm.labels = (args?["labels"] as? [String]) ?? []
  }

  // MARK: - Legacy UIKit path (pre-iOS 26)

  private func configureLegacyUIKit(args: [String: Any]?) {
    let sc = UISegmentedControl()
    sc.translatesAutoresizingMaskIntoConstraints = false
    self.segmentedControl = sc

    rebuildLegacySegments(from: args, control: sc)

    let selectedIndex = (args?["selectedIndex"] as? NSNumber)?.intValue ?? 0
    if selectedIndex >= 0, selectedIndex < sc.numberOfSegments {
      sc.selectedSegmentIndex = selectedIndex
    }
    sc.isEnabled = (args?["enabled"] as? Bool) ?? true
    if let color = Self.decodeColor(from: args?["color"]) {
      sc.selectedSegmentTintColor = color
    }

    sc.addTarget(self, action: #selector(handleValueChanged), for: .valueChanged)

    containerView.addSubview(sc)
    NSLayoutConstraint.activate([
      sc.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
      sc.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
      sc.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])
  }

  private func rebuildLegacySegments(
    from args: [String: Any]?, control sc: UISegmentedControl? = nil
  ) {
    guard let sc = sc ?? self.segmentedControl else { return }
    let labels = (args?["labels"] as? [String]) ?? []
    sc.removeAllSegments()
    for (i, label) in labels.enumerated() {
      sc.insertSegment(withTitle: label, at: i, animated: false)
    }
  }

  @objc
  private func handleValueChanged() {
    guard let sc = segmentedControl else { return }
    methodChannel.invokeMethod("valueChanged", arguments: sc.selectedSegmentIndex)
  }

  // MARK: - Method channel

  private func setupMethodChannelHandler() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "updateSegments":
        let args = call.arguments as? [String: Any]
        if #available(iOS 26.0, *),
          let vm = self.viewModel as? LiquidGlassSegmentedControlViewModel
        {
          self.applySegmentParams(args, to: vm)
        } else {
          self.rebuildLegacySegments(from: args)
        }
        result(nil)

      case "setSelectedIndex":
        if let args = call.arguments as? [String: Any],
          let index = (args["index"] as? NSNumber)?.intValue
        {
          let animated = (args["animated"] as? Bool) ?? true
          if #available(iOS 26.0, *),
            let vm = self.viewModel as? LiquidGlassSegmentedControlViewModel
          {
            if animated {
              withAnimation { vm.selection = index }
            } else {
              vm.selection = index
            }
          } else if let sc = self.segmentedControl {
            if animated {
              UIView.animate(withDuration: 0.2) {
                sc.selectedSegmentIndex = index
              }
            } else {
              sc.selectedSegmentIndex = index
            }
          }
        }
        result(nil)

      case "setEnabled":
        if let args = call.arguments as? [String: Any],
          let enabled = args["enabled"] as? Bool
        {
          if #available(iOS 26.0, *),
            let vm = self.viewModel as? LiquidGlassSegmentedControlViewModel
          {
            vm.enabled = enabled
          } else if let sc = self.segmentedControl {
            sc.isEnabled = enabled
            UIView.animate(withDuration: 0.2) {
              sc.alpha = enabled ? 1.0 : 0.4
            }
          }
        }
        result(nil)

      case "setColor":
        if let args = call.arguments as? [String: Any] {
          let color = Self.decodeColor(from: args["color"])
          if #available(iOS 26.0, *),
            let vm = self.viewModel as? LiquidGlassSegmentedControlViewModel
          {
            vm.tintColor = color.map { Color(uiColor: $0) }
          } else {
            self.segmentedControl?.selectedSegmentTintColor = color
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
