// lib/models/character_item.dart

import 'package:dnd_app/models/item.dart';

class CharacterItem {
  final String characterId;
  final Item item;
  int _quantity;
  bool isEquipped;
  bool isAttuned;
  String notes;

  CharacterItem({
    required this.characterId,
    required this.item,
    int quantity = 1,
    this.isEquipped = false,
    this.isAttuned = false,
    this.notes = '',
  }) : _quantity = quantity.clamp(0, 9999);

  int get quantity => _quantity;
  set quantity(int value) => _quantity = value.clamp(0, 9999);

  bool get isUsable => !item.requiresAttunement || isAttuned;
  double get totalWeight => item.weight * _quantity;

  Map<String, dynamic> toMap() => {
    'characterId': characterId,
    'itemId':      item.id,
    'quantity':    quantity,
    'isEquipped':  isEquipped ? 1 : 0,
    'isAttuned':   isAttuned ? 1 : 0,
    'notes':       notes,
  };

  factory CharacterItem.fromMap(Map<String, dynamic> map, Item item) {
    return CharacterItem(
      characterId: map['characterId'],
      item:        item,
      quantity:    map['quantity'] ?? 1,
      isEquipped:  map['isEquipped'] == 1,
      isAttuned:   map['isAttuned'] == 1,
      notes:       map['notes'] ?? '',
    );
  }
}