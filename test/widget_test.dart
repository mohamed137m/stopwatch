import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch/main.dart';

void main() {
  testWidgets('StopwatchApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StopwatchApp());

    expect(find.text('00:00.00'), findsOneWidget);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);
    expect(find.text('Reset'), findsOneWidget);

    await tester.tap(find.text('Start'));
    await tester.pump(const Duration(seconds: 1, milliseconds: 500));
    expect(find.text('00:01.50'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    await tester.pump();
    expect(find.text('00:01.50'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pump();
    expect(find.text('00:00.00'), findsOneWidget);
  });
}
