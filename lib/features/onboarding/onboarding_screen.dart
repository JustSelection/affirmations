import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/dependency.dart';
import '../../state/app_controller.dart';
import 'dependency_option_card.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final Set<Dependency> _selected;
  late bool _choosingGoal;
  Dependency? _goalChoice;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.controller.state.selectedGoals};
    _choosingGoal = _selected.isNotEmpty;
  }

  Future<void> _toggle(Dependency goal) async {
    setState(() {
      if (!_selected.add(goal)) {
        _selected.remove(goal);
      }
      _error = null;
    });
    try {
      await HapticFeedback.selectionClick();
    } catch (error) {
      debugPrint('Selection haptic failed: $error');
    }
  }

  Future<void> _selectGoal(Dependency goal) async {
    setState(() {
      _goalChoice = goal;
      _error = null;
    });
    try {
      await HapticFeedback.selectionClick();
    } catch (error) {
      debugPrint('Selection haptic failed: $error');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Не удалось сохранить выбор: $error');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continue() => _run(() async {
    await widget.controller.selectGoals(_selected);
    if (mounted) setState(() => _choosingGoal = true);
  });

  Future<void> _choose(Dependency goal) => _selectGoal(goal);

  Future<void> _start() {
    final goal = _goalChoice;
    if (goal == null) return Future<void>.value();
    return _run(() => widget.controller.chooseGoal(goal));
  }

  bool _isSelected(Dependency goal) =>
      _choosingGoal ? _goalChoice == goal : _selected.contains(goal);

  @override
  Widget build(BuildContext context) {
    final goals = _choosingGoal
        ? Dependency.values.where(_selected.contains).toList()
        : Dependency.values;
    return Scaffold(
      appBar: AppBar(
        leading: _choosingGoal
            ? IconButton(
                tooltip: 'Назад к выбору',
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _choosingGoal = false;
                        _error = null;
                      }),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Text(
                    _choosingGoal
                        ? 'Выберите одну цель, с которой начнёте'
                        : 'Отметьте, что присутствует в вашей жизни',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final goal in goals)
                          DependencyOptionCard(
                            goal: goal,
                            selected: _isSelected(goal),
                            showSafetyNote:
                                goal.safetyNote != null && _isSelected(goal),
                            onTap: _busy
                                ? null
                                : _choosingGoal
                                ? () => _choose(goal)
                                : () => _toggle(goal),
                          ),
                      ],
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(_error!, textAlign: TextAlign.center),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy
                          ? null
                          : _choosingGoal
                          ? _goalChoice == null
                                ? null
                                : _start
                          : _selected.isEmpty
                          ? null
                          : _continue,
                      child: _busy
                          ? const CircularProgressIndicator()
                          : Text(_choosingGoal ? 'Начать' : 'Далее'),
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
