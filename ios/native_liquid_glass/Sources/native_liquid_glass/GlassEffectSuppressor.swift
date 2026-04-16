import Flutter
import UIKit

// MARK: - Notification Names

extension Notification.Name {
  /// Posted by `GlassEffectSuppressor` to request all glass views to hide.
  static let liquidGlassSuppress = Notification.Name("LiquidGlassSuppressAll")
  /// Posted by `GlassEffectSuppressor` to request all glass views to reappear.
  static let liquidGlassUnsuppress = Notification.Name("LiquidGlassUnsuppressAll")
}

// MARK: - GlassEffectSuppressor

/// Singleton that coordinates hiding / showing all native glass platform views.
///
/// Flutter platform views with glass effects sit *above* Flutter's rendering
/// surface (they are real `UIView`s composited on top of Flutter's Metal
/// layer). When Flutter shows its own overlays — `showModalBottomSheet`,
/// dialogs, page transitions — the glass views render on top and bleed
/// through.
///
/// The suppressor exposes a method-channel API (`liquid-glass-lifecycle`)
/// that the Dart side can call before/after presenting overlays:
///
///   • `suppressGlassEffects`  → fades all glass views to alpha 0
///   • `unsuppressGlassEffects` → fades them back to alpha 1
///
/// Each platform view registers a `GlassSuppressObserver` that listens for
/// the `NotificationCenter` broadcasts and animates accordingly.
final class GlassEffectSuppressor {
  static let shared = GlassEffectSuppressor()

  private var methodChannel: FlutterMethodChannel?

  private init() {}

  /// Call once during plugin registration.
  func setup(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "liquid-glass-lifecycle",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "suppressGlassEffects":
        self?.suppress()
        result(nil)
      case "unsuppressGlassEffects":
        self?.unsuppress()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    methodChannel = channel
  }

  func suppress() {
    NotificationCenter.default.post(name: .liquidGlassSuppress, object: nil)
  }

  func unsuppress() {
    NotificationCenter.default.post(name: .liquidGlassUnsuppress, object: nil)
  }
}

// MARK: - GlassSuppressObserver

/// Lightweight observer that hides/shows a single platform view.
///
/// Tracks two independent suppression sources:
///
///   1. **Route-based** (`setRouteSuppressed`) — driven per-widget by
///      `ModalRoute.of(context).isCurrent` on the Dart side. Fully
///      automatic; no observer setup needed.
///   2. **Global** (NotificationCenter) — driven by the manual
///      `NativeLiquidGlassLifecycle` API or the optional
///      `LiquidGlassNavigatorObserver`.
///
/// The view is hidden when *either* source says suppress, and only
/// shown when *both* say unsuppress.
///
/// Usage — add two lines to any `FlutterPlatformView`:
/// ```
/// private var suppressObserver: GlassSuppressObserver?
/// // in init, after containerView is ready:
/// suppressObserver = GlassSuppressObserver(view: containerView)
/// ```
///
/// Then forward `setSuppressed` from the method channel:
/// ```
/// case "setSuppressed":
///   let suppressed = (call.arguments as? [String: Any])?["suppressed"] as? Bool ?? false
///   self.suppressObserver?.setRouteSuppressed(suppressed)
///   result(nil)
/// ```
final class GlassSuppressObserver {
  private weak var targetView: UIView?
  private var isSuppressedByRoute = false
  private var isSuppressedGlobally = false

  init(view: UIView) {
    self.targetView = view
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleSuppress),
      name: .liquidGlassSuppress,
      object: nil
    )
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleUnsuppress),
      name: .liquidGlassUnsuppress,
      object: nil
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  /// Called by the platform view's method channel when the Dart-side
  /// `ModalRoute.of(context).isCurrent` changes.
  func setRouteSuppressed(_ suppressed: Bool) {
    isSuppressedByRoute = suppressed
    updateAlpha()
  }

  // MARK: - Global (NotificationCenter)

  @objc private func handleSuppress() {
    isSuppressedGlobally = true
    updateAlpha()
  }

  @objc private func handleUnsuppress() {
    guard isSuppressedGlobally else { return }
    isSuppressedGlobally = false
    updateAlpha()
  }

  // MARK: - Alpha

  private func updateAlpha() {
    let shouldHide = isSuppressedByRoute || isSuppressedGlobally
    UIView.animate(withDuration: shouldHide ? 0.15 : 0.25) {
      self.targetView?.alpha = shouldHide ? 0 : 1
    }
  }
}
