import 'package:flutter/material.dart';

import '../view_models/stopwatch_view_model.dart';
import 'widgets/stopwatch_controls.dart';
import 'widgets/stopwatch_dial.dart';

/// Primary screen presenting the stopwatch dial and Start, Stop, Reset controls.
class StopwatchScreen extends StatefulWidget {
  /// Creates a [StopwatchScreen] with an optional externally managed [viewModel].
  const StopwatchScreen({super.key, this.viewModel});

  /// Optional [StopwatchViewModel] injected for state sharing or testing.
  final StopwatchViewModel? viewModel;

  @override
  State<StopwatchScreen> createState() => _StopwatchScreenState();
}

class _StopwatchScreenState extends State<StopwatchScreen> {
  StopwatchViewModel? _ownedViewModel;

  StopwatchViewModel get _viewModel => widget.viewModel ?? _ownedViewModel!;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel == null) {
      _ownedViewModel = StopwatchViewModel();
    }
  }

  @override
  void didUpdateWidget(StopwatchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.viewModel != oldWidget.viewModel) {
      if (widget.viewModel != null) {
        _ownedViewModel?.dispose();
        _ownedViewModel = null;
      } else {
        _ownedViewModel ??= StopwatchViewModel();
      }
    }
  }

  @override
  void dispose() {
    _ownedViewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stopwatch')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            final dial = StopwatchDial(
              formattedTime: _viewModel.formattedTime,
              status: _viewModel.status,
              minuteProgress: _viewModel.minuteProgress,
            );

            final controls = StopwatchControls(
              canStart: _viewModel.canStart,
              canStop: _viewModel.canStop,
              canReset: _viewModel.canReset,
              onStart: _viewModel.start,
              onStop: _viewModel.stop,
              onReset: _viewModel.reset,
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWideLayout =
                    constraints.maxWidth >= 600 ||
                    (constraints.maxWidth > constraints.maxHeight &&
                        constraints.maxHeight < 500);

                if (isWideLayout) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 840),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(flex: 6, child: Center(child: dial)),
                            const SizedBox(width: 32),
                            Expanded(
                              flex: 5,
                              child: SingleChildScrollView(child: controls),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                      child: Column(
                        children: [
                          Expanded(child: Center(child: dial)),
                          const SizedBox(height: 24),
                          controls,
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
