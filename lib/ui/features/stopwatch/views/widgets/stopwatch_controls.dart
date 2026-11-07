import 'package:flutter/material.dart';

/// Action buttons for starting, stopping, and resetting the stopwatch.
class StopwatchControls extends StatelessWidget {
  /// Creates [StopwatchControls] bound to the stopwatch state and callbacks.
  const StopwatchControls({
    super.key,
    required this.canStart,
    required this.canStop,
    required this.canReset,
    required this.onStart,
    required this.onStop,
    required this.onReset,
  });

  /// Whether the Start button is enabled.
  final bool canStart;

  /// Whether the Stop button is enabled.
  final bool canStop;

  /// Whether the Reset button is enabled.
  final bool canReset;

  /// Callback invoked when the user taps Start.
  final VoidCallback onStart;

  /// Callback invoked when the user taps Stop.
  final VoidCallback onStop;

  /// Callback invoked when the user taps Reset.
  final VoidCallback onReset;

  static const double _buttonHeight = 56.0;
  static const TextStyle _labelStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final startButton = FilledButton.icon(
      key: const Key('start_button'),
      onPressed: canStart ? onStart : null,
      style: FilledButton.styleFrom(
        minimumSize: const Size(112, _buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: _labelStyle,
      ),
      icon: const Icon(Icons.play_arrow_rounded, size: 24),
      label: const Text('Start'),
    );

    final stopButton = FilledButton.icon(
      key: const Key('stop_button'),
      onPressed: canStop ? onStop : null,
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.error,
        foregroundColor: colorScheme.onError,
        minimumSize: const Size(112, _buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
        textStyle: _labelStyle,
      ),
      icon: const Icon(Icons.stop_rounded, size: 24),
      label: const Text('Stop'),
    );

    final resetButton = OutlinedButton.icon(
      key: const Key('reset_button'),
      onPressed: canReset ? onReset : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        minimumSize: const Size(112, _buttonHeight),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
        side: BorderSide(
          color: canReset
              ? colorScheme.outline
              : colorScheme.onSurface.withValues(alpha: 0.12),
        ),
        textStyle: _labelStyle,
      ),
      icon: const Icon(Icons.refresh_rounded, size: 22),
      label: const Text('Reset'),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactWidth =
            constraints.hasBoundedWidth && constraints.maxWidth < 280;

        if (isCompactWidth) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              startButton,
              const SizedBox(height: 12),
              stopButton,
              const SizedBox(height: 12),
              resetButton,
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: startButton),
                const SizedBox(width: 14),
                Expanded(child: stopButton),
              ],
            ),
            const SizedBox(height: 14),
            resetButton,
          ],
        );
      },
    );
  }
}
