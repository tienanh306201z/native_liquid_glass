import Flutter
import UIKit

/// Shared singleton that handles modal presentation (sheets, alerts, popovers)
/// via a single plugin-level method channel.
final class LiquidGlassPresenter: NSObject {
  private let messenger: FlutterBinaryMessenger
  private weak var hostViewController: UIViewController?
  private let methodChannel: FlutterMethodChannel
  private var presentedPopovers: [Int: UIViewController] = [:]
  private var presentedSheets: [Int: UIViewController] = [:]

  init(messenger: FlutterBinaryMessenger, hostViewController: UIViewController?) {
    self.messenger = messenger
    self.hostViewController = hostViewController
    self.methodChannel = FlutterMethodChannel(
      name: "liquid-glass-presenter",
      binaryMessenger: messenger
    )
    super.init()
    setupHandler()
  }

  private func findHostVC() -> UIViewController? {
    var vc = hostViewController
      ?? UIApplication.shared.connectedScenes
        .compactMap({ $0 as? UIWindowScene })
        .flatMap({ $0.windows })
        .first(where: { $0.isKeyWindow })?
        .rootViewController
    // Walk to the topmost presented controller so action sheets
    // present correctly from Flutter's view hierarchy.
    while let presented = vc?.presentedViewController {
      vc = presented
    }
    return vc
  }

  private func setupHandler() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "showSheet":
        self.handleShowSheet(call: call, result: result)
      case "dismissSheet":
        self.handleDismissSheet(call: call, result: result)
      case "showAlert":
        self.handleShowAlert(call: call, result: result)
      case "showPopover":
        self.handleShowPopover(call: call, result: result)
      case "dismissPopover":
        self.handleDismissPopover(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // MARK: - Sheet

  private func handleShowSheet(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let id = (args["id"] as? NSNumber)?.intValue,
      let host = findHostVC()
    else {
      result(FlutterError(code: "NO_HOST", message: "No host view controller", details: nil))
      return
    }

    let title = args["title"] as? String
    let message = args["message"] as? String
    let detentsRaw = args["detents"] as? [String] ?? ["medium", "large"]
    let prefersGrabberVisible = (args["prefersGrabberVisible"] as? Bool) ?? true
    let isModal = (args["isModal"] as? Bool) ?? false

    let contentVC = UIViewController()
    contentVC.view.backgroundColor = .systemBackground

    // Add title/message labels if provided
    var yOffset: CGFloat = 24
    if let title {
      let label = UILabel()
      label.text = title
      label.font = .preferredFont(forTextStyle: .headline)
      label.translatesAutoresizingMaskIntoConstraints = false
      contentVC.view.addSubview(label)
      NSLayoutConstraint.activate([
        label.topAnchor.constraint(equalTo: contentVC.view.topAnchor, constant: yOffset),
        label.leadingAnchor.constraint(equalTo: contentVC.view.leadingAnchor, constant: 20),
        label.trailingAnchor.constraint(equalTo: contentVC.view.trailingAnchor, constant: -20),
      ])
      yOffset += 36
    }
    if let message {
      let label = UILabel()
      label.text = message
      label.font = .preferredFont(forTextStyle: .body)
      label.numberOfLines = 0
      label.translatesAutoresizingMaskIntoConstraints = false
      contentVC.view.addSubview(label)
      NSLayoutConstraint.activate([
        label.topAnchor.constraint(equalTo: contentVC.view.topAnchor, constant: yOffset),
        label.leadingAnchor.constraint(equalTo: contentVC.view.leadingAnchor, constant: 20),
        label.trailingAnchor.constraint(equalTo: contentVC.view.trailingAnchor, constant: -20),
      ])
    }

    if #available(iOS 15.0, *), let sheet = contentVC.sheetPresentationController {
      var detents: [UISheetPresentationController.Detent] = []
      for d in detentsRaw {
        switch d {
        case "medium": detents.append(.medium())
        case "large": detents.append(.large())
        default: detents.append(.medium())
        }
      }
      sheet.detents = detents
      sheet.prefersGrabberVisible = prefersGrabberVisible
    }
    contentVC.isModalInPresentation = isModal

    presentedSheets[id] = contentVC
    host.present(contentVC, animated: true) {
      result(nil)
    }
  }

  private func handleDismissSheet(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let id = (args["id"] as? NSNumber)?.intValue,
      let vc = presentedSheets[id]
    else {
      result(nil)
      return
    }

    vc.dismiss(animated: true) { [weak self] in
      self?.presentedSheets.removeValue(forKey: id)
      self?.methodChannel.invokeMethod("sheetDismissed", arguments: ["id": id])
      result(nil)
    }
  }

  // MARK: - Alert

  private func handleShowAlert(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let host = findHostVC()
    else {
      result(FlutterError(code: "NO_HOST", message: "No host view controller", details: nil))
      return
    }

    let title = args["title"] as? String
    let message = args["message"] as? String
    let styleIndex = (args["style"] as? NSNumber)?.intValue ?? 0
    let alertStyle: UIAlertController.Style = styleIndex == 1 ? .actionSheet : .alert
    let actions = (args["actions"] as? [[String: Any]]) ?? []

    let alert = UIAlertController(title: title, message: message, preferredStyle: alertStyle)

    for action in actions {
      let actionTitle = (action["title"] as? String) ?? "OK"
      let actionId = (action["id"] as? String) ?? actionTitle
      let isDestructive = (action["isDestructive"] as? Bool) ?? false
      let isCancel = (action["isCancel"] as? Bool) ?? false

      let style: UIAlertAction.Style
      if isCancel {
        style = .cancel
      } else if isDestructive {
        style = .destructive
      } else {
        style = .default
      }

      alert.addAction(
        UIAlertAction(title: actionTitle, style: style) { [weak self] _ in
          self?.methodChannel.invokeMethod("alertActionSelected", arguments: ["actionId": actionId])
        })
    }

    // Add default OK if no actions
    if actions.isEmpty {
      alert.addAction(
        UIAlertAction(title: "OK", style: .default) { [weak self] _ in
          self?.methodChannel.invokeMethod("alertActionSelected", arguments: ["actionId": "ok"])
        })
    }

    // On iPad, action sheets require a popover source; fall back to center of host view.
    if alertStyle == .actionSheet, let popover = alert.popoverPresentationController {
      popover.sourceView = host.view
      popover.sourceRect = CGRect(
        x: host.view.bounds.midX,
        y: host.view.bounds.midY,
        width: 0,
        height: 0
      )
      popover.permittedArrowDirections = []
    }

    host.present(alert, animated: true) {
      result(nil)
    }
  }

  // MARK: - Popover

  private func handleShowPopover(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let id = (args["id"] as? NSNumber)?.intValue,
      let host = findHostVC()
    else {
      result(FlutterError(code: "NO_HOST", message: "No host view controller", details: nil))
      return
    }

    let anchorX = (args["anchorX"] as? NSNumber)?.doubleValue ?? 0
    let anchorY = (args["anchorY"] as? NSNumber)?.doubleValue ?? 0
    let anchorWidth = (args["anchorWidth"] as? NSNumber)?.doubleValue ?? 0
    let anchorHeight = (args["anchorHeight"] as? NSNumber)?.doubleValue ?? 0
    let preferredWidth = (args["preferredWidth"] as? NSNumber)?.doubleValue ?? 320
    let preferredHeight = (args["preferredHeight"] as? NSNumber)?.doubleValue ?? 200

    let contentVC = UIViewController()
    contentVC.view.backgroundColor = .systemBackground
    contentVC.preferredContentSize = CGSize(width: preferredWidth, height: preferredHeight)
    contentVC.modalPresentationStyle = .popover

    if let popover = contentVC.popoverPresentationController {
      popover.sourceView = host.view
      popover.sourceRect = CGRect(
        x: anchorX, y: anchorY,
        width: anchorWidth, height: anchorHeight
      )
      popover.delegate = PopoverDelegateProxy(presenter: self, id: id)
    }

    presentedPopovers[id] = contentVC
    host.present(contentVC, animated: true) {
      result(nil)
    }
  }

  private func handleDismissPopover(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
      let id = (args["id"] as? NSNumber)?.intValue,
      let vc = presentedPopovers[id]
    else {
      result(nil)
      return
    }

    vc.dismiss(animated: true) { [weak self] in
      self?.presentedPopovers.removeValue(forKey: id)
      result(nil)
    }
  }

  fileprivate func popoverDidDismiss(id: Int) {
    presentedPopovers.removeValue(forKey: id)
    methodChannel.invokeMethod("popoverDismissed", arguments: ["id": id])
  }
}

// MARK: - Popover Delegate Proxy

private final class PopoverDelegateProxy: NSObject, UIPopoverPresentationControllerDelegate {
  private weak var presenter: LiquidGlassPresenter?
  private let id: Int

  init(presenter: LiquidGlassPresenter, id: Int) {
    self.presenter = presenter
    self.id = id
    super.init()
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    presenter?.popoverDidDismiss(id: id)
  }
}
