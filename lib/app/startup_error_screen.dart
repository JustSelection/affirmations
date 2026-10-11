import 'package:flutter/material.dart';

import '../state/app_controller.dart';

class StartupErrorScreen extends StatefulWidget {
  const StartupErrorScreen({
    required this.controller,
    required this.onRetry,
    required this.onCleared,
    super.key,
  });

  final AppController controller;
  final VoidCallback onRetry;
  final VoidCallback onCleared;

  @override
  State<StartupErrorScreen> createState() => _StartupErrorScreenState();
}

class _StartupErrorScreenState extends State<StartupErrorScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _clearSavedData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Удалить локальные данные?'),
        content: const Text(
          'Сохранённые данные повреждены. Удаление нельзя отменить; '
          'приложение запустится заново.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить данные'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.controller.clearUnreadableSavedData();
      widget.onCleared();
    } catch (error) {
      if (mounted) setState(() => _error = 'Не удалось удалить данные: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Не удалось прочитать данные приложения',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Данные не были перезаписаны. Повторите попытку или удалите '
                  'их, чтобы начать заново.',
                  textAlign: TextAlign.center,
                ),
                if (_error != null) Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : widget.onRetry,
                  child: const Text('Повторить'),
                ),
                TextButton(
                  onPressed: _busy ? null : _clearSavedData,
                  child: const Text('Удалить данные и начать заново'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
