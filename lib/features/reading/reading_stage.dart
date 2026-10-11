import 'dart:ui';

import 'package:flutter/material.dart';

class ReadingStage extends StatelessWidget {
  const ReadingStage({
    required this.remainingSeconds,
    required this.affirmation,
    required this.paused,
    required this.onAdvance,
    required this.onPause,
    required this.onResume,
    this.error,
    this.onRetry,
    super.key,
  });

  final int remainingSeconds;
  final String affirmation;
  final bool paused;
  final VoidCallback onAdvance;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final minutes = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSeconds % 60).toString().padLeft(2, '0');
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                '$minutes:$seconds',
                semanticsLabel: '$minutes минут $seconds секунд',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAdvance,
                onHorizontalDragEnd: (details) {
                  final speed = details.primaryVelocity?.abs() ?? 0;
                  if (speed > 150) {
                    onAdvance();
                  }
                },
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: animation.drive(
                          Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ),
                        ),
                        child: child,
                      ),
                    ),
                    child: Padding(
                      key: ValueKey(affirmation),
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Text(
                        affirmation,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Пауза',
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                  ),
                  const SizedBox(width: 16),
                  IconButton.filledTonal(
                    tooltip: 'Следующая аффирмация',
                    onPressed: onAdvance,
                    icon: const Icon(Icons.skip_next),
                  ),
                ],
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(child: Text(error!, textAlign: TextAlign.center)),
                    if (onRetry != null)
                      TextButton(
                        onPressed: onRetry,
                        child: const Text('Повторить'),
                      ),
                  ],
                ),
              ),
          ],
        ),
        if (paused)
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface
                      .withValues(alpha: 0.55),
                  child: Center(
                    child: FilledButton.icon(
                      onPressed: onResume,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Продолжить'),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
