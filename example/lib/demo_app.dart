import 'package:flutter/material.dart';

import 'pages/demo_catalog_page.dart';

class LiquidGlassDemoApp extends StatefulWidget {
  const LiquidGlassDemoApp({super.key});

  @override
  State<LiquidGlassDemoApp> createState() => _LiquidGlassDemoAppState();
}

class _LiquidGlassDemoAppState extends State<LiquidGlassDemoApp> {
  bool _isDarkTheme = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkTheme ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: DemoCatalogPage(
        onThemeChanged: (value) {
          setState(() {
            _isDarkTheme = value;
          });
        },
      ),
    );
  }
}
