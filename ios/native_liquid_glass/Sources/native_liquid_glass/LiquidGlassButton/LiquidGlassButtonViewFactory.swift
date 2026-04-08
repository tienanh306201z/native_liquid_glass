import Flutter
import UIKit

/// Registers and builds native Liquid Glass button platform views.
final class LiquidGlassButtonViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  private let defaultIconOnly: Bool

  init(messenger: FlutterBinaryMessenger, defaultIconOnly: Bool) {
    self.messenger = messenger
    self.defaultIconOnly = defaultIconOnly
    super.init()
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    LiquidGlassButtonPlatformView(
      frame: frame,
      viewId: viewId,
      arguments: args as? [String: Any],
      messenger: messenger,
      defaultIconOnly: defaultIconOnly
    )
  }
}
