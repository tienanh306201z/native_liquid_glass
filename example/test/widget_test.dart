import 'package:flutter_test/flutter_test.dart';
import 'package:native_liquid_glass_example/demo_app.dart';

void main() {
  testWidgets('renders catalog and opens LiquidGlassTabBar preview', (WidgetTester tester) async {
    await tester.pumpWidget(const LiquidGlassDemoApp());

    expect(find.text('Native Liquid Glass Widgets'), findsOneWidget);
    expect(find.text('LiquidGlassTabBar preview'), findsOneWidget);

    await tester.tap(find.text('LiquidGlassTabBar preview'));
    await tester.pumpAndSettle();

    expect(find.text('Selected tab: Home'), findsOneWidget);
    expect(find.text('Show labels'), findsOneWidget);
  });
}
