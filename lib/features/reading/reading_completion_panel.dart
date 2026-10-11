import 'package:flutter/material.dart';

import '../home/progress_ring.dart';

class ReadingCompletionPanel extends StatelessWidget {
  const ReadingCompletionPanel({
    required this.day,
    required this.target,
    super.key,
  });

  final int day;
  final int target;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'День $day завершён',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          const ProgressRing(
            progress: 1,
            label: '✓',
            semanticLabel: 'День завершён',
            completed: true,
            onTap: null,
          ),
          const SizedBox(height: 16),
          Text('Прогресс: $day из $target дней'),
        ],
      ),
    );
  }
}
