import 'package:affirmations/content/affirmations.dart';
import 'package:affirmations/domain/dependency.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every goal has a non-empty, cycleable affirmation list', () {
    for (final goal in Dependency.values) {
      final items = Affirmations.forGoal(goal);

      expect(items, isNotEmpty, reason: goal.id);
      expect(items.every((item) => item.trim().isNotEmpty), isTrue);
      expect(items.toSet(), hasLength(items.length));
    }
  });
}
