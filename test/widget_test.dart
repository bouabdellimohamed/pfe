// JURISDZ App Widget Test
import 'package:flutter_test/flutter_test.dart';
import 'package:first_app/main.dart';

void main() {
  testWidgets('JurisdZApp smoke test', (WidgetTester tester) async {
    // Just verify the app launches without crashing
    await tester.pumpWidget(const JurisdZApp());
    expect(find.byType(JurisdZApp), findsOneWidget);
  });
}
