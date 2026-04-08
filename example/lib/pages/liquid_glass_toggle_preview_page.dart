import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassTogglePreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassTogglePreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassTogglePreviewPage> createState() => _LiquidGlassTogglePreviewPageState();
}

class _LiquidGlassTogglePreviewPageState extends State<LiquidGlassTogglePreviewPage> {
  bool _wifi = true;
  bool _bluetooth = false;
  bool _airplaneMode = false;
  bool _flashlight = true;
  bool _enabled = true;
  bool _useCustomColor = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tintColor = _useCustomColor ? colorScheme.tertiary : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassToggle preview'),
        actions: [ThemeModeActionButton(onThemeChanged: widget.onThemeChanged)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ToggleRow(
                            label: 'Wi-Fi',
                            icon: Icons.wifi_rounded,
                            value: _wifi,
                            enabled: _enabled,
                            color: tintColor,
                            onChanged: (v) => setState(() => _wifi = v),
                          ),
                          _ToggleRow(
                            label: 'Bluetooth',
                            icon: Icons.bluetooth_rounded,
                            value: _bluetooth,
                            enabled: _enabled,
                            color: tintColor,
                            onChanged: (v) => setState(() => _bluetooth = v),
                          ),
                          _ToggleRow(
                            label: 'Airplane Mode',
                            icon: Icons.airplanemode_active_rounded,
                            value: _airplaneMode,
                            enabled: _enabled,
                            color: tintColor,
                            onChanged: (v) => setState(() => _airplaneMode = v),
                          ),
                          _ToggleRow(
                            label: 'Flashlight',
                            icon: Icons.flashlight_on_rounded,
                            value: _flashlight,
                            enabled: _enabled,
                            color: tintColor,
                            onChanged: (v) => setState(() => _flashlight = v),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enabled'),
                        value: _enabled,
                        onChanged: (v) => setState(() => _enabled = v),
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom tint color'),
                        value: _useCustomColor,
                        onChanged: (v) => setState(() => _useCustomColor = v),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final bool enabled;
  final Color? color;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({required this.label, required this.icon, required this.value, required this.enabled, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: LiquidGlassToggle(value: value, onChanged: onChanged, enabled: enabled, color: color),
    );
  }
}
