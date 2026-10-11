enum Dependency {
  alcohol(
    'alcohol',
    'Алкоголь',
    '🍷',
    'Резкая отмена алкоголя при физической зависимости может быть опасна. '
        'План изменений обсудите с врачом. При судорогах, спутанности сознания '
        'или тяжёлом недомогании немедленно обратитесь в местную экстренную службу.',
  ),
  nicotine('nicotine', 'Никотин', '🚬'),
  pornography('pornography', 'Порно', '👁️'),
  digital('digital', 'Цифровая зависимость', '📱');

  const Dependency(this.id, this.title, this.symbol, [this.safetyNote]);

  final String id;
  final String title;
  final String symbol;
  final String? safetyNote;

  static Dependency? fromId(Object? value) {
    for (final dependency in values) {
      if (dependency.id == value) return dependency;
    }
    return null;
  }
}
