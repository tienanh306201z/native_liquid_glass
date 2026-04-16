import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Controls the visibility of all native Liquid Glass platform views.
///
/// Native glass views are real `UIView`s composited on top of Flutter's
/// rendering surface. When Flutter shows its own overlays —
/// `showModalBottomSheet`, dialogs, custom page transitions — the glass
/// views can render above them, causing visual bleed-through.
///
/// ## Automatic (recommended)
///
/// Add [LiquidGlassNavigatorObserver] to your app and all popup routes
/// (bottom sheets, dialogs, etc.) are handled automatically:
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [LiquidGlassNavigatorObserver()],
/// )
/// ```
///
/// ## Manual
///
/// For custom overlays that don't go through the Navigator, call
/// [NativeLiquidGlassLifecycle.suppressGlassEffects] /
/// [NativeLiquidGlassLifecycle.unsuppressGlassEffects] directly.
/// Calls are reference-counted, so nested overlays are safe.
final class NativeLiquidGlassLifecycle {
  NativeLiquidGlassLifecycle._();

  static const _channel = MethodChannel('liquid-glass-lifecycle');
  static int _suppressCount = 0;

  /// Fades all native glass views to invisible.
  ///
  /// Safe to call multiple times — only the first call triggers the
  /// native fade-out. Each call must be balanced by a matching
  /// [unsuppressGlassEffects].
  static Future<void> suppressGlassEffects() async {
    _suppressCount++;
    if (_suppressCount == 1) {
      await _channel.invokeMethod('suppressGlassEffects');
    }
  }

  /// Fades all native glass views back to visible.
  ///
  /// Only triggers the native fade-in when the suppress count reaches
  /// zero (i.e. all matching [suppressGlassEffects] calls have been
  /// balanced).
  static Future<void> unsuppressGlassEffects() async {
    _suppressCount--;
    if (_suppressCount <= 0) {
      _suppressCount = 0;
      await _channel.invokeMethod('unsuppressGlassEffects');
    }
  }
}

/// Automatically suppresses glass effects when Flutter presents overlays.
///
/// Detects [PopupRoute]s — which cover `showModalBottomSheet`,
/// `showDialog`, `showCupertinoModalPopup`, `showMenu`, and any custom
/// popup — and fades glass views out/in around them.
///
/// Glass items *inside* the popup are unaffected (they're created after
/// the suppress notification, so they stay visible).
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [LiquidGlassNavigatorObserver()],
/// )
/// ```
///
/// For nested navigators (e.g. GoRouter shell routes), add a separate
/// instance to each navigator that can present popups.
class LiquidGlassNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) {
      NativeLiquidGlassLifecycle.suppressGlassEffects();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) {
      NativeLiquidGlassLifecycle.unsuppressGlassEffects();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) {
      NativeLiquidGlassLifecycle.unsuppressGlassEffects();
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    // A popup was replaced by a non-popup (or removed).
    if (oldRoute is PopupRoute && newRoute is! PopupRoute) {
      NativeLiquidGlassLifecycle.unsuppressGlassEffects();
    }
    // A non-popup was replaced by a popup.
    if (newRoute is PopupRoute && oldRoute is! PopupRoute) {
      NativeLiquidGlassLifecycle.suppressGlassEffects();
    }
  }
}
