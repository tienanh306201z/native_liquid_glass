import Flutter
import UIKit

/// Hosts and configures a native `UITabBarController` for the Flutter platform view.
///
/// The view is responsible for:
/// - applying tab appearance and layout options from `LiquidGlassTabBarConfig`
/// - embedding the controller's view into this host view
/// - forwarding selection changes back to Flutter
final class LiquidGlassNativeTabBarControllerView: UIView, UITabBarControllerDelegate {
  private static let actionButtonTag = 9999

  private let config: LiquidGlassTabBarConfig
  let tabBarController = UITabBarController()
  private let onTabSelected: (Int) -> Void
  private let onActionButtonPressed: () -> Void
  private let selectedItemColor: UIColor?
  private let selectableTabCount: Int
  private let tabSelectedColors: [UIColor?]
  private var defaultTabBarTintColor: UIColor?

  init(
    config: LiquidGlassTabBarConfig,
    onTabSelected: @escaping (Int) -> Void,
    onActionButtonPressed: @escaping () -> Void
  ) {
    self.config = config
    self.onTabSelected = onTabSelected
    self.onActionButtonPressed = onActionButtonPressed
    self.selectedItemColor = config.selectedItemColor
    self.selectableTabCount = config.tabs.count
    self.tabSelectedColors = config.tabs.map { $0.selectedItemColor ?? config.selectedItemColor }
    super.init(frame: .zero)

    backgroundColor = .clear
    clipsToBounds = false
    isOpaque = false
    layer.isOpaque = false
    configureTabBarController(with: config)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    guard previousTraitCollection != nil else {
      return
    }

    refreshTabBarVisuals()
  }

  /// Re-apply the selected tint whenever this view (re)attaches to a window.
  ///
  /// Flutter navigation push/pop can cause UIKit to re-render the tab bar
  /// using its baked-in `UITabBarAppearance.selected.iconColor`, which
  /// overrides the dynamic per-tab `tintColor` we apply for tabs that set
  /// their own `selectedItemColor`. Re-applying here keeps the per-tab
  /// color stable after navigating away and coming back.
  override func didMoveToWindow() {
    super.didMoveToWindow()

    guard window != nil else {
      return
    }

    applyTintColorForSelectedIndex(
      tabBarController.selectedIndex,
      tabBar: tabBarController.tabBar
    )
  }

  /// Attaches the internal tab bar controller to a parent view controller.
  ///
  /// UIKit requires proper parent-child containment for embedded controllers.
  func attach(to parentViewController: UIViewController?) {
    guard let parentViewController else {
      return
    }

    if tabBarController.parent === parentViewController {
      return
    }

    if tabBarController.parent != nil {
      tabBarController.willMove(toParent: nil)
      tabBarController.removeFromParent()
    }

    parentViewController.addChild(tabBarController)
    tabBarController.didMove(toParent: parentViewController)

    // Re-apply tint after containment changes; iPad can recalculate tab bar
    // rendering when the controller is attached to its final hierarchy.
    applySelectedTintColorHierarchy(selectedItemColor, tabBar: tabBarController.tabBar)
  }

  /// Ensures controller containment is cleaned up when this host view is deallocated.
  deinit {
    if tabBarController.parent != nil {
      tabBarController.willMove(toParent: nil)
      tabBarController.removeFromParent()
    }
  }

  /// Builds and applies native tab bar UI from parsed config.
  ///
  /// Order matters:
  /// 1) create tab view controllers/items
  /// 2) configure selection and layout behavior
  /// 3) apply optional appearance customization
  /// 4) embed the tab bar controller's view
  private func configureTabBarController(with config: LiquidGlassTabBarConfig) {
    let viewControllers = buildViewControllers(from: config)

    tabBarController.delegate = self
    tabBarController.view.backgroundColor = .clear
    tabBarController.view.clipsToBounds = false
    tabBarController.view.isOpaque = false
    tabBarController.view.layer.isOpaque = false
    tabBarController.setViewControllers(viewControllers, animated: false)

    configureSelectionAndMode(
      currentIndex: config.currentIndex,
      selectableTabCount: selectableTabCount
    )

    let tabBar = tabBarController.tabBar
    tabBar.clipsToBounds = false
    tabBar.layer.masksToBounds = false
    if defaultTabBarTintColor == nil {
      defaultTabBarTintColor = tabBar.tintColor
    }
    configureTabBarLayout(tabBar, with: config)
    applyTabBarAppearanceIfNeeded(on: tabBar, with: config)

    // Keep tint assignment deterministic after appearance configuration so
    // iPad rendering paths don't fall back to default system blue.
    applyTintColorForSelectedIndex(tabBarController.selectedIndex, tabBar: tabBar)

    embedTabBarControllerView()
  }

  /// Creates one child view controller per tab item.
  private func buildViewControllers(from config: LiquidGlassTabBarConfig) -> [UIViewController] {
    var viewControllers = config.tabs.map { tab in
      let controller = UIViewController()
      controller.view.backgroundColor = .clear
      controller.tabBarItem = makeTabBarItem(from: tab, config: config)
      return controller
    }

    if let actionButton = config.actionButton {
      viewControllers.append(makeActionButtonController(from: actionButton, config: config))
    }

    return viewControllers
  }

  /// Builds a trailing action button controller rendered as a separate native pill.
  private func makeActionButtonController(
    from actionButton: LiquidGlassTabBarConfig.TabItem,
    config: LiquidGlassTabBarConfig
  ) -> UIViewController {
    let controller = UIViewController()
    controller.view.backgroundColor = .clear

    let actionItem = UITabBarItem(tabBarSystemItem: .search, tag: Self.actionButtonTag)
    actionItem.image = actionButton.image(forSelectedState: false, iconSize: config.iconSize)
    actionItem.selectedImage = actionButton.image(forSelectedState: true, iconSize: config.iconSize)
    actionItem.title = config.showLabels ? actionButton.label : nil
    actionItem.accessibilityLabel = actionButton.label

    applyBadgeConfiguration(from: actionButton, to: actionItem)
    applyLabelTypographyIfNeeded(to: actionItem, labelStyle: config.labelStyle)

    controller.tabBarItem = actionItem
    return controller
  }

  /// Builds a native tab bar item with icon, label, badge, and selected title styling.
  private func makeTabBarItem(
    from tab: LiquidGlassTabBarConfig.TabItem,
    config: LiquidGlassTabBarConfig
  ) -> UITabBarItem {
    let tabItem = UITabBarItem(
      title: config.showLabels ? tab.label : nil,
      image: tab.image(forSelectedState: false, iconSize: config.iconSize),
      selectedImage: tab.image(forSelectedState: true, iconSize: config.iconSize)
    )
    tabItem.accessibilityLabel = tab.label

    applyBadgeConfiguration(from: tab, to: tabItem)
    applyLabelTypographyIfNeeded(to: tabItem, labelStyle: config.labelStyle)
    let resolvedSelectedColor = tab.selectedItemColor ?? config.selectedItemColor
    applySelectedTitleAttributesIfNeeded(to: tabItem, selectedColor: resolvedSelectedColor)

    return tabItem
  }

  /// Applies optional font and letter spacing to tab labels.
  private func applyLabelTypographyIfNeeded(
    to tabItem: UITabBarItem,
    labelStyle: LiquidGlassTabBarConfig.LabelStyle?
  ) {
    guard let labelStyle else {
      return
    }

    var normalAttributes = tabItem.titleTextAttributes(for: .normal) ?? [:]
    var selectedAttributes = tabItem.titleTextAttributes(for: .selected) ?? [:]

    if let font = labelStyle.resolvedFont() {
      normalAttributes[.font] = font
      selectedAttributes[.font] = font
    }

    if let letterSpacing = labelStyle.letterSpacing {
      normalAttributes[.kern] = letterSpacing
      selectedAttributes[.kern] = letterSpacing
    }

    if !normalAttributes.isEmpty {
      tabItem.setTitleTextAttributes(normalAttributes, for: .normal)
    }

    if !selectedAttributes.isEmpty {
      tabItem.setTitleTextAttributes(selectedAttributes, for: .selected)
    }
  }

  /// Applies badge value and colors for a tab item.
  private func applyBadgeConfiguration(
    from tab: LiquidGlassTabBarConfig.TabItem, to tabItem: UITabBarItem
  ) {
    tabItem.badgeValue = tab.badgeValue
    if let badgeColor = tab.badgeColor {
      tabItem.badgeColor = badgeColor
    }
    if let badgeTextColor = tab.badgeTextColor {
      tabItem.setBadgeTextAttributes([.foregroundColor: badgeTextColor], for: .normal)
    }
  }

  /// Applies per-item selected title attributes as a safeguard for iPad title color.
  private func applySelectedTitleAttributesIfNeeded(
    to tabItem: UITabBarItem, selectedColor: UIColor?
  ) {
    guard let selectedColor else {
      return
    }

    var selectedAttributes = tabItem.titleTextAttributes(for: .selected) ?? [:]
    selectedAttributes[.foregroundColor] = selectedColor
    tabItem.setTitleTextAttributes(selectedAttributes, for: .selected)
  }

  /// Applies selected index and iOS 18+ tab-bar mode behavior.
  private func configureSelectionAndMode(currentIndex: Int, selectableTabCount: Int) {
    // Protect against invalid index when config and view-controller count diverge.
    tabBarController.selectedIndex = min(max(0, currentIndex), max(selectableTabCount - 1, 0))

    // On iPad, automatic mode can switch to tab/sidebar presentations where
    // system styling may override item title colors. Keep native tab bar mode
    // so appearance text colors apply consistently.
    if #available(iOS 18.0, *) {
      tabBarController.mode = .tabBar
    }
  }

  /// Applies layout options that control item positioning, spacing, and width.
  private func configureTabBarLayout(_ tabBar: UITabBar, with config: LiquidGlassTabBarConfig) {
    tabBar.itemPositioning = config.itemPositioning

    if let itemSpacing = config.itemSpacing {
      tabBar.itemSpacing = itemSpacing
    }

    if let itemWidth = config.itemWidth {
      tabBar.itemWidth = itemWidth
    }
  }

  /// Applies tab bar appearance when any appearance-related configuration is present.
  private func applyTabBarAppearanceIfNeeded(
    on tabBar: UITabBar, with config: LiquidGlassTabBarConfig
  ) {
    guard let appearance = makeTabBarAppearanceIfNeeded(from: config) else {
      return
    }

    // Set standard appearance for baseline rendering and scroll-edge for modern iOS.
    tabBar.standardAppearance = appearance
    if #available(iOS 15.0, *) {
      tabBar.scrollEdgeAppearance = appearance
    }
  }

  private func refreshTabBarVisuals() {
    let tabBar = tabBarController.tabBar
    configureTabBarLayout(tabBar, with: config)
    applyTabBarAppearanceIfNeeded(on: tabBar, with: config)
    applyTintColorForSelectedIndex(tabBarController.selectedIndex, tabBar: tabBar)
  }

  /// Builds appearance with selected, background, and shadow styling.
  private func makeTabBarAppearanceIfNeeded(from config: LiquidGlassTabBarConfig)
    -> UITabBarAppearance?
  {
    guard config.selectedItemColor != nil || config.labelStyle != nil else {
      return nil
    }

    let appearance = UITabBarAppearance()
    appearance.configureWithDefaultBackground()

    // iPad/iPhone can use different tab item layout styles depending on context.
    // Apply colors across all layout appearances to keep rendering consistent.
    applyItemAppearance(
      to: appearance.stackedLayoutAppearance,
      selectedColor: config.selectedItemColor,
      labelStyle: config.labelStyle
    )
    applyItemAppearance(
      to: appearance.inlineLayoutAppearance,
      selectedColor: config.selectedItemColor,
      labelStyle: config.labelStyle
    )
    applyItemAppearance(
      to: appearance.compactInlineLayoutAppearance,
      selectedColor: config.selectedItemColor,
      labelStyle: config.labelStyle
    )

    return appearance
  }

  /// Embeds the tab bar controller view to fill the host view.
  private func embedTabBarControllerView() {
    let controllerView = tabBarController.view!
    controllerView.translatesAutoresizingMaskIntoConstraints = false

    addSubview(controllerView)
    NSLayoutConstraint.activate([
      controllerView.leadingAnchor.constraint(equalTo: leadingAnchor),
      controllerView.trailingAnchor.constraint(equalTo: trailingAnchor),
      controllerView.topAnchor.constraint(equalTo: topAnchor),
      controllerView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  /// Propagates selected tint through the tab bar controller hierarchy.
  ///
  /// iPad tab rendering can source tint from multiple levels depending on
  /// layout and trait environment, so we set it on all relevant views.
  private func selectedColorForSelectableIndex(_ index: Int) -> UIColor? {
    guard index >= 0, index < tabSelectedColors.count else {
      return selectedItemColor
    }

    return tabSelectedColors[index]
  }

  private func applyTintColorForSelectedIndex(_ index: Int, tabBar: UITabBar) {
    let selectedColor = selectedColorForSelectableIndex(index)
    applySelectedTintColorHierarchy(selectedColor, tabBar: tabBar)
  }

  private func applySelectedTintColorHierarchy(_ selectedColor: UIColor?, tabBar: UITabBar) {
    if let selectedColor {
      tabBar.tintColor = selectedColor
      tabBarController.view.tintColor = selectedColor
      tintColor = selectedColor

      for viewController in tabBarController.viewControllers ?? [] {
        viewController.view.tintColor = selectedColor
      }

      // Keep the baked-in UITabBarAppearance in sync with the current
      // selected color. Without this, UIKit's internal re-renders (e.g.
      // after a Flutter navigation push/pop) fall back to the appearance's
      // original `selected.iconColor` — which is the GLOBAL
      // `config.selectedItemColor` — and the per-tab color appears to
      // "reset" until the user taps a tab.
      syncAppearanceSelectedColor(selectedColor, tabBar: tabBar)

      return
    }

    tabBar.tintColor = defaultTabBarTintColor
    tabBarController.view.tintColor = nil
    tintColor = nil

    for viewController in tabBarController.viewControllers ?? [] {
      viewController.view.tintColor = nil
    }
  }

  /// Updates the tab bar's appearance so its baked-in selected-state
  /// `iconColor` and title color match [color]. Called whenever per-tab
  /// tint changes so UIKit's internal re-renders don't revert to the
  /// original global color.
  private func syncAppearanceSelectedColor(_ color: UIColor, tabBar: UITabBar) {
    // Copy to a fresh instance so UIKit reliably observes the change and
    // triggers a redraw on all iOS versions.
    guard let appearance = tabBar.standardAppearance.copy() as? UITabBarAppearance else {
      return
    }

    let itemAppearances: [UITabBarItemAppearance] = [
      appearance.stackedLayoutAppearance,
      appearance.inlineLayoutAppearance,
      appearance.compactInlineLayoutAppearance,
    ]

    for itemAppearance in itemAppearances {
      itemAppearance.selected.iconColor = color

      var selectedAttributes = itemAppearance.selected.titleTextAttributes
      selectedAttributes[.foregroundColor] = color
      itemAppearance.selected.titleTextAttributes = selectedAttributes

      if #available(iOS 15.0, *) {
        itemAppearance.focused.iconColor = color

        var focusedAttributes = itemAppearance.focused.titleTextAttributes
        focusedAttributes[.foregroundColor] = color
        itemAppearance.focused.titleTextAttributes = focusedAttributes
      }
    }

    tabBar.standardAppearance = appearance
    if #available(iOS 15.0, *) {
      tabBar.scrollEdgeAppearance = appearance
    }
  }

  /// Updates the selected tab index without rebuilding the native controller.
  func setSelectedIndex(_ index: Int) {
    guard selectableTabCount > 0 else {
      return
    }

    let clampedIndex = min(max(0, index), selectableTabCount - 1)
    guard tabBarController.selectedIndex != clampedIndex else {
      return
    }

    tabBarController.selectedIndex = clampedIndex
    applyTintColorForSelectedIndex(clampedIndex, tabBar: tabBarController.tabBar)
  }

  func tabBarController(
    _ tabBarController: UITabBarController, shouldSelect viewController: UIViewController
  ) -> Bool {
    if viewController.tabBarItem.tag == Self.actionButtonTag {
      onActionButtonPressed()
      return false
    }

    return true
  }

  func tabBarController(
    _ tabBarController: UITabBarController, didSelect viewController: UIViewController
  ) {
    guard let viewControllers = tabBarController.viewControllers,
      let index = viewControllers.firstIndex(where: { $0 === viewController }),
      index < selectableTabCount
    else {
      return
    }

    applyTintColorForSelectedIndex(index, tabBar: tabBarController.tabBar)
    onTabSelected(index)
  }

  /// Applies selected icon/title colors to one tab bar item appearance style.
  private func applyItemAppearance(
    to appearance: UITabBarItemAppearance,
    selectedColor: UIColor?,
    labelStyle: LiquidGlassTabBarConfig.LabelStyle?
  ) {
    var normalAttributes = appearance.normal.titleTextAttributes
    var selectedAttributes = appearance.selected.titleTextAttributes

    if let font = labelStyle?.resolvedFont() {
      normalAttributes[.font] = font
      selectedAttributes[.font] = font
    }

    if let letterSpacing = labelStyle?.letterSpacing {
      normalAttributes[.kern] = letterSpacing
      selectedAttributes[.kern] = letterSpacing
    }

    appearance.normal.titleTextAttributes = normalAttributes
    appearance.selected.titleTextAttributes = selectedAttributes

    if let selectedColor {
      appearance.selected.iconColor = selectedColor
      selectedAttributes[.foregroundColor] = selectedColor
      appearance.selected.titleTextAttributes = selectedAttributes

      if #available(iOS 15.0, *) {
        appearance.focused.iconColor = selectedColor
        var focusedAttributes = appearance.focused.titleTextAttributes
        if let font = labelStyle?.resolvedFont() {
          focusedAttributes[.font] = font
        }
        if let letterSpacing = labelStyle?.letterSpacing {
          focusedAttributes[.kern] = letterSpacing
        }
        focusedAttributes[.foregroundColor] = selectedColor
        appearance.focused.titleTextAttributes = focusedAttributes
      }
    }
  }
}

// MARK: - Platform view bridge

final class LiquidGlassTabBarPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let channel: FlutterMethodChannel
  private weak var hostViewController: UIViewController?
  private var nativeTabBarControllerView: LiquidGlassNativeTabBarControllerView?

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger,
    hostViewController: UIViewController?
  ) {
    containerView = UIView(frame: frame)
    self.hostViewController = hostViewController
    channel = FlutterMethodChannel(
      name: "liquid-glass-tab-bar-view/\(viewId)",
      binaryMessenger: messenger
    )

    super.init()
    setupView(arguments: args as? [String: Any])
    setupMethodChannelHandler()
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView {
    containerView
  }

  private func setupView(arguments args: [String: Any]?) {
    let config = LiquidGlassTabBarConfig(arguments: args)

    let nativeView = LiquidGlassNativeTabBarControllerView(
      config: config,
      onTabSelected: { [weak self] index in
        self?.channel.invokeMethod("onTabSelected", arguments: index)
      },
      onActionButtonPressed: { [weak self] in
        self?.channel.invokeMethod("onActionButtonPressed", arguments: nil)
      }
    )
    nativeView.translatesAutoresizingMaskIntoConstraints = false
    nativeView.attach(to: hostViewController)

    containerView.clipsToBounds = false
    containerView.backgroundColor = .clear
    containerView.isOpaque = false
    containerView.layer.isOpaque = false
    containerView.addSubview(nativeView)

    // Constrain the native view to the bottom portion of the container.
    // The top `glassOverflow` points stay empty so the glass effect can
    // overflow into them via clipsToBounds = false without extending
    // beyond the platform view frame that Flutter composites.
    let glassOverflow = config.glassOverflow
    NSLayoutConstraint.activate([
      nativeView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      nativeView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      nativeView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: glassOverflow),
      nativeView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    nativeTabBarControllerView = nativeView
  }

  private func setupMethodChannelHandler() {
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call, result: result)
    }
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setSelectedIndex":
      guard let index = parseSelectedIndex(from: call.arguments) else {
        result(
          FlutterError(
            code: "invalid-arguments",
            message: "Expected integer selected index.",
            details: call.arguments
          )
        )
        return
      }

      nativeTabBarControllerView?.setSelectedIndex(index)
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func parseSelectedIndex(from arguments: Any?) -> Int? {
    if let index = arguments as? Int {
      return index
    }

    if let number = arguments as? NSNumber {
      return number.intValue
    }

    if let dictionary = arguments as? [String: Any] {
      if let index = dictionary["index"] as? Int {
        return index
      }
      if let number = dictionary["index"] as? NSNumber {
        return number.intValue
      }
    }

    return nil
  }
}
