import 'package:flutter/material.dart';

class ProgressRing extends StatefulWidget {
  const ProgressRing({
    required this.progress,
    required this.label,
    required this.semanticLabel,
    required this.completed,
    required this.onTap,
    super.key,
  });

  final double progress;
  final String label;
  final String semanticLabel;
  final bool completed;
  final VoidCallback? onTap;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathing;

  @override
  void initState() {
    super.initState();
    _breathing = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
      lowerBound: 0.99,
      upperBound: 1.01,
    );
    if (widget.completed) _breathing.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.completed && !oldWidget.completed) {
      _breathing.repeat(reverse: true);
    } else if (!widget.completed && oldWidget.completed) {
      _breathing
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _breathing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      label: widget.semanticLabel,
      child: ScaleTransition(
        scale: _breathing,
        child: SizedBox.square(
          dimension: 224,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onTap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.square(
                    dimension: 204,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: widget.progress),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, value, _) => CircularProgressIndicator(
                        value: value.clamp(0, 1),
                        strokeWidth: 9,
                        color: color,
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .outlineVariant,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(34),
                    child: Text(
                      widget.label,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
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
