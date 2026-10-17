import 'package:flutter_test/flutter_test.dart';
import 'package:spence/main.dart';

void main() {
  testWidgets('ExpenseTrackerApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExpenseTrackerApp());

    // Verify that main bottom nav tabs appear
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Reports'), findsOneWidget);
  });
}
