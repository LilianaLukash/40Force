import 'package:flutter_test/flutter_test.dart';

import 'package:force40/main.dart';

void main() {
  testWidgets('shows navigation and opens card of the day',
      (WidgetTester tester) async {
    await tester.pumpWidget(const Force40App());

    expect(find.text('40FORCE'), findsWidgets);
    expect(find.text('Calendar'), findsOneWidget);

    await tester.tap(find.text('Graphs'));
    await tester.pumpAndSettle();
    expect(find.text('Sleep'), findsWidgets);

    await tester.tap(find.text('Card'));
    await tester.pumpAndSettle();
    expect(find.textContaining('coffee'), findsWidgets);
    expect(find.textContaining('does not show a cause'), findsOneWidget);
  });
}
