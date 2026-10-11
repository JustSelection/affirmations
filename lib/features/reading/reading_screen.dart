import 'dart:async';

import 'package:flutter/material.dart';

import '../../content/affirmations.dart';
import '../../state/app_controller.dart';
import 'reading_completion_panel.dart';
import 'reading_session_driver.dart';
import 'reading_stage.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  late final ReadingSessionDriver _driver;
  bool _allowPop = false;
  bool _closeScheduled = false;

  @override
  void initState() {
    super.initState();
    _driver = ReadingSessionDriver(widget.controller)
      ..addListener(_onDriverChanged)
      ..start();
  }

  @override
  void dispose() {
    _driver
      ..removeListener(_onDriverChanged)
      ..dispose();
    super.dispose();
  }

  void _onDriverChanged() {
    if (!mounted) return;
    setState(() {});
    if (_driver.isCompleted && !_closeScheduled) {
      _closeScheduled = true;
      unawaited(_closeAfterDelay());
    }
  }

  Future<void> _closeAfterDelay() async {
    await Future<void>.delayed(const Duration(milliseconds: 2500));
    await _closeRoute();
  }

  Future<void> _closeRoute() async {
    if (!mounted) return;
    setState(() => _allowPop = true);
    await Future<void>.delayed(Duration.zero);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _leave() async {
    if (_allowPop || _driver.isCompleted) return;
    if (!await _driver.pause() || !mounted) return;
    await _closeRoute();
  }

  Future<void> _pauseFromButton() async {
    await _driver.pause();
  }

  @override
  Widget build(BuildContext context) {
    final activeGoal = widget.controller.state.activeGoal;
    final progress = activeGoal == null
        ? null
        : widget.controller.state.progressFor(activeGoal);
    final items = activeGoal == null
        ? const <String>[]
        : Affirmations.forGoal(activeGoal);
    final index = progress?.session?.affirmationIndex ?? 0;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Назад',
            onPressed: _leave,
            icon: const Icon(Icons.arrow_back),
          ),
          title: const Text('Чтение'),
        ),
        body: SafeArea(
          child: _driver.isCompleted
              ? ReadingCompletionPanel(day: _driver.day, target: _driver.target)
              : ReadingStage(
                  remainingSeconds: _driver.remainingSeconds,
                  affirmation: items.isEmpty
                      ? 'Аффирмации пока недоступны.'
                      : items[index % items.length],
                  paused: _driver.isPaused,
                  onAdvance: _driver.advance,
                  onPause: _pauseFromButton,
                  onResume: _driver.resume,
                  error: _driver.error,
                  onRetry: _driver.remainingSeconds == 0
                      ? _driver.retryCompletion
                      : null,
                ),
        ),
      ),
    );
  }
}
