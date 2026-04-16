import Flutter
import SwiftUI
import UIKit

// MARK: - Platform view bridge

/// Platform-view bridge for grouped Liquid Glass buttons with unified glass blending.
final class LiquidGlassButtonGroupPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let methodChannel: FlutterMethodChannel
  private var buttonCallbacks: [Int: (() -> Void)] = [:]

  // iOS 26+ SwiftUI path
  private var viewModel: Any?  // LiquidGlassButtonGroupViewModel
  private var hostingController: UIViewController?

  // Pre-iOS 26 UIKit fallback
  private var uikitButtons: [UIButton] = []
  private var stackView: UIStackView?
  private var suppressObserver: GlassSuppressObserver?

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .clear
    containerView.clipsToBounds = false

    methodChannel = FlutterMethodChannel(
      name: "liquid-glass-button-group-view/\(viewId)",
      binaryMessenger: messenger
    )

    super.init()
    suppressObserver = GlassSuppressObserver(view: containerView)

    let isDark = (args?["isDark"] as? Bool) ?? false

    if #available(iOS 26.0, *) {
      configureSwiftUI(args: args, isDark: isDark)
    } else {
      configureLegacyUIKit(args: args)
    }

    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(nil)
        return
      }
      switch call.method {
      case "getIntrinsicSize":
        if #available(iOS 26.0, *) {
          let hc = self.hostingController
          hc?.view.setNeedsLayout()
          hc?.view.layoutIfNeeded()
          let size =
            hc?.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            ?? CGSize(width: 200, height: 56)
          result(["width": Double(size.width), "height": Double(size.height)])
        } else {
          let sv = self.stackView
          sv?.setNeedsLayout()
          sv?.layoutIfNeeded()
          let size =
            sv?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            ?? CGSize(width: 200, height: 56)
          result(["width": Double(size.width), "height": Double(size.height)])
        }
      case "updateButtons":
        let updateArgs = call.arguments as? [String: Any]
        if #available(iOS 26.0, *) {
          self.updateSwiftUIButtons(updateArgs)
        } else {
          self.stackView?.removeFromSuperview()
          self.stackView = nil
          self.uikitButtons.removeAll()
          self.configureLegacyUIKit(args: updateArgs)
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

  func view() -> UIView {
    containerView
  }

  // MARK: - Arg remapping

  /// Remaps group button dict keys to match LiquidGlassButtonConfig expectations.
  private static func remapButtonArgs(_ dict: [String: Any]) -> [String: Any] {
    var mapped = dict
    if let label = dict["label"] as? String {
      mapped["title"] = label
    }
    // Group buttons default to "glass" style when not specified
    mapped["buttonStyle"] = (dict["style"] as? String) ?? "glass"
    return mapped
  }

  // MARK: - SwiftUI path (iOS 26+)

  @available(iOS 26.0, *)
  private func configureSwiftUI(args: [String: Any]?, isDark: Bool) {
    let vm = LiquidGlassButtonGroupViewModel()
    self.viewModel = vm

    let parsedButtons = Self.parseButtonDicts(
      args?["buttons"] as? [[String: Any]],
      channel: methodChannel,
      callbacks: &buttonCallbacks
    )
    vm.buttons = parsedButtons

    if let axisStr = args?["axis"] as? String {
      vm.axis = axisStr == "horizontal" ? .horizontal : .vertical
    }
    if let spacingValue = args?["spacing"] as? NSNumber {
      vm.spacing = CGFloat(truncating: spacingValue)
    }
    if let spacingForGlassValue = args?["spacingForGlass"] as? NSNumber {
      vm.spacingForGlass = CGFloat(truncating: spacingForGlassValue)
    }

    let swiftUIView = LiquidGlassButtonGroupSwiftUI(viewModel: vm)
    let hc = UIHostingController(rootView: swiftUIView)
    hc.view.backgroundColor = .clear
    hc.view.translatesAutoresizingMaskIntoConstraints = false

    if #available(iOS 13.0, *) {
      hc.overrideUserInterfaceStyle = isDark ? .dark : .light
    }

    containerView.addSubview(hc.view)
    NSLayoutConstraint.activate([
      hc.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      hc.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      hc.view.topAnchor.constraint(equalTo: containerView.topAnchor),
      hc.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    hc.view.setNeedsLayout()
    hc.view.layoutIfNeeded()

    self.hostingController = hc
  }

  @available(iOS 26.0, *)
  private func updateSwiftUIButtons(_ args: [String: Any]?) {
    guard let vm = self.viewModel as? LiquidGlassButtonGroupViewModel else { return }

    let parsedButtons = Self.parseButtonDicts(
      args?["buttons"] as? [[String: Any]],
      channel: methodChannel,
      callbacks: &buttonCallbacks
    )
    vm.updateButtons(parsedButtons)

    if let axisStr = args?["axis"] as? String {
      vm.axis = axisStr == "horizontal" ? .horizontal : .vertical
    }
    if let spacingValue = args?["spacing"] as? NSNumber {
      vm.spacing = CGFloat(truncating: spacingValue)
    }
    if let spacingForGlassValue = args?["spacingForGlass"] as? NSNumber {
      vm.spacingForGlass = CGFloat(truncating: spacingForGlassValue)
    }
  }

  @available(iOS 26.0, *)
  private static func parseButtonDicts(
    _ buttonDicts: [[String: Any]]?,
    channel: FlutterMethodChannel,
    callbacks: inout [Int: (() -> Void)]
  ) -> [LiquidGlassButtonData] {
    guard let buttonDicts else { return [] }
    var result: [LiquidGlassButtonData] = []

    for (index, dict) in buttonDicts.enumerated() {
      let mappedArgs = remapButtonArgs(dict)
      let buttonConfig = LiquidGlassButtonConfig(arguments: mappedArgs, defaultIconOnly: false)

      let buttonIndex = index
      let buttonCallback: () -> Void = {
        channel.invokeMethod("onButtonPressed", arguments: buttonIndex)
      }
      callbacks[buttonIndex] = buttonCallback

      result.append(LiquidGlassButtonData(
        buttonConfig: buttonConfig,
        onPressed: buttonCallback
      ))
    }

    return result
  }

  // MARK: - Legacy UIKit path (pre-iOS 26)

  private static func decodeColor(from value: Any?) -> UIColor? {
    guard let numericValue = value as? NSNumber else { return nil }
    let argb = UInt32(bitPattern: Int32(truncatingIfNeeded: numericValue.intValue))
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
    let red = CGFloat((argb >> 16) & 0xFF) / 255.0
    let green = CGFloat((argb >> 8) & 0xFF) / 255.0
    let blue = CGFloat(argb & 0xFF) / 255.0
    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }

  private func configureLegacyUIKit(args: [String: Any]?) {
    guard let buttonDicts = args?["buttons"] as? [[String: Any]] else { return }
    let isHorizontal = (args?["axis"] as? String) ?? "horizontal" == "horizontal"
    let spacing = CGFloat((args?["spacing"] as? NSNumber)?.doubleValue ?? 8.0)

    let sv = UIStackView()
    sv.axis = isHorizontal ? .horizontal : .vertical
    sv.spacing = spacing
    sv.alignment = .center
    sv.distribution = .fill
    sv.translatesAutoresizingMaskIntoConstraints = false
    self.stackView = sv

    for (index, dict) in buttonDicts.enumerated() {
      let mappedArgs = Self.remapButtonArgs(dict)
      let buttonConfig = LiquidGlassButtonConfig(arguments: mappedArgs, defaultIconOnly: false)

      let button = UIButton(type: .system)
      button.tag = index
      button.isEnabled = buttonConfig.enabled
      button.addTarget(self, action: #selector(handleButtonTap(_:)), for: .touchUpInside)

      if #available(iOS 15.0, *) {
        var configuration = UIButton.Configuration.borderedProminent()
        configuration.cornerStyle = .capsule
        if buttonConfig.iconOnly {
          configuration.title = nil
          configuration.imagePadding = 0
        } else {
          configuration.title = buttonConfig.title ?? "Button"
          configuration.imagePadding = buttonConfig.imagePadding
        }
        configuration.image = buttonConfig.resolvedImage()
        if let tintColor = buttonConfig.tint {
          configuration.baseBackgroundColor = tintColor.withAlphaComponent(0.22)
        }
        button.configuration = configuration
      }

      uikitButtons.append(button)
      sv.addArrangedSubview(button)
    }

    containerView.addSubview(sv)
    NSLayoutConstraint.activate([
      sv.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      sv.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])
  }

  @objc
  private func handleButtonTap(_ sender: UIButton) {
    methodChannel.invokeMethod("onButtonPressed", arguments: sender.tag)
  }
}
