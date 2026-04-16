import Flutter
import SwiftUI
import UIKit

/// Platform-view bridge for Liquid Glass button widgets.
final class LiquidGlassButtonPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let methodChannel: FlutterMethodChannel
  private let defaultIconOnly: Bool

  // SwiftUI path (iOS 16+)
  private var viewModel: AnyObject?
  private var hostingController: UIViewController?

  // UIKit legacy path (iOS < 16)
  private var legacyButton: UIButton?
  private var legacyConfig: LiquidGlassButtonConfig?
  private var suppressObserver: GlassSuppressObserver?

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: [String: Any]?,
    messenger: FlutterBinaryMessenger,
    defaultIconOnly: Bool
  ) {
    self.defaultIconOnly = defaultIconOnly

    methodChannel = FlutterMethodChannel(
      name:
        "\(defaultIconOnly ? "liquid-glass-icon-button-view" : "liquid-glass-button-view")/\(viewId)",
      binaryMessenger: messenger
    )

    containerView = UIView(frame: frame)
    containerView.backgroundColor = .clear
    containerView.clipsToBounds = false

    super.init()
    suppressObserver = GlassSuppressObserver(view: containerView)

    if #available(iOS 16.0, *) {
      configureSwiftUI(args: args)
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
        if #available(iOS 16.0, *) {
          self.hostingController?.view.setNeedsLayout()
          self.hostingController?.view.layoutIfNeeded()
          let size =
            self.hostingController?.view.systemLayoutSizeFitting(
              UIView.layoutFittingCompressedSize)
            ?? CGSize(width: 100, height: 50)
          result(["width": Double(size.width), "height": Double(size.height)])
        } else {
          self.legacyButton?.setNeedsLayout()
          self.legacyButton?.layoutIfNeeded()
          let size = self.legacyButton?.intrinsicContentSize ?? CGSize(width: 100, height: 50)
          result(["width": Double(size.width), "height": Double(size.height)])
        }

      case "updateConfig":
        let newArgs = call.arguments as? [String: Any]
        let newConfig = LiquidGlassButtonConfig(
          arguments: newArgs, defaultIconOnly: self.defaultIconOnly)
        if #available(iOS 16.0, *) {
          if let vm = self.viewModel as? LiquidGlassButtonViewModel {
            vm.config = newConfig
          }
          DispatchQueue.main.async {
            self.hostingController?.view.setNeedsLayout()
            self.hostingController?.view.layoutIfNeeded()
            let size =
              self.hostingController?.view.systemLayoutSizeFitting(
                UIView.layoutFittingCompressedSize)
              ?? CGSize(width: 100, height: 50)
            result(["width": Double(size.width), "height": Double(size.height)])
          }
        } else {
          self.legacyConfig = newConfig
          self.applyLegacyConfiguration()
          self.legacyButton?.setNeedsLayout()
          self.legacyButton?.layoutIfNeeded()
          let size = self.legacyButton?.intrinsicContentSize ?? CGSize(width: 100, height: 50)
          result(["width": Double(size.width), "height": Double(size.height)])
        }

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

  // MARK: - SwiftUI setup (iOS 16+)

  @available(iOS 16.0, *)
  private func configureSwiftUI(args: [String: Any]?) {
    let config = LiquidGlassButtonConfig(arguments: args, defaultIconOnly: defaultIconOnly)
    let vm = LiquidGlassButtonViewModel(config: config)
    vm.onPressed = { [weak self] in
      self?.methodChannel.invokeMethod("onPressed", arguments: nil)
    }
    self.viewModel = vm

    let swiftUIView = LiquidGlassButtonRootView(viewModel: vm)
    let hc = UIHostingController(rootView: swiftUIView)
    hc.view.backgroundColor = .clear
    hc.view.translatesAutoresizingMaskIntoConstraints = false

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

  // MARK: - UIKit legacy setup (iOS < 16)

  private func configureLegacyUIKit(args: [String: Any]?) {
    let config = LiquidGlassButtonConfig(arguments: args, defaultIconOnly: defaultIconOnly)
    self.legacyConfig = config

    let button = UIButton(type: .system)
    button.translatesAutoresizingMaskIntoConstraints = false
    button.backgroundColor = .clear
    button.isEnabled = config.enabled
    button.addTarget(self, action: #selector(handleLegacyButtonTap), for: .touchUpInside)

    self.legacyButton = button
    containerView.addSubview(button)
    NSLayoutConstraint.activate([
      button.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      button.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      button.topAnchor.constraint(equalTo: containerView.topAnchor),
      button.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    applyLegacyConfiguration()
  }

  private func applyLegacyConfiguration() {
    guard let config = legacyConfig, let button = legacyButton else { return }

    let resolvedBackgroundColor = (config.tint ?? button.tintColor).withAlphaComponent(0.22)
    let resolvedForegroundColor = config.foregroundColor ?? config.iconColor ?? .label

    button.backgroundColor = resolvedBackgroundColor
    button.tintColor = config.iconColor ?? resolvedForegroundColor
    button.setTitleColor(resolvedForegroundColor, for: .normal)
    button.isEnabled = config.enabled

    if config.iconOnly {
      button.setTitle(nil, for: .normal)
      button.contentEdgeInsets = .zero
      button.imageEdgeInsets = .zero
      button.titleEdgeInsets = .zero
    } else {
      button.setTitle(config.title ?? "Button", for: .normal)
      button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
      let halfPadding = config.imagePadding / 2
      button.imageEdgeInsets = UIEdgeInsets(
        top: 0, left: -halfPadding, bottom: 0, right: halfPadding)
      button.titleEdgeInsets = UIEdgeInsets(
        top: 0, left: halfPadding, bottom: 0, right: -halfPadding)
    }

    button.setImage(config.resolvedImage(), for: .normal)
    button.layer.cornerRadius = min(config.height / 2, config.iconOnly ? config.height / 2 : 16)
    button.clipsToBounds = true
  }

  @objc
  private func handleLegacyButtonTap() {
    methodChannel.invokeMethod("onPressed", arguments: nil)
  }
}
