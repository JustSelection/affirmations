import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import '../settings/goal_switch_dialog.dart';

class ThirtyDayMilestoneScreen extends StatefulWidget {
  const ThirtyDayMilestoneScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<ThirtyDayMilestoneScreen> createState() =>
      _ThirtyDayMilestoneScreenState();
}

class _ThirtyDayMilestoneScreenState extends State<ThirtyDayMilestoneScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _continue() => _run(widget.controller.continueAfterThirtyDays);

  Future<void> _chooseNext() async {
    final current = widget.controller.state.activeGoal;
    if (current == null) return;
    final choices = widget.controller.state.selectedGoals.where(
      (goal) => goal != current,
    );
    final goal = await showGoalSwitchDialog(context, choices);
    if (goal != null && mounted) {
      await _run(() => widget.controller.changeActiveGoal(goal));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Не удалось сохранить решение: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.controller.state.activeGoal;
    final hasNext = widget.controller.state.selectedGoals.any(
      (goal) => goal != current,
    );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.spa_outlined, size: 56),
                  const SizedBox(height: 20),
                  Text(
                    'Первые 30 дней позади',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Вы завершили обязательную часть программы. '
                    'Продолжайте ежедневную практику по желанию или выберите '
                    'следующую цель. Прогресс по каждой цели сохраняется отдельно.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _continue,
                      child: const Text('Продолжать ежедневно'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _busy || !hasNext ? null : _chooseNext,
                      child: const Text('Взять следующую цель'),
                    ),
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
