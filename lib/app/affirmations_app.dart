import 'package:flutter/material.dart';

import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/progress/finished_screen.dart';
import '../features/progress/thirty_day_milestone_screen.dart';
import '../features/progress/victory_screen.dart';
import '../state/app_controller.dart';
import 'app_theme.dart';
import 'startup_error_screen.dart';

class AffirmationsApp extends StatelessWidget {
  const AffirmationsApp({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Affirmations',
    debugShowCheckedModeBanner: false,
    restorationScopeId: 'affirmations-root',
    themeMode: ThemeMode.system,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    home: AppGate(controller: controller),
  );
}

class AppGate extends StatefulWidget {
  const AppGate({required this.controller, super.key});

  final AppController controller;

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  late Future<void> _loading;

  @override
  void initState() {
    super.initState();
    _loading = widget.controller.initialize();
  }

  void _retry() => setState(() {
    _loading = widget.controller.initialize();
  });

  void _continueAfterRecovery() => setState(() {
    _loading = Future<void>.value();
  });

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return StartupErrorScreen(
          controller: widget.controller,
          onRetry: _retry,
          onCleared: _continueAfterRecovery,
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) => _screenForState(),
      );
    },
  );

  Widget _screenForState() {
    final controller = widget.controller;
    final state = controller.state;
    if (state.hasFinishedAppWork) return const FinishedScreen();
    if (!state.onboardingStarted) {
      return WelcomeScreen(onStart: controller.startOnboarding);
    }
    final activeGoal = state.activeGoal;
    if (state.selectedGoals.isEmpty || activeGoal == null) {
      return OnboardingScreen(controller: controller);
    }

    final progress = state.progressFor(activeGoal);
    if (progress.hasWon) return VictoryScreen(controller: controller);
    if (progress.needsThirtyDayChoice) {
      return ThirtyDayMilestoneScreen(controller: controller);
    }
    return HomeScreen(controller: controller);
  }
}
