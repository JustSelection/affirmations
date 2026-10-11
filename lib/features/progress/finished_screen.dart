import 'package:flutter/material.dart';

class FinishedScreen extends StatelessWidget {
  const FinishedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.spa_outlined, size: 64),
                const SizedBox(height: 24),
                Text(
                  'Спасибо за вашу работу',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Вы завершили выбранные этапы. Берегите себя и при необходимости '
                  'обращайтесь за поддержкой к близким и специалистам.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  'Приложение можно закрыть. Ваш прогресс сохранён на устройстве.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
