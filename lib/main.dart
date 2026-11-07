import 'package:flutter/material.dart';

import 'ui/core/theme/app_theme.dart';
import 'ui/features/stopwatch/views/stopwatch_screen.dart';

void main() {
  runApp(const StopwatchApp());
}

/// Root widget configuring theming and navigation for the Stopwatch mobile app.
class StopwatchApp extends StatelessWidget {
  /// Creates the root [StopwatchApp].
  const StopwatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stopwatch',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const StopwatchScreen(),
    );
  }
}
