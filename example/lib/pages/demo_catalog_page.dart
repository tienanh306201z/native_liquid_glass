import 'package:flutter/material.dart';

import '../widgets/theme_mode_action_button.dart';
import 'liquid_glass_activity_indicator_preview_page.dart';
import 'liquid_glass_alert_preview_page.dart';
import 'liquid_glass_button_group_preview_page.dart';
import 'liquid_glass_button_preview_page.dart';
import 'liquid_glass_color_picker_preview_page.dart';
import 'liquid_glass_container_preview_page.dart';
import 'liquid_glass_date_picker_preview_page.dart';
import 'liquid_glass_menu_preview_page.dart';
import 'liquid_glass_navigation_bar_preview_page.dart';
import 'liquid_glass_popover_preview_page.dart';
import 'liquid_glass_progress_view_preview_page.dart';
import 'liquid_glass_search_bar_preview_page.dart';
import 'liquid_glass_search_scaffold_preview_page.dart';
import 'liquid_glass_segmented_control_preview_page.dart';
import 'liquid_glass_sheet_preview_page.dart';
import 'liquid_glass_slider_preview_page.dart';
import 'liquid_glass_stepper_preview_page.dart';
import 'liquid_glass_tab_bar_preview_page.dart';
import 'liquid_glass_toggle_preview_page.dart';
import 'liquid_glass_toolbar_preview_page.dart';

class DemoCatalogPage extends StatelessWidget {
  final ValueChanged<bool> onThemeChanged;

  const DemoCatalogPage({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Liquid Glass Widgets'),
        actions: [ThemeModeActionButton(onThemeChanged: onThemeChanged)],
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.smart_button_outlined),
            title: const Text('LiquidGlassButton preview'),
            subtitle: const Text('Native glass-style button (text & icon-only)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassButtonPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.view_compact_alt_outlined),
            title: const Text('LiquidGlassTabBar preview'),
            subtitle: const Text('Native UITabBarController with per-item customizations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassTabBarPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('LiquidGlassContainer preview'),
            subtitle: const Text('Apply glass effect to any child widget'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassContainerPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.group_work_outlined),
            title: const Text('LiquidGlassButtonGroup preview'),
            subtitle: const Text('Grouped buttons with unified glass blending'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassButtonGroupPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('LiquidGlassSearchBar preview'),
            subtitle: const Text('Expandable search bar with glass effect'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassSearchBarPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.toggle_on_outlined),
            title: const Text('LiquidGlassToggle preview'),
            subtitle: const Text('Native glass-style toggle switches'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassTogglePreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune_rounded),
            title: const Text('LiquidGlassSlider preview'),
            subtitle: const Text('Native glass-style sliders'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassSliderPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.segment_rounded),
            title: const Text('LiquidGlassSegmentedControl preview'),
            subtitle: const Text('Native UISegmentedControl with glass effect'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassSegmentedControlPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded),
            title: const Text('LiquidGlassDatePicker preview'),
            subtitle: const Text('Native UIDatePicker with styles and modes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassDatePickerPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('LiquidGlassColorPicker preview'),
            subtitle: const Text('Native UIColorWell color picker'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassColorPickerPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_rounded),
            title: const Text('LiquidGlassMenu preview'),
            subtitle: const Text('Native UIMenu with submenus and destructive actions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassMenuPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new_rounded),
            title: const Text('LiquidGlassPopover preview'),
            subtitle: const Text('Native UIPopoverPresentationController'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassPopoverPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.table_rows_rounded),
            title: const Text('LiquidGlassSheet preview'),
            subtitle: const Text('Native UISheetPresentationController bottom sheet'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassSheetPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.warning_amber_rounded),
            title: const Text('LiquidGlassAlert preview'),
            subtitle: const Text('Native UIAlertController alert and action sheet'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassAlertPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.web_asset_rounded),
            title: const Text('LiquidGlassNavigationBar preview'),
            subtitle: const Text('Native UINavigationBar with glass effect'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassNavigationBarPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.space_bar_rounded),
            title: const Text('LiquidGlassToolbar preview'),
            subtitle: const Text('Native UIToolbar with flexible spacers'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassToolbarPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.tab_rounded),
            title: const Text('LiquidGlassSearchScaffold preview'),
            subtitle: const Text('Native UITabBarController with inline search'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassSearchScaffoldPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('LiquidGlassStepper preview'),
            subtitle: const Text('Native UIStepper with glass effect'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassStepperPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.hourglass_empty_rounded),
            title: const Text('LiquidGlassActivityIndicator preview'),
            subtitle: const Text('Native UIActivityIndicatorView'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassActivityIndicatorPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.linear_scale_rounded),
            title: const Text('LiquidGlassProgressView preview'),
            subtitle: const Text('Native UIProgressView'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => LiquidGlassProgressViewPreviewPage(onThemeChanged: onThemeChanged)));
            },
          ),
        ],
      ),
    );
  }
}
