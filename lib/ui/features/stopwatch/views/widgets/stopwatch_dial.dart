import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../view_models/stopwatch_view_model.dart';

/// Circular chronograph dial and tabular digital readout for elapsed time.
class StopwatchDial extends StatelessWidget {
  /// Creates a [StopwatchDial] displaying [formattedTime] and [minuteProgress].
  const StopwatchDial({
    super.key,
    required this.formattedTime,
    required this.status,
    required this.minuteProgress,
  });

  /// Formatted time segments to render inside the dial.
  final FormattedElapsedTime formattedTime;

  /// Current operational status of the stopwatch.
  final StopwatchStatus status;

  /// Progress around the 60-second dial ring in the range `[0.0, 1.0)`.
  final double minuteProgress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accentColor = switch (status) {
      StopwatchStatus.running => colorScheme.primary,
      StopwatchStatus.paused => colorScheme.tertiary,
      StopwatchStatus.ready => colorScheme.onSurfaceVariant,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.hasBoundedWidth ? constraints.maxWidth : 280.0;
        final maxH = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 280.0;
        final diameter = math.min(maxW, maxH).clamp(160.0, 340.0);
        final innerPadding = diameter * 0.16;

        return SizedBox.square(
          dimension: diameter,
          child: CustomPaint(
            painter: _StopwatchDialPainter(
              progress: minuteProgress,
              activeColor: accentColor,
              trackColor: colorScheme.surfaceContainerHighest,
              tickColor: colorScheme.onSurfaceVariant,
              surfaceColor: colorScheme.surfaceContainerLow,
              showProgressIndicator:
                  status != StopwatchStatus.ready || minuteProgress > 0,
            ),
            child: Padding(
              padding: EdgeInsets.all(innerPadding),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StatusBadge(status: status, accentColor: accentColor),
                      const SizedBox(height: 14),
                      Text.rich(
                        key: const Key('elapsed_time_text'),
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formattedTime.mainTime,
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                                letterSpacing: -1.2,
                                height: 1.05,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: formattedTime.centiseconds,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                                color: status == StopwatchStatus.running
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                                letterSpacing: -0.5,
                                height: 1.05,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        semanticsLabel: formattedTime.semanticsLabel,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.accentColor});

  final StopwatchStatus status;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final (label, icon) = switch (status) {
      StopwatchStatus.ready => ('READY', Icons.timelapse_rounded),
      StopwatchStatus.running => ('RUNNING', Icons.fiber_manual_record_rounded),
      StopwatchStatus.paused => ('PAUSED', Icons.pause_circle_filled_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accentColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopwatchDialPainter extends CustomPainter {
  const _StopwatchDialPainter({
    required this.progress,
    required this.activeColor,
    required this.trackColor,
    required this.tickColor,
    required this.surfaceColor,
    required this.showProgressIndicator,
  });

  final double progress;
  final Color activeColor;
  final Color trackColor;
  final Color tickColor;
  final Color surfaceColor;
  final bool showProgressIndicator;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outerRadius = math.min(size.width, size.height) / 2;
    const strokeWidth = 8.0;
    final ringRadius = outerRadius - strokeWidth;

    // Subtle elevated inner face.
    final facePaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, ringRadius - 4, facePaint);

    // Background circular track.
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, ringRadius, trackPaint);

    // 60 chronograph second tick marks inside the ring.
    final tickOuterRadius = ringRadius - strokeWidth / 2 - 6;
    for (var i = 0; i < 60; i++) {
      final isMajor = i % 5 == 0;
      final angle = -math.pi / 2 + (i / 60) * 2 * math.pi;
      final tickLength = isMajor ? 8.0 : 4.0;
      final innerRadius = tickOuterRadius - tickLength;

      final p1 = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + tickOuterRadius * math.cos(angle),
        center.dy + tickOuterRadius * math.sin(angle),
      );

      final tickPaint = Paint()
        ..color = tickColor.withValues(alpha: isMajor ? 0.45 : 0.18)
        ..strokeWidth = isMajor ? 2.0 : 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, tickPaint);
    }

    if (!showProgressIndicator) {
      return;
    }

    // Active progress sweep arc from 12 o'clock.
    final sweepAngle = progress.clamp(0.0, 1.0) * 2 * math.pi;
    final progressPaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }

    // Indicator dot on the active tip of the sweep.
    final tipAngle = -math.pi / 2 + sweepAngle;
    final tipCenter = Offset(
      center.dx + ringRadius * math.cos(tipAngle),
      center.dy + ringRadius * math.sin(tipAngle),
    );
    canvas.drawCircle(tipCenter, 6.5, Paint()..color = activeColor);
    canvas.drawCircle(tipCenter, 3.0, Paint()..color = surfaceColor);
  }

  @override
  bool shouldRepaint(_StopwatchDialPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.tickColor != tickColor ||
        oldDelegate.surfaceColor != surfaceColor ||
        oldDelegate.showProgressIndicator != showProgressIndicator;
  }
}
