import 'package:flutter/material.dart';

Future<bool> confirmProgressReset(BuildContext context) async {
  final firstConfirmation = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Сбросить прогресс?'),
      content: const Text(
        'Весь прогресс будет удалён без возможности восстановления.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Далее'),
        ),
      ],
    ),
  );
  if (firstConfirmation != true || !context.mounted) return false;

  final finalConfirmation = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Подтвердите окончательное удаление'),
      content: const Text('Это действие нельзя отменить. Удалить все данные?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Сохранить прогресс'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Удалить'),
        ),
      ],
    ),
  );
  return finalConfirmation == true;
}
