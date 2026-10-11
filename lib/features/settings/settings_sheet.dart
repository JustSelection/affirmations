import 'package:flutter/material.dart';

import '../../state/app_controller.dart';
import 'goal_switch_dialog.dart';
import 'reset_confirm_dialog.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({required this.controller, super.key});

  final AppController controller;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _changeGoal() async {
    final current = widget.controller.state.activeGoal;
    if (current == null) return;
    final choices = widget.controller.state.selectedGoals.where(
      (goal) => goal != current,
    );
    final selected = await showGoalSwitchDialog(context, choices);
    if (selected == null || !mounted) return;
    await _run(() async {
      await widget.controller.changeActiveGoal(selected);
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _reset() async {
    final confirmed = await confirmProgressReset(context);
    if (!confirmed || !mounted) return;
    await _run(() async {
      await widget.controller.reset();
      if (mounted) Navigator.of(context).pop();
    });
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
        setState(() => _error = 'Не удалось выполнить действие: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.controller.state.activeGoal;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Настройки', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ListTile(
              enabled: !_busy && goal != null,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Сменить активную цель'),
              subtitle: Text(goal == null ? 'Цель не выбрана' : goal.title),
              trailing: const Icon(Icons.chevron_right),
              onTap: _changeGoal,
            ),
            const Divider(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            TextButton(
              onPressed: _busy ? null : _reset,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Сбросить весь прогресс'),
            ),
            const Text(
              'Приложение помогает в ежедневной самоподдержке и не заменяет '
              'профессиональную помощь.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
