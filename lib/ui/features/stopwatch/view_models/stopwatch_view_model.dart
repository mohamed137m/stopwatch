import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';

/// Formatted components of an elapsed stopwatch [Duration].
@immutable
class FormattedElapsedTime {
  /// Creates a [FormattedElapsedTime] from its display and accessibility parts.
  const FormattedElapsedTime({
    required this.mainTime,
    required this.centiseconds,
    required this.semanticsLabel,
  });

  /// Primary minutes and seconds (and optional hours) segment, such as `01:23`.
  final String mainTime;

  /// Fractional centiseconds segment prefixed with a dot, such as `.45`.
  final String centiseconds;

  /// Screen-reader friendly description of the elapsed duration.
  final String semanticsLabel;

  /// Complete formatted time string, such as `01:23.45` or `01:02:03.45`.
  String get fullText => '$mainTime$centiseconds';
}

/// Visual operational state of the stopwatch.
enum StopwatchStatus {
  /// Stopwatch is at zero and has not started.
  ready,

  /// Stopwatch is actively counting up.
  running,

  /// Stopwatch is stopped with non-zero elapsed time.
  paused,
}

/// Manages stopwatch timing state and user commands.
class StopwatchViewModel extends ChangeNotifier {
  /// Creates a [StopwatchViewModel] using an optional custom [stopwatch].
  StopwatchViewModel({Stopwatch? stopwatch})
    : _stopwatch = stopwatch ?? clock.stopwatch();

  static const Duration _tickInterval = Duration(milliseconds: 10);

  final Stopwatch _stopwatch;
  Timer? _timer;

  /// Total elapsed time measured by the stopwatch.
  Duration get elapsed => _stopwatch.elapsed;

  /// Whether the stopwatch is currently counting elapsed time.
  bool get isRunning => _stopwatch.isRunning;

  /// Whether the start action is currently available.
  bool get canStart => !isRunning;

  /// Whether the stop action is currently available.
  bool get canStop => isRunning;

  /// Whether the reset action is currently available.
  bool get canReset => isRunning || elapsed > Duration.zero;

  /// Current high-level operational status of the stopwatch.
  StopwatchStatus get status {
    if (isRunning) {
      return StopwatchStatus.running;
    }
    if (elapsed > Duration.zero) {
      return StopwatchStatus.paused;
    }
    return StopwatchStatus.ready;
  }

  /// Fractional progress through the current 60-second minute cycle in `[0, 1)`.
  double get minuteProgress {
    final msInMinute = elapsed.inMilliseconds.clamp(0, 1 << 62) % 60000;
    return msInMinute / 60000.0;
  }

  /// Formatted representation of [elapsed] for UI rendering and accessibility.
  FormattedElapsedTime get formattedTime =>
      formatDuration(elapsed, includeCentisecondsInSemantics: !isRunning);

  /// Starts or resumes counting elapsed time.
  void start() {
    if (isRunning) {
      return;
    }
    _stopwatch.start();
    _timer?.cancel();
    _timer = Timer.periodic(_tickInterval, (_) {
      notifyListeners();
    });
    notifyListeners();
  }

  /// Stops counting while preserving the current [elapsed] time.
  void stop() {
    if (!isRunning) {
      return;
    }
    _stopwatch.stop();
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  /// Stops counting and resets [elapsed] back to [Duration.zero].
  void reset() {
    if (!canReset) {
      return;
    }
    _stopwatch
      ..stop()
      ..reset();
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  /// Formats [duration] into main time, centiseconds, and semantics strings.
  static FormattedElapsedTime formatDuration(
    Duration duration, {
    bool includeCentisecondsInSemantics = true,
  }) {
    final clampedMs = duration.isNegative ? 0 : duration.inMilliseconds;
    final totalCentiseconds = clampedMs ~/ 10;
    final centiseconds = totalCentiseconds % 100;
    final totalSeconds = totalCentiseconds ~/ 100;
    final seconds = totalSeconds % 60;
    final totalMinutes = totalSeconds ~/ 60;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    final paddedMinutes = minutes.toString().padLeft(2, '0');
    final paddedSeconds = seconds.toString().padLeft(2, '0');
    final paddedCentiseconds = centiseconds.toString().padLeft(2, '0');

    final mainTime = hours > 0
        ? '${hours.toString().padLeft(2, '0')}:$paddedMinutes:$paddedSeconds'
        : '$paddedMinutes:$paddedSeconds';

    final parts = <String>[
      if (hours > 0) '$hours ${hours == 1 ? 'hour' : 'hours'}',
      '$minutes ${minutes == 1 ? 'minute' : 'minutes'}',
      if (includeCentisecondsInSemantics && centiseconds > 0)
        '$seconds.$paddedCentiseconds seconds'
      else
        '$seconds ${seconds == 1 ? 'second' : 'seconds'}',
    ];

    return FormattedElapsedTime(
      mainTime: mainTime,
      centiseconds: '.$paddedCentiseconds',
      semanticsLabel: 'Elapsed time: ${parts.join(', ')}',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    super.dispose();
  }
}

