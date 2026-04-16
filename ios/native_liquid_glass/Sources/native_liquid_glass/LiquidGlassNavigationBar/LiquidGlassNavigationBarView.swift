import Flutter
import UIKit

/// Platform-view bridge for native UINavigationBar with Liquid Glass effects.
final class LiquidGlassNavigationBarPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let navigationBar: UINavigationBar
  private let methodChannel: FlutterMethodChannel
  private var suppressObserver: GlassSuppressObserver?

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: [String: Any]?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .clear

    navigationBar = UINavigationBar()
    navigationBar.translatesAutoresizingMaskIntoConstraints = false

    methodChannel = FlutterMethodChannel(
      name: "liquid-glass-navigation-bar-view/\(viewId)",
      binaryMessenger: messenger
    )

    super.init()
    suppressObserver = GlassSuppressObserver(view: containerView)

    configureBar(args: args)
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

  private func makeBarButtonItem(from dict: [String: Any]) -> UIBarButtonItem {
    let id = (dict["id"] as? String) ?? ""
    let sfSymbol = dict["sfSymbol"] as? String
    let label = dict["label"] as? String
    let iconSize = (dict["iconSize"] as? NSNumber)?.doubleValue

    let item: UIBarButtonItem
    if let sfSymbol {
      let image: UIImage?
      if let size = iconSize {
        let cfg = UIImage.SymbolConfiguration(pointSize: size, weight: .regular)
        image = UIImage(systemName: sfSymbol, withConfiguration: cfg)
      } else {
        image = UIImage(systemName: sfSymbol)
      }
      item = UIBarButtonItem(
        image: image, style: .plain,
        target: self, action: #selector(handleItemTapped(_:))
      )
    } else {
      item = UIBarButtonItem(
        title: label ?? id, style: .plain,
        target: self, action: #selector(handleItemTapped(_:))
      )
    }
    // Store the id for identification in the tap handler
    item.accessibilityIdentifier = id
    return item
  }

  @objc
  private func handleItemTapped(_ sender: UIBarButtonItem) {
    let id = sender.accessibilityIdentifier ?? ""
    methodChannel.invokeMethod("itemTapped", arguments: id)
  }

  private func configureBar(args: [String: Any]?) {
    let title = (args?["title"] as? String) ?? ""
    let largeTitle = (args?["largeTitle"] as? Bool) ?? false
    let leadingItems = (args?["leadingItems"] as? [[String: Any]]) ?? []
    let trailingItems = (args?["trailingItems"] as? [[String: Any]]) ?? []
    let backgroundColor = Self.decodeColor(from: args?["backgroundColor"])
    let tintColor = Self.decodeColor(from: args?["tintColor"])
    let titleStyle = LiquidGlassNavigationBarConfig.LabelStyle(
      arguments: args?["titleStyle"] as? [String: Any])

    let navItem = UINavigationItem(title: title)
    navItem.leftBarButtonItems = leadingItems.map { makeBarButtonItem(from: $0) }
    navItem.rightBarButtonItems = trailingItems.map { makeBarButtonItem(from: $0) }

    if largeTitle {
      navigationBar.prefersLargeTitles = true
      navItem.largeTitleDisplayMode = .always
    }

    navigationBar.items = [navItem]

    if let tintColor {
      navigationBar.tintColor = tintColor
    }

    let hasAppearanceChanges = backgroundColor != nil || titleStyle != nil
    if hasAppearanceChanges {
      let appearance = UINavigationBarAppearance()
      if let backgroundColor { appearance.backgroundColor = backgroundColor }
      if let titleFont = titleStyle?.resolvedFont() {
        var titleAttrs: [NSAttributedString.Key: Any] = [.font: titleFont]
        if let spacing = titleStyle?.letterSpacing { titleAttrs[.kern] = spacing }
        appearance.titleTextAttributes = titleAttrs
        if largeTitle {
          appearance.largeTitleTextAttributes = titleAttrs
        }
      }
      navigationBar.standardAppearance = appearance
      navigationBar.scrollEdgeAppearance = appearance
    }

    containerView.addSubview(navigationBar)
    NSLayoutConstraint.activate([
      navigationBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      navigationBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      navigationBar.topAnchor.constraint(equalTo: containerView.topAnchor),
      navigationBar.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])
  }

  private func setupMethodChannelHandler() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "setTitle":
        if let args = call.arguments as? [String: Any],
          let title = args["title"] as? String
        {
          self.navigationBar.topItem?.title = title
        }
        result(nil)

      case "setStyle":
        if let args = call.arguments as? [String: Any] {
          if let tintColor = Self.decodeColor(from: args["tintColor"]) {
            self.navigationBar.tintColor = tintColor
          }
          let appearance = self.navigationBar.standardAppearance
          if let backgroundColor = Self.decodeColor(from: args["backgroundColor"]) {
            appearance.backgroundColor = backgroundColor
          }
          if let titleStyleArgs = args["titleStyle"] as? [String: Any] {
            let config = LiquidGlassNavigationBarConfig.LabelStyle(arguments: titleStyleArgs)
            if let titleFont = config?.resolvedFont() {
              var titleAttrs: [NSAttributedString.Key: Any] = [.font: titleFont]
              if let spacing = config?.letterSpacing { titleAttrs[.kern] = spacing }
              appearance.titleTextAttributes = titleAttrs
            }
          }
          self.navigationBar.standardAppearance = appearance
          self.navigationBar.scrollEdgeAppearance = appearance
        }
        result(nil)

      case "setItems":
        if let args = call.arguments as? [String: Any] {
          let leadingItems = (args["leadingItems"] as? [[String: Any]]) ?? []
          let trailingItems = (args["trailingItems"] as? [[String: Any]]) ?? []
          self.navigationBar.topItem?.leftBarButtonItems = leadingItems.map {
            self.makeBarButtonItem(from: $0)
          }
          self.navigationBar.topItem?.rightBarButtonItems = trailingItems.map {
            self.makeBarButtonItem(from: $0)
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
