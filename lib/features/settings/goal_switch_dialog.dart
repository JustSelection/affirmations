import 'package:flutter/material.dart';

import '../../domain/dependency.dart';

Future<Dependency?> showGoalSwitchDialog(
  BuildContext context,
  Iterable<Dependency> choices,
) async {
  final available = choices.toList(growable: false);
  if (available.isEmpty) return null;

  final selected = await showDialog<Dependency>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Выберите следующую цель'),
      children: [
        for (final goal in available)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, goal),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${goal.symbol}  ${goal.title}'),
                  if (goal.safetyNote != null)
                    Text(
                      goal.safetyNote!,
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
  if (selected == null || !context.mounted) return null;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Сменить цель?'),
      content: const Text(
        'Прогресс текущей цели сохранится. Ежедневные чтения переключатся '
        'на выбранную цель.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Продолжить'),
        ),
      ],
    ),
  );
  return confirmed == true ? selected : null;
}
