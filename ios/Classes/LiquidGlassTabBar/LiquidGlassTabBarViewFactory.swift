import Flutter
import UIKit

final class LiquidGlassTabBarViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger
  private weak var hostViewController: UIViewController?

  init(messenger: FlutterBinaryMessenger, hostViewController: UIViewController?) {
    self.messenger = messenger
    self.hostViewController = hostViewController
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    LiquidGlassTabBarPlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      messenger: messenger,
      hostViewController: hostViewController
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}
