import 'package:flutter/material.dart';

import '../../domain/goal_progress.dart';
import '../../state/app_controller.dart';
import '../reading/reading_screen.dart';
import '../settings/settings_sheet.dart';
import 'progress_ring.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({required this.controller, super.key});

  final AppController controller;

  Future<void> _openReading(BuildContext context) async {
    try {
      final goal = controller.state.activeGoal;
      if (goal == null) throw StateError('Choose a goal before reading.');
      if (controller.state.progressFor(goal).session == null) {
        await controller.startReading();
      }
      if (!context.mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ReadingScreen(controller: controller),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть чтение: $error')),
      );
    }
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SettingsSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final goal = state.activeGoal;
    if (goal == null) {
      return const Scaffold(
        body: Center(child: Text('Сначала выберите цель в настройках.')),
      );
    }
    final progress = state.progressFor(goal);
    final target = progress.continuesAfterThirtyDays
        ? GoalProgress.victoryDay
        : GoalProgress.requiredDays;
    final completeToday = progress.completedOn(DateTime.now());
    final sessionExists = progress.session != null;
    final label = completeToday
        ? '✓'
        : sessionExists
        ? 'Продолжить'
        : 'Начать';

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
        actions: [
          IconButton(
            tooltip: 'Настройки',
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'День ${progress.currentDay} из $target',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 28),
                  ProgressRing(
                    progress: progress.completedCount / target,
                    label: label,
                    semanticLabel: completeToday
                        ? 'День завершён'
                        : '$label. День ${progress.currentDay}',
                    completed: completeToday,
                    onTap: completeToday ? null : () => _openReading(context),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    completeToday
                        ? 'Сегодняшнее чтение завершено'
                        : 'До полной победы: '
                              '${GoalProgress.victoryDay - progress.completedCount} дней',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ежедневная практика — это самоподдержка, а не лечение.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
