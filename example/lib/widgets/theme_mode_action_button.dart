import 'package:flutter/material.dart';

class ThemeModeActionButton extends StatelessWidget {
  final ValueChanged<bool> onThemeChanged;

  const ThemeModeActionButton({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    return IconButton(
      tooltip: isDarkTheme ? 'Switch to light theme' : 'Switch to dark theme',
      icon: Icon(isDarkTheme ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
      onPressed: () => onThemeChanged(!isDarkTheme),
    );
  }
}
