// lib/models/item.dart

import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

// Kategorie des Gegenstands
enum ItemCategory {
  weapon,    // Waffe
  armor,     // Rüstung
  shield,    // Schild
  tool,      // Werkzeug
  consumable, // Verbrauchsgegenstand (Tränke, Schriftrollen)
  treasure,  // Schatz (Edelsteine, Kunstgegenstände)
  misc,      // Sonstiges
}

extension ItemCategoryExtension on ItemCategory {
  String get label {
    switch (this) {
      case ItemCategory.weapon:     return 'Waffen';
      case ItemCategory.armor:      return 'Rüstung';
      case ItemCategory.shield:     return 'Schilde';
      case ItemCategory.tool:       return 'Werkzeug';
      case ItemCategory.consumable: return 'Verbrauchsgegenstände';
      case ItemCategory.treasure:   return 'Schätze';
      case ItemCategory.misc:       return 'Sonstiges';
    }
  }

  IconData get icon {
    switch (this) {
      case ItemCategory.weapon:     return Icons.sports_martial_arts;
      case ItemCategory.armor:      return Icons.security;
      case ItemCategory.shield:     return Icons.shield;
      case ItemCategory.tool:       return Icons.handyman;
      case ItemCategory.consumable: return Icons.local_pharmacy;
      case ItemCategory.treasure:   return Icons.diamond;
      case ItemCategory.misc:       return Icons.category;
    }
  }
}

// Seltenheit des Gegenstands (D&D 5e Standard)
enum ItemRarity {
  common,    // Gewöhnlich
  uncommon,  // Ungewöhnlich
  rare,      // Selten
  veryRare,  // Sehr selten
  legendary, // Legendär
  artifact,  // Artefakt
}

extension ItemRarityExtension on ItemRarity {
  String get label {
    switch (this) {
      case ItemRarity.common:    return 'Gewöhnlich';
      case ItemRarity.uncommon:  return 'Ungewöhnlich';
      case ItemRarity.rare:      return 'Selten';
      case ItemRarity.veryRare:  return 'Sehr selten';
      case ItemRarity.legendary: return 'Legendär';
      case ItemRarity.artifact:  return 'Artefakt';
    }
  }

  Color get color {
    switch (this) {
      case ItemRarity.common:    return Colors.grey;
      case ItemRarity.uncommon:  return Colors.green;
      case ItemRarity.rare:      return Colors.blue;
      case ItemRarity.veryRare:  return Colors.purple;
      case ItemRarity.legendary: return Colors.orange;
      case ItemRarity.artifact:  return Colors.red;
    }
  }
}

class Item {
  final String id;
  String name;
  String description;
  bool isCustom;
  String creatorId;

  // ── Kategorie & Seltenheit ────────────────────────────────────────────────
  ItemCategory category;
  ItemRarity rarity;
  bool requiresAttunement; // Erfordert Einstimmung?

  // ── Gewicht & Menge ───────────────────────────────────────────────────────
  double _weight = 0.0; // Gewicht in Pfund (D&D 5e Standard)
  int _quantity = 1;

  // ── Waffeneigenschaften (nur relevant wenn category == weapon) ────────────
  String? damageDice;   // z.B. '1d8'
  String? damageType;   // z.B. 'Hieb', 'Stich', 'Wucht'
  bool isMagical;       // Magischer Gegenstand?
  int _magicBonus = 0;  // +1, +2, +3 Bonus auf Angriff und Schaden

  // ── Rüstungseigenschaften (nur relevant wenn category == armor) ───────────
  int _armorClassBonus = 0; // Bonus auf Rüstungsklasse

  // ── Wert ──────────────────────────────────────────────────────────────────
  int _valueInCopper = 0; // Wert in Kupferstücken (kleinste Einheit in D&D)

  Item({
    String? id,
    required this.name,
    this.description = '',
    this.isCustom = false,
    this.creatorId = '',
    this.category = ItemCategory.misc,
    this.rarity = ItemRarity.common,
    this.requiresAttunement = false,
    double weight = 0.0,
    int quantity = 1,
    this.damageDice,
    this.damageType,
    this.isMagical = false,
    int magicBonus = 0,
    int armorClassBonus = 0,
    int valueInCopper = 0,
  }) : id = id ?? const Uuid().v4() {
    _weight = weight.clamp(0.0, 9999.0);
    _quantity = quantity.clamp(0, 9999);
    _magicBonus = magicBonus.clamp(0, 3);
    _armorClassBonus = armorClassBonus.clamp(0, 99);
    _valueInCopper = valueInCopper.clamp(0, 99999999);
  }

  // ── Getter & Setter ───────────────────────────────────────────────────────

  double get weight => _weight;
  set weight(double value) => _weight = value.clamp(0.0, 9999.0);

  int get quantity => _quantity;
  set quantity(int value) => _quantity = value.clamp(0, 9999);

  // Magischer Bonus: 0 bis +3 (D&D 5e Maximum)
  int get magicBonus => _magicBonus;
  set magicBonus(int value) => _magicBonus = value.clamp(0, 3);

  int get armorClassBonus => _armorClassBonus;
  set armorClassBonus(int value) => _armorClassBonus = value.clamp(0, 99);

  int get valueInCopper => _valueInCopper;
  set valueInCopper(int value) => _valueInCopper = value.clamp(0, 99999999);

  // ── Berechnete Getter ─────────────────────────────────────────────────────

  // Gesamtgewicht = Gewicht × Menge
  double get totalWeight => _weight * _quantity;

  // Wert in lesbarer Form umrechnen
  // D&D Umrechnungskurs: 1 PP = 10 GP = 100 SP = 1000 CP
  String get valueDisplay {
    if (_valueInCopper == 0) return 'Wertlos';
    int remaining = _valueInCopper;

    final pp = remaining ~/ 1000; remaining %= 1000;
    final gp = remaining ~/ 100;  remaining %= 100;
    final sp = remaining ~/ 10;   remaining %= 10;
    final cp = remaining;

    final parts = <String>[];
    if (pp > 0) parts.add('$pp PP');
    if (gp > 0) parts.add('$gp GP');
    if (sp > 0) parts.add('$sp SP');
    if (cp > 0) parts.add('$cp KP');
    return parts.join(', ');
  }

  // ── Datenbank: Konvertierung ──────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id':                 id,
      'name':               name,
      'description':        description,
      'isCustom':           isCustom ? 1 : 0,
      'creatorId':          creatorId,
      'category':           category.name,
      'rarity':             rarity.name,
      'requiresAttunement': requiresAttunement ? 1 : 0,
      'weight':             weight,
      'quantity':           quantity,
      'damageDice':         damageDice,
      'damageType':         damageType,
      'isMagical':          isMagical ? 1 : 0,
      'magicBonus':         magicBonus,
      'armorClassBonus':    armorClassBonus,
      'valueInCopper':      valueInCopper,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id:                 map['id'],
      name:               map['name'],
      description:        map['description'] ?? '',
      isCustom:           map['isCustom'] == 1,
      creatorId:          map['creatorId'] ?? '',
      category:           ItemCategory.values.byName(
                            map['category'] ?? 'misc'),
      rarity:             ItemRarity.values.byName(
                            map['rarity'] ?? 'common'),
      requiresAttunement: map['requiresAttunement'] == 1,
      weight:             (map['weight'] ?? 0.0).toDouble(),
      quantity:           map['quantity'] ?? 1,
      damageDice:         map['damageDice'],
      damageType:         map['damageType'],
      isMagical:          map['isMagical'] == 1,
      magicBonus:         map['magicBonus'] ?? 0,
      armorClassBonus:    map['armorClassBonus'] ?? 0,
      valueInCopper:      map['valueInCopper'] ?? 0,
    );
  }
}