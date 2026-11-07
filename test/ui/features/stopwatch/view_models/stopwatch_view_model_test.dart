import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stopwatch/ui/features/stopwatch/view_models/stopwatch_view_model.dart';

void main() {
  group('StopwatchViewModel', () {
    test('starts in ready state at zero elapsed time', () {
      final viewModel = StopwatchViewModel();
      addTearDown(viewModel.dispose);

      expect(viewModel.elapsed, Duration.zero);
      expect(viewModel.isRunning, isFalse);
      expect(viewModel.canStart, isTrue);
      expect(viewModel.canStop, isFalse);
      expect(viewModel.canReset, isFalse);
      expect(viewModel.status, StopwatchStatus.ready);
      expect(viewModel.minuteProgress, 0.0);
      expect(viewModel.formattedTime.fullText, '00:00.00');
    });

    test('counts elapsed time accurately and notifies listeners', () {
      fakeAsync((async) {
        final viewModel = StopwatchViewModel();
        var notifications = 0;
        viewModel.addListener(() => notifications++);

        viewModel.start();
        expect(viewModel.isRunning, isTrue);
        expect(viewModel.canStart, isFalse);
        expect(viewModel.canStop, isTrue);
        expect(viewModel.canReset, isTrue);
        expect(viewModel.status, StopwatchStatus.running);

        async.elapse(const Duration(seconds: 15, milliseconds: 250));

        expect(
          viewModel.elapsed,
          const Duration(seconds: 15, milliseconds: 250),
        );
        expect(viewModel.formattedTime.fullText, '00:15.25');
        expect(viewModel.minuteProgress, closeTo(15.25 / 60.0, 1e-6));
        expect(notifications, greaterThan(100));

        viewModel.dispose();
      });
    });

    test('stop freezes elapsed time and start resumes accumulation', () {
      fakeAsync((async) {
        final viewModel = StopwatchViewModel();

        viewModel.start();
        async.elapse(const Duration(seconds: 3, milliseconds: 400));
        viewModel.stop();

        expect(viewModel.isRunning, isFalse);
        expect(viewModel.status, StopwatchStatus.paused);
        expect(viewModel.canStart, isTrue);
        expect(viewModel.canStop, isFalse);
        expect(viewModel.canReset, isTrue);
        expect(viewModel.formattedTime.fullText, '00:03.40');

        // Time passing while stopped must not change elapsed time or notify.
        var pausedNotifications = 0;
        viewModel.addListener(() => pausedNotifications++);
        async.elapse(const Duration(seconds: 10));
        expect(viewModel.formattedTime.fullText, '00:03.40');
        expect(pausedNotifications, 0);

        // Resuming adds onto previously elapsed time.
        viewModel.start();
        async.elapse(const Duration(seconds: 1, milliseconds: 600));
        expect(viewModel.formattedTime.fullText, '00:05.00');

        viewModel.dispose();
      });
    });

    test('reset clears elapsed time from both paused and running states', () {
      fakeAsync((async) {
        final viewModel = StopwatchViewModel();

        // Reset while running.
        viewModel.start();
        async.elapse(const Duration(seconds: 4, milliseconds: 120));
        viewModel.reset();

        expect(viewModel.isRunning, isFalse);
        expect(viewModel.elapsed, Duration.zero);
        expect(viewModel.status, StopwatchStatus.ready);
        expect(viewModel.canReset, isFalse);
        expect(viewModel.formattedTime.fullText, '00:00.00');

        // Reset while paused.
        viewModel.start();
        async.elapse(const Duration(seconds: 2));
        viewModel.stop();
        viewModel.reset();

        expect(viewModel.elapsed, Duration.zero);
        expect(viewModel.status, StopwatchStatus.ready);
        expect(viewModel.formattedTime.fullText, '00:00.00');

        viewModel.dispose();
      });
    });

    test('duplicate start, stop, and reset calls are safe no-ops', () {
      fakeAsync((async) {
        final viewModel = StopwatchViewModel();
        var notifications = 0;
        viewModel.addListener(() => notifications++);

        // Stop and reset when already at zero do not notify.
        viewModel.stop();
        viewModel.reset();
        expect(notifications, 0);

        // Duplicate start while running does not notify twice.
        viewModel.start();
        expect(notifications, 1);
        viewModel.start();
        expect(notifications, 1);

        viewModel.dispose();
      });
    });

    test(
      'formatDuration handles sub-minute, multi-hour, and negative values',
      () {
        expect(
          StopwatchViewModel.formatDuration(const Duration(milliseconds: -50))
              .fullText,
          '00:00.00',
        );

        final underHour = StopwatchViewModel.formatDuration(
          const Duration(minutes: 9, seconds: 5, milliseconds: 78),
        );
        expect(underHour.mainTime, '09:05');
        expect(underHour.centiseconds, '.07');
        expect(underHour.fullText, '09:05.07');
        expect(
          underHour.semanticsLabel,
          'Elapsed time: 9 minutes, 5.07 seconds',
        );

        final overHour = StopwatchViewModel.formatDuration(
          const Duration(hours: 1, minutes: 1, seconds: 1),
        );
        expect(overHour.fullText, '01:01:01.00');
        expect(
          overHour.semanticsLabel,
          'Elapsed time: 1 hour, 1 minute, 1 second',
        );
      },
    );
  });
}
