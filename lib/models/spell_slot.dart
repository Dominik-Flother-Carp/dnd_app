// lib/models/spell_slot.dart

class SpellSlot {
  final int max;
  int current;

  SpellSlot({required this.max, required this.current});

  SpellSlot copyWith({int? max, int? current}) => SpellSlot(
        max: max ?? this.max,
        current: (current ?? this.current).clamp(0, max ?? this.max),
      );

  Map<String, dynamic> toMap() => {'max': max, 'current': current};

  factory SpellSlot.fromMap(Map<String, dynamic> map) => SpellSlot(
        max: map['max'] ?? 0,
        current: map['current'] ?? 0,
      );
}