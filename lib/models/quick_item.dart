// lib/models/quick_item.dart

import 'package:uuid/uuid.dart';
import 'package:dnd_app/models/item.dart';

// Ein Schnellitem ist ein einfacher Inventareintrag ohne Kompendium-Bezug.
// Gedacht für Beute, Questgegenstände, Verbrauchsmaterial – alles was
// keine spielmechanische Bedeutung hat (kein Schaden, kein RK-Bonus).
//
// Im Inventar-Tab wird es genauso dargestellt wie ein normales Item,
// landet aber immer in der Kategorie "Sonstiges".

class QuickItem {
  final String id;
  final String characterId;

  String name;
  String notes;

  int _quantity = 1;
  double _weight = 0.0;
  int _valueInCopper = 0;

  QuickItem({
    String? id,
    required this.characterId,
    required this.name,
    this.category      = ItemCategory.misc,
    this.notes         = '',
    int quantity       = 1,
    double weight      = 0.0,
    int valueInCopper  = 0,
  }) : id = id ?? const Uuid().v4() {
    _quantity      = quantity.clamp(1, 9999);
    _weight        = weight.clamp(0.0, 9999.0);
    _valueInCopper = valueInCopper.clamp(0, 99999999);
  }

  // ── Getter & Setter ───────────────────────────────────────────────────────

  int get quantity => _quantity;
  set quantity(int v) => _quantity = v.clamp(1, 9999);

  double get weight => _weight;
  set weight(double v) => _weight = v.clamp(0.0, 9999.0);

  int get valueInCopper => _valueInCopper;
  set valueInCopper(int v) => _valueInCopper = v.clamp(0, 99999999);

  double get totalWeight => _weight * _quantity;

  // Nur treasure oder misc erlaubt – Schnellitems haben keine
  // spielmechanische Bedeutung und erscheinen nicht im Kompendium.
  ItemCategory category;

  String get valueDisplay {
    if (_valueInCopper == 0) return 'Wertlos';
    int r = _valueInCopper;
    final pp = r ~/ 1000; r %= 1000;
    final gp = r ~/ 100;  r %= 100;
    final sp = r ~/ 10;   r %= 10;
    final cp = r;
    final parts = <String>[];
    if (pp > 0) parts.add('$pp PM');
    if (gp > 0) parts.add('$gp GM');
    if (sp > 0) parts.add('$sp SM');
    if (cp > 0) parts.add('$cp KM');
    return parts.join(', ');
  }

  // ── Datenbank ─────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id':           id,
      'characterId':  characterId,
      'name':         name,
      'category':     category.name,
      'notes':        notes,
      'quantity':     quantity,
      'weight':       weight,
      'valueInCopper': valueInCopper,
    };
  }

  factory QuickItem.fromMap(Map<String, dynamic> map) {
    return QuickItem(
      id:            map['id'],
      characterId:   map['characterId'],
      name:          map['name'],
      category:      ItemCategory.values.byName(map['category'] ?? 'misc'),
      notes:         map['notes'] ?? '',
      quantity:      map['quantity'] ?? 1,
      weight:        (map['weight'] ?? 0.0).toDouble(),
      valueInCopper: map['valueInCopper'] ?? 0,
    );
  }
}