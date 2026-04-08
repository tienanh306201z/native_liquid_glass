import Flutter
import UIKit

/// Registers and builds native Liquid Glass search-scaffold platform views.
final class LiquidGlassSearchScaffoldViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  private weak var hostViewController: UIViewController?

  init(messenger: FlutterBinaryMessenger, hostViewController: UIViewController?) {
    self.messenger = messenger
    self.hostViewController = hostViewController
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
    LiquidGlassSearchScaffoldPlatformView(
      frame: frame,
      viewId: viewId,
      arguments: args as? [String: Any],
      messenger: messenger,
      hostViewController: hostViewController
    )
  }
}
