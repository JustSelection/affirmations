import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract final class CompletionFeedback {
  static Future<void> selection() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (error) {
      debugPrint('Selection haptic failed: $error');
    }
  }

  static Future<void> play() async {
    try {
      await HapticFeedback.mediumImpact();
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await HapticFeedback.mediumImpact();
    } catch (error) {
      debugPrint('Completion haptic failed: $error');
    }
  }
}
