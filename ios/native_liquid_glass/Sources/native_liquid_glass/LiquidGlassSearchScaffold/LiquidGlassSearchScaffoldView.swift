import Flutter
import UIKit

/// Platform-view bridge for a native UITabBarController with inline search
/// (UISearchTab on iOS 26+).
///
/// Uses LiquidGlassTabBarConfig for full tab bar customization parity
/// with the standalone LiquidGlassTabBar.
final class LiquidGlassSearchScaffoldPlatformView: NSObject, FlutterPlatformView,
  UISearchBarDelegate
{
  private let containerView: UIView
  private let methodChannel: FlutterMethodChannel
  private weak var hostViewController: UIViewController?
  private var nativeTabBarView: LiquidGlassNativeTabBarControllerView?
  private var searchController: UISearchController?
  private var searchPlaceholder: String = "Search"

  init(
    frame: CGRect,
    viewId: Int64,
    arguments args: [String: Any]?,
    messenger: FlutterBinaryMessenger,
    hostViewController: UIViewController?
  ) {
    containerView = UIView(frame: frame)
    containerView.backgroundColor = .systemBackground

    methodChannel = FlutterMethodChannel(
      name: "liquid-glass-search-scaffold-view/\(viewId)",
      binaryMessenger: messenger
    )
    self.hostViewController = hostViewController

    super.init()

    configureScaffold(args: args)
    setupMethodChannelHandler()
  }

  func view() -> UIView {
    containerView
  }

  private func configureScaffold(args: [String: Any]?) {
    let searchHint = (args?["searchHint"] as? String) ?? "Search"
    let searchEnabled = (args?["searchEnabled"] as? Bool) ?? true
    searchPlaceholder = searchHint

    // Parse tab bar config using the same config as standalone TabBar
    let config = LiquidGlassTabBarConfig(arguments: args)

    let nativeView = LiquidGlassNativeTabBarControllerView(
      config: config,
      onTabSelected: { [weak self] index in
        self?.methodChannel.invokeMethod("tabChanged", arguments: index)
      },
      onActionButtonPressed: { [weak self] in
        self?.methodChannel.invokeMethod("actionButtonPressed", arguments: nil)
      }
    )
    nativeView.translatesAutoresizingMaskIntoConstraints = false

    // Attach search to the tab bar controller
    if searchEnabled {
      attachSearch(
        to: nativeView.tabBarController,
        placeholder: searchHint
      )
    }

    // Attach to host view controller for proper containment
    nativeView.attach(to: hostViewController)

    containerView.addSubview(nativeView)
    NSLayoutConstraint.activate([
      nativeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      nativeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      nativeView.topAnchor.constraint(equalTo: containerView.topAnchor),
      nativeView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    self.nativeTabBarView = nativeView
  }

  private func attachSearch(
    to tabBarController: UITabBarController,
    placeholder: String
  ) {
    let search = UISearchController(searchResultsController: nil)
    search.searchBar.placeholder = placeholder
    search.searchBar.delegate = self
    search.obscuresBackgroundDuringPresentation = false
    searchController = search

    guard var vcs = tabBarController.viewControllers, !vcs.isEmpty else { return }
    let firstVC = vcs[0]

    if let navVC = firstVC as? UINavigationController,
      let rootVC = navVC.viewControllers.first
    {
      // Already wrapped — just re-attach the search controller
      rootVC.navigationItem.searchController = search
      rootVC.navigationItem.hidesSearchBarWhenScrolling = false
    } else {
      // First time — wrap in a navigation controller
      let navVC = UINavigationController(rootViewController: firstVC)
      navVC.tabBarItem = firstVC.tabBarItem
      firstVC.navigationItem.searchController = search
      firstVC.navigationItem.hidesSearchBarWhenScrolling = false
      vcs[0] = navVC
      tabBarController.viewControllers = vcs
    }
  }

  private func updateTabBarStyle(args: [String: Any]) {
    guard let tabBarController = nativeTabBarView?.tabBarController else { return }
    let tabBar = tabBarController.tabBar

    // Update selected item color
    let selectedItemColor = Self.decodeColor(from: args["selectedItemColor"])
    tabBar.tintColor = selectedItemColor
    tabBarController.view.tintColor = selectedItemColor

    // Update show labels
    let showLabels = (args["showLabels"] as? Bool) ?? true
    for vc in tabBarController.viewControllers ?? [] {
      if showLabels {
        // Restore label from accessibility label
        vc.tabBarItem.title = vc.tabBarItem.accessibilityLabel
      } else {
        vc.tabBarItem.title = nil
      }
    }

    // Update label style
    if let labelStyleArgs = args["labelStyle"] as? [String: Any] {
      let labelStyle = LiquidGlassTabBarConfig.LabelStyle(arguments: labelStyleArgs)
      if let font = labelStyle?.resolvedFont() {
        var normalAttrs: [NSAttributedString.Key: Any] = [.font: font]
        var selectedAttrs: [NSAttributedString.Key: Any] = [.font: font]
        if let spacing = labelStyle?.letterSpacing {
          normalAttrs[.kern] = spacing
          selectedAttrs[.kern] = spacing
        }
        if let selectedItemColor {
          selectedAttrs[.foregroundColor] = selectedItemColor
        }
        for vc in tabBarController.viewControllers ?? [] {
          vc.tabBarItem.setTitleTextAttributes(normalAttrs, for: .normal)
          vc.tabBarItem.setTitleTextAttributes(selectedAttrs, for: .selected)
        }
      }
    }

    // Update appearance
    let appearance = UITabBarAppearance()
    appearance.configureWithDefaultBackground()
    if let selectedItemColor {
      for layout in [
        appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance,
        appearance.compactInlineLayoutAppearance,
      ] {
        layout.selected.iconColor = selectedItemColor
        var attrs = layout.selected.titleTextAttributes
        attrs[.foregroundColor] = selectedItemColor
        layout.selected.titleTextAttributes = attrs
      }
    }
    tabBar.standardAppearance = appearance
    if #available(iOS 15.0, *) {
      tabBar.scrollEdgeAppearance = appearance
    }
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

  private func setSearchVisible(_ visible: Bool) {
    guard let tabBarController = nativeTabBarView?.tabBarController else { return }

    if visible && searchController == nil {
      attachSearch(to: tabBarController, placeholder: searchPlaceholder)
    } else if !visible, let search = searchController {
      search.isActive = false
      // Remove search from the first tab's navigation item
      if let navVC = tabBarController.viewControllers?.first as? UINavigationController,
        let rootVC = navVC.viewControllers.first
      {
        rootVC.navigationItem.searchController = nil
      }
      searchController = nil
    }
  }

  // MARK: - UISearchBarDelegate

  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    methodChannel.invokeMethod("searchChanged", arguments: searchText)
  }

  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    methodChannel.invokeMethod("searchSubmitted", arguments: searchBar.text ?? "")
  }

  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    methodChannel.invokeMethod("searchActiveChanged", arguments: true)
  }

  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    methodChannel.invokeMethod("searchActiveChanged", arguments: false)
  }

  // MARK: - Method Channel

  private func setupMethodChannelHandler() {
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self else {
        result(FlutterMethodNotImplemented)
        return
      }

      switch call.method {
      case "setSelectedTab":
        if let args = call.arguments as? [String: Any],
          let index = (args["index"] as? NSNumber)?.intValue
        {
          self.nativeTabBarView?.setSelectedIndex(index)
        }
        result(nil)

      case "updateStyle":
        if let args = call.arguments as? [String: Any] {
          self.updateTabBarStyle(args: args)
        }
        result(nil)

      case "setSearchEnabled":
        if let args = call.arguments as? [String: Any],
          let enabled = args["enabled"] as? Bool
        {
          self.setSearchVisible(enabled)
        }
        result(nil)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
