import Flutter
import SwiftUI
import UIKit

// MARK: - Platform View Bridge

/// Platform-view bridge for Liquid Glass container widgets.
final class LiquidGlassContainerPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let methodChannel: FlutterMethodChannel
  private var hostingController: UIHostingController<AnyView>?
  private var viewModel: AnyObject?  // type-erased; actual type is LiquidGlassContainerViewModel (iOS 26+)
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
      name: "liquid-glass-container-view/\(viewId)",
      binaryMessenger: messenger
    )

    super.init()
    suppressObserver = GlassSuppressObserver(view: containerView)

    setupGlassView(args: args)
    setupMethodChannelHandler()
  }

  func view() -> UIView {
    containerView
  }

  // MARK: - Setup (called once)

  private func setupGlassView(args: [String: Any]?) {
    if #available(iOS 26.0, *) {
      let vm = LiquidGlassContainerViewModel()
      vm.update(from: args, animated: false)
      self.viewModel = vm

      let swiftUIView = LiquidGlassContainerSwiftUIView(viewModel: vm)

      let hc = UIHostingController(rootView: AnyView(swiftUIView))
      hc.view.backgroundColor = .clear
      hc.view.translatesAutoresizingMaskIntoConstraints = false
      // The glass material's drop shadow can extend slightly past the
      // shape's bounds; don't clip it at the host view boundary.
      hc.view.clipsToBounds = false
      hc.view.layer.masksToBounds = false

      containerView.addSubview(hc.view)
      NSLayoutConstraint.activate([
        hc.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
        hc.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        hc.view.topAnchor.constraint(equalTo: containerView.topAnchor),
        hc.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
      ])

      hostingController = hc
    }
    // Pre-iOS 26: transparent view (no glass effect)
  }

  // MARK: - Update (called on config changes)

  private func updateGlassEffect(args: [String: Any]?, animated: Bool) {
    if #available(iOS 26.0, *) {
      if let vm = viewModel as? LiquidGlassContainerViewModel {
        vm.update(from: args, animated: animated)
      }
    }
  }

  // MARK: - Method Channel

  private func setupMethodChannelHandler() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "updateConfig":
        let args = call.arguments as? [String: Any]
        let animated = (args?["animated"] as? Bool) ?? false
        self.updateGlassEffect(args: args, animated: animated)
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
