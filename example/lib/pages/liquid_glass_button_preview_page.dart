import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

enum _ButtonIconSource { sfSymbol, iconData, asset }

class LiquidGlassButtonPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassButtonPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassButtonPreviewPage> createState() => _LiquidGlassButtonPreviewPageState();
}

class _LiquidGlassButtonPreviewPageState extends State<LiquidGlassButtonPreviewPage> {
  int _pressCount = 0;
  bool _isEnabled = true;
  bool _iconOnly = false;
  bool _showIcon = true;
  bool _useIconColor = false;
  bool _useForegroundColor = false;
  bool _useGlassTint = false;
  bool _interactive = true;
  bool _useLabelTextStyle = false;
  int _badgeMode = 0; // 0=off, 1=dot, 2=value
  bool _useBadgeColor = false;
  double _badgeSize = 12;
  LiquidGlassButtonStyle _buttonStyle = LiquidGlassButtonStyle.prominentGlass;
  double _buttonWidth = 240;
  double _buttonHeight = 50;
  double _iconButtonSize = 56;
  double _iconSize = 18;
  double _imagePadding = 10;
  double _labelFontSize = 16;
  LiquidGlassImagePlacement _imagePlacement = LiquidGlassImagePlacement.leading;
  _ButtonIconSource _iconSource = _ButtonIconSource.sfSymbol;

  NativeLiquidGlassIcon? _resolveIcon() {
    if (!_showIcon) {
      return null;
    }

    return switch (_iconSource) {
      _ButtonIconSource.sfSymbol => const NativeLiquidGlassIcon.sfSymbol('arrow.right.circle.fill'),
      _ButtonIconSource.iconData => const NativeLiquidGlassIcon.iconData(Icons.arrow_forward_rounded),
      _ButtonIconSource.asset => const NativeLiquidGlassIcon.asset('assets/icons/continue.svg'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassButton preview'),
        actions: [ThemeModeActionButton(onThemeChanged: widget.onThemeChanged)],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Pressed: $_pressCount', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                if (_iconOnly)
                  Center(
                    child: LiquidGlassButton.icon(
                      onPressed: _isEnabled ? () => setState(() => _pressCount++) : null,
                      icon: _resolveIcon() ?? const NativeLiquidGlassIcon.sfSymbol('star.fill'),
                      size: _iconButtonSize,
                      iconSize: _iconButtonSize * 0.44,
                      iconColor: _useIconColor ? colorScheme.primary : null,
                      tint: _useGlassTint ? colorScheme.secondary : null,
                      style: _buttonStyle,
                      showBadge: _badgeMode >= 1,
                      badgeValue: _badgeMode == 2 ? '3' : null,
                      badgeColor: _useBadgeColor ? Colors.blue : null,
                      badgeTextColor: _useBadgeColor ? Colors.white : null,
                      badgeSize: _badgeMode > 0 ? _badgeSize : null,
                    ),
                  )
                else
                  Center(
                    child: LiquidGlassButton(
                      label: 'Continue',
                      onPressed: _isEnabled
                          ? () {
                              setState(() {
                                _pressCount++;
                              });
                            }
                          : null,
                      style: _buttonStyle,
                      width: _buttonWidth,
                      height: _buttonHeight,
                      icon: _resolveIcon(),
                      iconSize: _iconSize,
                      imagePadding: _imagePadding,
                      imagePlacement: _imagePlacement,
                      iconColor: _useIconColor ? colorScheme.primary : null,
                      foregroundColor: _useForegroundColor ? colorScheme.onSurface : null,
                      tint: _useGlassTint ? colorScheme.secondary : null,
                      interactive: _interactive,
                      labelTextStyle: _useLabelTextStyle ? TextStyle(fontSize: _labelFontSize, fontWeight: FontWeight.bold, letterSpacing: 0.5) : null,
                      showBadge: _badgeMode >= 1,
                      badgeValue: _badgeMode == 2 ? '3' : null,
                      badgeColor: _useBadgeColor ? Colors.blue : null,
                      badgeTextColor: _useBadgeColor ? Colors.white : null,
                      badgeSize: _badgeMode > 0 ? _badgeSize : null,
                    ),
                  ),
                SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Icon-only mode'),
                          value: _iconOnly,
                          onChanged: (value) => setState(() => _iconOnly = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Enabled'),
                          value: _isEnabled,
                          onChanged: (value) => setState(() => _isEnabled = value),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Button style', style: Theme.of(context).textTheme.titleSmall),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<LiquidGlassButtonStyle>(
                            segments: const [
                              ButtonSegment(value: LiquidGlassButtonStyle.glass, label: Text('Glass')),
                              ButtonSegment(value: LiquidGlassButtonStyle.prominentGlass, label: Text('Prominent')),
                              ButtonSegment(value: LiquidGlassButtonStyle.filled, label: Text('Filled')),
                              ButtonSegment(value: LiquidGlassButtonStyle.tinted, label: Text('Tinted')),
                              ButtonSegment(value: LiquidGlassButtonStyle.plain, label: Text('Plain')),
                            ],
                            selected: {_buttonStyle},
                            onSelectionChanged: (sel) => setState(() => _buttonStyle = sel.first),
                          ),
                        ),
                        if (!_iconOnly)
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Glass interactive'),
                            value: _interactive,
                            onChanged: (value) => setState(() => _interactive = value),
                          ),
                        if (!_iconOnly)
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Show icon'),
                            value: _showIcon,
                            onChanged: (value) => setState(() => _showIcon = value),
                          ),
                        if (_showIcon || _iconOnly) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Icon source', style: Theme.of(context).textTheme.titleSmall),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<_ButtonIconSource>(
                            segments: const [
                              ButtonSegment<_ButtonIconSource>(value: _ButtonIconSource.sfSymbol, label: Text('SF Symbol')),
                              ButtonSegment<_ButtonIconSource>(value: _ButtonIconSource.iconData, label: Text('IconData')),
                              ButtonSegment<_ButtonIconSource>(value: _ButtonIconSource.asset, label: Text('Asset')),
                            ],
                            selected: <_ButtonIconSource>{_iconSource},
                            onSelectionChanged: (selection) => setState(() => _iconSource = selection.first),
                          ),
                        ],
                        if (_showIcon && !_iconOnly) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Image placement', style: Theme.of(context).textTheme.titleSmall),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<LiquidGlassImagePlacement>(
                            segments: const [
                              ButtonSegment(value: LiquidGlassImagePlacement.leading, label: Text('Leading')),
                              ButtonSegment(value: LiquidGlassImagePlacement.trailing, label: Text('Trailing')),
                            ],
                            selected: {_imagePlacement},
                            onSelectionChanged: (sel) => setState(() => _imagePlacement = sel.first),
                          ),
                        ],
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Apply icon color'),
                          value: _useIconColor,
                          onChanged: (value) => setState(() => _useIconColor = value),
                        ),
                        if (!_iconOnly)
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Apply foreground color'),
                            value: _useForegroundColor,
                            onChanged: (value) => setState(() => _useForegroundColor = value),
                          ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Apply glass tint color'),
                          value: _useGlassTint,
                          onChanged: (value) => setState(() => _useGlassTint = value),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Badge', style: Theme.of(context).textTheme.titleSmall),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 0, label: Text('Off')),
                            ButtonSegment(value: 1, label: Text('Dot')),
                            ButtonSegment(value: 2, label: Text('Value')),
                          ],
                          selected: {_badgeMode},
                          onSelectionChanged: (sel) => setState(() => _badgeMode = sel.first),
                        ),
                        if (_badgeMode > 0) ...[
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Custom badge color (blue)'),
                            value: _useBadgeColor,
                            onChanged: (value) => setState(() => _useBadgeColor = value),
                          ),
                          Row(
                            children: [
                              const Text('Badge sz'),
                              Expanded(
                                child: Slider.adaptive(
                                  min: 6,
                                  max: 24,
                                  divisions: 18,
                                  value: _badgeSize,
                                  label: _badgeSize.toStringAsFixed(0),
                                  onChanged: (value) => setState(() => _badgeSize = value),
                                ),
                              ),
                              Text(_badgeSize.toStringAsFixed(0)),
                            ],
                          ),
                        ],
                        if (!_iconOnly) ...[
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Custom label text style'),
                            value: _useLabelTextStyle,
                            onChanged: (value) => setState(() => _useLabelTextStyle = value),
                          ),
                          Row(
                            children: [
                              const SizedBox(width: 4, child: Text('W')),
                              Expanded(
                                child: Slider.adaptive(
                                  min: 160,
                                  max: 320,
                                  divisions: 16,
                                  value: _buttonWidth,
                                  label: _buttonWidth.toStringAsFixed(0),
                                  onChanged: (value) => setState(() => _buttonWidth = value),
                                ),
                              ),
                              Text(_buttonWidth.toStringAsFixed(0)),
                            ],
                          ),
                          Row(
                            children: [
                              const SizedBox(width: 4, child: Text('H')),
                              Expanded(
                                child: Slider.adaptive(
                                  min: 40,
                                  max: 64,
                                  divisions: 12,
                                  value: _buttonHeight,
                                  label: _buttonHeight.toStringAsFixed(0),
                                  onChanged: (value) => setState(() => _buttonHeight = value),
                                ),
                              ),
                              Text(_buttonHeight.toStringAsFixed(0)),
                            ],
                          ),
                        ],
                        if (_iconOnly)
                          Row(
                            children: [
                              const Text('Size'),
                              Expanded(
                                child: Slider.adaptive(
                                  min: 40,
                                  max: 88,
                                  divisions: 24,
                                  value: _iconButtonSize,
                                  label: _iconButtonSize.toStringAsFixed(0),
                                  onChanged: (value) => setState(() => _iconButtonSize = value),
                                ),
                              ),
                              Text(_iconButtonSize.toStringAsFixed(0)),
                            ],
                          ),
                        if (_showIcon && !_iconOnly)
                          Row(
                            children: [
                              const Text('Icon sz'),
                              Expanded(
                                child: Slider.adaptive(
                                  min: 14,
                                  max: 28,
                                  divisions: 14,
                                  value: _iconSize,
                                  label: _iconSize.toStringAsFixed(0),
                                  onChanged: (value) => setState(() => _iconSize = value),
                                ),
                              ),
                              Text(_iconSize.toStringAsFixed(0)),
                            ],
                          ),
                        if (_showIcon && !_iconOnly)
                          Row(
                            children: [
                              const Text('Padding'),
                              Expanded(
                                child: Slider.adaptive(
                                  min: 0,
                                  max: 20,
                                  divisions: 20,
                                  value: _imagePadding,
                                  label: _imagePadding.toStringAsFixed(0),
                                  onChanged: (value) => setState(() => _imagePadding = value),
                                ),
                              ),
                              Text(_imagePadding.toStringAsFixed(0)),
                            ],
                          ),
                        if (_useLabelTextStyle && !_iconOnly)
                          Row(
                            children: [
                              const Text('Font sz'),
                              Expanded(
                                child: Slider.adaptive(
                                  min: 12,
                                  max: 24,
                                  divisions: 12,
                                  value: _labelFontSize,
                                  label: _labelFontSize.toStringAsFixed(0),
                                  onChanged: (value) => setState(() => _labelFontSize = value),
                                ),
                              ),
                              Text(_labelFontSize.toStringAsFixed(0)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
