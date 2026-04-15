import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../widgets/theme_mode_action_button.dart';

class LiquidGlassToolbarPreviewPage extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;

  const LiquidGlassToolbarPreviewPage({super.key, required this.onThemeChanged});

  @override
  State<LiquidGlassToolbarPreviewPage> createState() => _LiquidGlassToolbarPreviewPageState();
}

class _LiquidGlassToolbarPreviewPageState extends State<LiquidGlassToolbarPreviewPage> {
  bool _flexibleSpacer = true;
  bool _textOnly = false;
  bool _useCustomIconSize = false;
  bool _usePerItemColor = false;
  bool _useLabelTextStyle = false;
  bool _useShadowColor = false;
  String? _lastTappedItem;
  double _iconSize = 22;
  LiquidGlassToolbarIconWeight _iconWeight = LiquidGlassToolbarIconWeight.regular;

  List<LiquidGlassToolbarItem> get _items => [
    LiquidGlassToolbarItem(
      id: 'reply',
      icon: _textOnly ? null : const NativeLiquidGlassIcon.sfSymbol('arrowshape.turn.up.left.fill'),
      label: _textOnly ? 'Reply' : null,
      iconSize: _useCustomIconSize ? _iconSize : null,
      tintColor: _usePerItemColor ? Colors.blue : null,
    ),
    LiquidGlassToolbarItem(
      id: 'forward',
      icon: _textOnly ? null : const NativeLiquidGlassIcon.sfSymbol('arrowshape.turn.up.right.fill'),
      label: _textOnly ? 'Forward' : null,
      iconSize: _useCustomIconSize ? _iconSize : null,
    ),
    if (_flexibleSpacer) const LiquidGlassToolbarSpacer(flexible: true) else const LiquidGlassToolbarSpacer(flexible: false, width: 32),
    LiquidGlassToolbarItem(
      id: 'archive',
      icon: _textOnly ? null : const NativeLiquidGlassIcon.sfSymbol('archivebox.fill'),
      label: _textOnly ? 'Archive' : null,
      iconSize: _useCustomIconSize ? _iconSize : null,
    ),
    LiquidGlassToolbarItem(
      id: 'delete',
      icon: _textOnly ? null : const NativeLiquidGlassIcon.iconData(Icons.delete),
      label: _textOnly ? 'Delete' : null,
      iconSize: _useCustomIconSize ? _iconSize : null,
      tintColor: _usePerItemColor ? Colors.red : null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LiquidGlassToolbar preview'),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Toolbar is shown below', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                      if (_lastTappedItem != null) ...[
                        const SizedBox(height: 12),
                        Text('Tapped: "$_lastTappedItem"', style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ],
                  ),
                ),
              ),
              LiquidGlassToolbar(
                items: _items,
                shadowColor: _useShadowColor ? Colors.transparent : null,
                iconWeight: _iconWeight,
                height: 32,
                itemSpacing: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                labelTextStyle: _useLabelTextStyle ? const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3) : null,
                onItemTapped: (id) => setState(() => _lastTappedItem = id),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Text-only items (no icons)'),
                          value: _textOnly,
                          onChanged: (v) => setState(() => _textOnly = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Flexible spacer'),
                          value: _flexibleSpacer,
                          onChanged: (v) => setState(() => _flexibleSpacer = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Per-item color (Reply=blue, Delete=red)'),
                          value: _usePerItemColor,
                          onChanged: (v) => setState(() => _usePerItemColor = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Hide separator (shadow)'),
                          value: _useShadowColor,
                          onChanged: (v) => setState(() => _useShadowColor = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Custom label text style'),
                          value: _useLabelTextStyle,
                          onChanged: (v) => setState(() => _useLabelTextStyle = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Custom icon size'),
                          value: _useCustomIconSize,
                          onChanged: (v) => setState(() => _useCustomIconSize = v),
                        ),
                        if (_useCustomIconSize)
                          Row(
                            children: [
                              const Text('Icon sz'),
                              Expanded(
                                child: Slider.adaptive(
                                  min: 14,
                                  max: 32,
                                  divisions: 18,
                                  value: _iconSize,
                                  label: _iconSize.toStringAsFixed(0),
                                  onChanged: (v) => setState(() => _iconSize = v),
                                ),
                              ),
                              Text(_iconSize.toStringAsFixed(0)),
                            ],
                          ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Icon weight', style: Theme.of(context).textTheme.titleSmall),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SegmentedButton<LiquidGlassToolbarIconWeight>(
                            segments: const [
                              ButtonSegment(value: LiquidGlassToolbarIconWeight.light, label: Text('Light')),
                              ButtonSegment(value: LiquidGlassToolbarIconWeight.regular, label: Text('Regular')),
                              ButtonSegment(value: LiquidGlassToolbarIconWeight.semibold, label: Text('Semi')),
                              ButtonSegment(value: LiquidGlassToolbarIconWeight.bold, label: Text('Bold')),
                            ],
                            selected: {_iconWeight},
                            onSelectionChanged: (sel) => setState(() => _iconWeight = sel.first),
                          ),
                        ),
                      ],
                    ),
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
