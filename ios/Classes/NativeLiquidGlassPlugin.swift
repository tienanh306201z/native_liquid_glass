import Flutter
import UIKit

public class NativeLiquidGlassPlugin: NSObject, FlutterPlugin {
  private static var presenter: LiquidGlassPresenter?
  private static let tabBarViewType = "liquid-glass-tab-bar-view"
  private static let buttonViewType = "liquid-glass-button-view"
  private static let iconButtonViewType = "liquid-glass-icon-button-view"
  private static let containerViewType = "liquid-glass-container-view"
  private static let buttonGroupViewType = "liquid-glass-button-group-view"
  private static let searchBarViewType = "liquid-glass-search-bar-view"
  private static let toggleViewType = "liquid-glass-toggle-view"
  private static let sliderViewType = "liquid-glass-slider-view"
  private static let segmentedControlViewType = "liquid-glass-segmented-control-view"
  private static let datePickerViewType = "liquid-glass-date-picker-view"
  private static let colorPickerViewType = "liquid-glass-color-picker-view"
  private static let menuViewType = "liquid-glass-menu-view"
  private static let navigationBarViewType = "liquid-glass-navigation-bar-view"
  private static let toolbarViewType = "liquid-glass-toolbar-view"
  private static let searchScaffoldViewType = "liquid-glass-search-scaffold-view"
  private static let stepperViewType = "liquid-glass-stepper-view"
  private static let activityIndicatorViewType = "liquid-glass-activity-indicator-view"
  private static let progressViewType = "liquid-glass-progress-view"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let tabBarFactory = LiquidGlassTabBarViewFactory(
      messenger: registrar.messenger(),
      hostViewController: registrar.viewController
    )
    let buttonFactory = LiquidGlassButtonViewFactory(
      messenger: registrar.messenger(),
      defaultIconOnly: false
    )
    let iconButtonFactory = LiquidGlassButtonViewFactory(
      messenger: registrar.messenger(),
      defaultIconOnly: true
    )
    let containerFactory = LiquidGlassContainerViewFactory(
      messenger: registrar.messenger()
    )
    let buttonGroupFactory = LiquidGlassButtonGroupViewFactory(
      messenger: registrar.messenger()
    )
    let searchBarFactory = LiquidGlassSearchBarViewFactory(
      messenger: registrar.messenger()
    )
    let toggleFactory = LiquidGlassToggleViewFactory(
      messenger: registrar.messenger()
    )
    let sliderFactory = LiquidGlassSliderViewFactory(
      messenger: registrar.messenger()
    )
    let segmentedControlFactory = LiquidGlassSegmentedControlViewFactory(
      messenger: registrar.messenger()
    )
    let datePickerFactory = LiquidGlassDatePickerViewFactory(
      messenger: registrar.messenger()
    )
    let navigationBarFactory = LiquidGlassNavigationBarViewFactory(
      messenger: registrar.messenger()
    )
    let toolbarFactory = LiquidGlassToolbarViewFactory(
      messenger: registrar.messenger()
    )
    let searchScaffoldFactory = LiquidGlassSearchScaffoldViewFactory(
      messenger: registrar.messenger(),
      hostViewController: registrar.viewController
    )

    registrar.register(tabBarFactory, withId: tabBarViewType)
    registrar.register(buttonFactory, withId: buttonViewType)
    registrar.register(iconButtonFactory, withId: iconButtonViewType)
    registrar.register(containerFactory, withId: containerViewType)
    registrar.register(buttonGroupFactory, withId: buttonGroupViewType)
    registrar.register(searchBarFactory, withId: searchBarViewType)
    registrar.register(toggleFactory, withId: toggleViewType)
    registrar.register(sliderFactory, withId: sliderViewType)
    registrar.register(segmentedControlFactory, withId: segmentedControlViewType)
    registrar.register(datePickerFactory, withId: datePickerViewType)
    if #available(iOS 14.0, *) {
      let colorPickerFactory = LiquidGlassColorPickerViewFactory(messenger: registrar.messenger())
      registrar.register(colorPickerFactory, withId: colorPickerViewType)
    }
    if #available(iOS 14.0, *) {
      let menuFactory = LiquidGlassMenuViewFactory(messenger: registrar.messenger())
      registrar.register(menuFactory, withId: menuViewType)
    }
    registrar.register(navigationBarFactory, withId: navigationBarViewType)
    registrar.register(toolbarFactory, withId: toolbarViewType)
    registrar.register(searchScaffoldFactory, withId: searchScaffoldViewType)

    let stepperFactory = LiquidGlassStepperViewFactory(messenger: registrar.messenger())
    registrar.register(stepperFactory, withId: stepperViewType)

    let activityIndicatorFactory = LiquidGlassActivityIndicatorViewFactory(
      messenger: registrar.messenger())
    registrar.register(activityIndicatorFactory, withId: activityIndicatorViewType)

    let progressViewFactory = LiquidGlassProgressViewFactory(messenger: registrar.messenger())
    registrar.register(progressViewFactory, withId: progressViewType)

    // Initialize the shared presenter for modal presentation (sheets, alerts, popovers)
    presenter = LiquidGlassPresenter(
      messenger: registrar.messenger(),
      hostViewController: registrar.viewController
    )
  }
}
