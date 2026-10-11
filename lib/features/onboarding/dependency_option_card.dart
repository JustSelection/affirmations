import 'package:flutter/material.dart';

import '../../domain/dependency.dart';

class DependencyOptionCard extends StatelessWidget {
  const DependencyOptionCard({
    required this.goal,
    required this.selected,
    required this.showSafetyNote,
    required this.onTap,
    super.key,
  });

  final Dependency goal;
  final bool selected;
  final bool showSafetyNote;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: Column(
        children: [
          Semantics(
            button: true,
            selected: selected,
            label: goal.title,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(goal.symbol, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 16),
                    Expanded(child: Text(goal.title)),
                    Icon(selected ? Icons.check_circle : Icons.circle_outlined),
                  ],
                ),
              ),
            ),
          ),
          if (showSafetyNote && goal.safetyNote != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                goal.safetyNote!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
