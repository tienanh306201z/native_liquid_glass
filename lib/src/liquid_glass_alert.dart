import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'shares/liquid_glass_icon.dart';
import 'utils/native_liquid_glass_utils.dart';

/// An action button for [LiquidGlassAlert].
class LiquidGlassAlertAction {
  /// Unique identifier.
  final String id;

  /// Display title.
  final String title;

  /// Optional icon. On iOS, only [NativeLiquidGlassIcon.sfSymbol] icons are
  /// rendered natively. Other icon types are shown in the Flutter fallback only.
  final NativeLiquidGlassIcon? icon;

  /// Whether this is a destructive action (shown in red).
  final bool isDestructive;

  /// Whether this is the cancel action.
  final bool isCancel;

  const LiquidGlassAlertAction({required this.id, required this.title, this.icon, this.isDestructive = false, this.isCancel = false});

  Map<String, Object?> toMap() {
    return <String, Object?>{'id': id, 'title': title, 'sfSymbolName': icon?.sfSymbolName, 'isDestructive': isDestructive, 'isCancel': isCancel};
  }
}

/// Alert style.
enum LiquidGlassAlertStyle {
  /// Centered alert dialog.
  alert,

  /// Action sheet from bottom.
  actionSheet,
}

/// Shows a native iOS alert using UIAlertController with Liquid Glass effects
/// on iOS 26+.
///
/// Uses the shared LiquidGlassPresenter channel for modal presentation.
/// On non-iOS platforms, falls back to [showDialog] + [AlertDialog].
class LiquidGlassAlert {
  static const _presenterChannel = MethodChannel('liquid-glass-presenter');

  LiquidGlassAlert._();

  /// Show an alert and return the selected action ID.
  static Future<String?> show({
    required BuildContext context,
    String? title,
    String? message,
    List<LiquidGlassAlertAction> actions = const [],
    LiquidGlassAlertStyle style = LiquidGlassAlertStyle.alert,
  }) async {
    if (NativeLiquidGlassUtils.supportsLiquidGlass) {
      final completer = Completer<String?>();

      // Listen for action selection
      _presenterChannel.setMethodCallHandler((call) async {
        if (call.method == 'alertActionSelected') {
          final args = call.arguments as Map?;
          if (args != null) {
            completer.complete(args['actionId'] as String?);
          }
        }
      });

      await _presenterChannel.invokeMethod<void>('showAlert', {
        'title': title,
        'message': message,
        'style': style.index,
        'actions': actions.map((a) => a.toMap()).toList(),
      });

      return completer.future;
    }

    return null;
  }

  /// Convenience: show a confirmation dialog with OK & Cancel.
  static Future<bool> confirm({
    required BuildContext context,
    String? title,
    String? message,
    String confirmTitle = 'OK',
    String cancelTitle = 'Cancel',
  }) async {
    final result = await show(
      context: context,
      title: title,
      message: message,
      actions: [
        LiquidGlassAlertAction(id: 'cancel', title: cancelTitle, isCancel: true),
        LiquidGlassAlertAction(id: 'confirm', title: confirmTitle),
      ],
    );
    return result == 'confirm';
  }

  /// Convenience: show a destructive confirmation dialog.
  static Future<bool> destructive({
    required BuildContext context,
    String? title,
    String? message,
    String destructiveTitle = 'Delete',
    String cancelTitle = 'Cancel',
  }) async {
    final result = await show(
      context: context,
      title: title,
      message: message,
      actions: [
        LiquidGlassAlertAction(id: 'cancel', title: cancelTitle, isCancel: true),
        LiquidGlassAlertAction(id: 'destructive', title: destructiveTitle, isDestructive: true),
      ],
    );
    return result == 'destructive';
  }
}
