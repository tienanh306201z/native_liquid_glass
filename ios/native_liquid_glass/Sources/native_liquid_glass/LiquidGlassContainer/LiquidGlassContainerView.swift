import Flutter
import SwiftUI
import UIKit

// MARK: - Platform View Bridge

/// Platform-view bridge for Liquid Glass container widgets.
final class LiquidGlassContainerPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let methodChannel: FlutterMethodChannel
  private var hostingController: UIHostingController<AnyView>?

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

    applyGlassEffect(args: args)
    setupMethodChannelHandler()
  }

  func view() -> UIView {
    containerView
  }

  private static func decodeColor(from value: Any?) -> UIColor? {
    guard let numericValue = value as? NSNumber else {
      return nil
    }

    let argb = UInt32(bitPattern: Int32(truncatingIfNeeded: numericValue.intValue))
    let alpha = CGFloat((argb >> 24) & 0xFF) / 255.0
    let red = CGFloat((argb >> 16) & 0xFF) / 255.0
    let green = CGFloat((argb >> 8) & 0xFF) / 255.0
    let blue = CGFloat(argb & 0xFF) / 255.0

    return UIColor(red: red, green: green, blue: blue, alpha: alpha)
  }

  private func applyGlassEffect(args: [String: Any]?) {
    // Remove previous hosting controller
    hostingController?.view.removeFromSuperview()
    hostingController = nil

    if #available(iOS 26.0, *) {
      let effectStr = (args?["effect"] as? String) ?? "regular"
      let shapeStr = (args?["shape"] as? String) ?? "rect"
      let cornerRadius = (args?["cornerRadius"] as? NSNumber)?.doubleValue
      let interactive = (args?["interactive"] as? Bool) ?? false
      let tint = Self.decodeColor(from: args?["tint"])
      let unionId = args?["glassEffectUnionId"] as? String
      let effectId = args?["glassEffectId"] as? String

      let swiftUIView = LiquidGlassContainerSwiftUIView(
        effect: effectStr,
        shape: shapeStr,
        cornerRadius: cornerRadius.map { CGFloat($0) },
        tint: tint,
        interactive: interactive,
        glassEffectUnionId: (unionId?.isEmpty == false) ? unionId : nil,
        glassEffectId: (effectId?.isEmpty == false) ? effectId : nil
      )

      let hc = UIHostingController(rootView: AnyView(swiftUIView))
      hc.view.backgroundColor = .clear
      hc.view.translatesAutoresizingMaskIntoConstraints = false

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

  private func setupMethodChannelHandler() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "updateConfig":
        let args = call.arguments as? [String: Any]
        self.applyGlassEffect(args: args)
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
