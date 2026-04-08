import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:native_liquid_glass_example/demo_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders catalog then opens LiquidGlass preview', (WidgetTester tester) async {
    await tester.pumpWidget(const LiquidGlassDemoApp());

    expect(find.text('Native Liquid Glass Widgets'), findsOneWidget);

    await tester.tap(find.text('LiquidGlassTabBar preview'));
    await tester.pumpAndSettle();

    expect(find.text('Selected tab: Home'), findsOneWidget);
  });
}
