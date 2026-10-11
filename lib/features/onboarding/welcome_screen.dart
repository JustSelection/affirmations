import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({required this.onStart, super.key});

  final Future<void> Function() onStart;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _breathing;
  late final AnimationController _fade;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _breathing = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
      lowerBound: 0.99,
      upperBound: 1.01,
    )..repeat(reverse: true);
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _breathing.dispose();
    _fade.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      unawaited(_playHaptic());
      await widget.onStart();
    } catch (error) {
      if (mounted) setState(() => _error = 'Не удалось начать: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _playHaptic() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (error) {
      debugPrint('Welcome haptic failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              FadeTransition(
                opacity: CurvedAnimation(parent: _fade, curve: Curves.easeIn),
                child: ScaleTransition(
                  scale: _breathing,
                  child: Text(
                    'Affirmations',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _start,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Начать'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
