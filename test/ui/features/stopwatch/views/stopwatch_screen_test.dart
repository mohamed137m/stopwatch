import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch/ui/core/theme/app_theme.dart';
import 'package:stopwatch/ui/features/stopwatch/views/stopwatch_screen.dart';

void main() {
  Widget buildTestApp({Brightness brightness = Brightness.light}) {
    return MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
      home: const StopwatchScreen(),
    );
  }

  group('StopwatchScreen interactions', () {
    testWidgets('displays initial zero state and Start, Stop, Reset buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());

      expect(find.text('Stopwatch'), findsOneWidget);
      expect(find.text('READY'), findsOneWidget);
      expect(find.text('00:00.00'), findsOneWidget);

      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);

      final startButton = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('start_button')),
      );
      final stopButton = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('stop_button')),
      );
      final resetButton = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('reset_button')),
      );

      expect(startButton.onPressed, isNotNull);
      expect(stopButton.onPressed, isNull);
      expect(resetButton.onPressed, isNull);
    });

    testWidgets('starts, stops, resumes, and resets elapsed time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());

      // Start the stopwatch and advance 2.35 seconds.
      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(seconds: 2, milliseconds: 350));

      expect(find.text('RUNNING'), findsOneWidget);
      expect(find.text('00:02.35'), findsOneWidget);

      // Stop the stopwatch and verify it stays paused across elapsed time.
      await tester.tap(find.text('Stop'));
      await tester.pump();

      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('00:02.35'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      expect(find.text('00:02.35'), findsOneWidget);

      // Resume from paused time and advance 1.65 seconds -> 00:04.00.
      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(seconds: 1, milliseconds: 650));

      expect(find.text('RUNNING'), findsOneWidget);
      expect(find.text('00:04.00'), findsOneWidget);

      // Stop then Reset back to 00:00.00.
      await tester.tap(find.text('Stop'));
      await tester.pump();
      await tester.tap(find.text('Reset'));
      await tester.pump();

      expect(find.text('READY'), findsOneWidget);
      expect(find.text('00:00.00'), findsOneWidget);
    });

    testWidgets('reset while running stops and clears elapsed time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestApp());

      await tester.tap(find.text('Start'));
      await tester.pump(const Duration(minutes: 1, seconds: 12));
      expect(find.text('01:12.00'), findsOneWidget);

      await tester.tap(find.text('Reset'));
      await tester.pump();

      expect(find.text('READY'), findsOneWidget);
      expect(find.text('00:00.00'), findsOneWidget);

      // Confirm timer stays stopped after reset.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('00:00.00'), findsOneWidget);
    });
  });

  group('StopwatchScreen responsiveness and accessibility', () {
    testWidgets(
      'adapts cleanly across small portrait, landscape, and 2x font',
      (WidgetTester tester) async {
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Small mobile screen with 2.0x accessibility text scaling.
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(320, 568);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: buildTestApp(),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('00:00.00'), findsOneWidget);

        // Mobile landscape layout.
        tester.view.physicalSize = const Size(844, 390);
        await tester.pumpWidget(buildTestApp(brightness: Brightness.dark));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('Start'), findsOneWidget);
        expect(find.text('Stop'), findsOneWidget);
        expect(find.text('Reset'), findsOneWidget);
      },
    );

    testWidgets('meets mobile tap target, label, and contrast guidelines', (
      WidgetTester tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        for (final brightness in Brightness.values) {
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey<Brightness>(brightness),
              theme: brightness == Brightness.light
                  ? AppTheme.light
                  : AppTheme.dark,
              home: const StopwatchScreen(),
            ),
          );
          await tester.pumpAndSettle();

          await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
          await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
          await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
          await expectLater(tester, meetsGuideline(textContrastGuideline));

          // Running state contrast check (pump twice so button theme settles).
          await tester.tap(find.text('Start'));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1, milliseconds: 250));
          await expectLater(tester, meetsGuideline(textContrastGuideline));

          // Paused state contrast check.
          await tester.tap(find.text('Stop'));
          await tester.pumpAndSettle();
          await expectLater(tester, meetsGuideline(textContrastGuideline));
        }
      } finally {
        handle.dispose();
      }
    });
  });
}
