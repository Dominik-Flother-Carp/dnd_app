// lib/models/item.dart

import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum ItemCategory {
  weapon,
  armor,
  shield,
  tool,
  consumable,
  gear,
  treasure,
  misc,
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
      case ItemCategory.gear:       return 'Ausrüstung';
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
      case ItemCategory.gear:       return Icons.backpack_outlined;
      case ItemCategory.misc:       return Icons.category;
    }
  }
}

enum ItemRarity {
  common,
  uncommon,
  rare,
  veryRare,
  legendary,
  artifact,
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

// Waffeneigenschaften nach D&D 5e
enum WeaponProperty {
  finesse,      // Finesse – darf STR oder GES verwenden
  versatile,    // Vielseitig – kann zwei- oder einhändig geführt werden
  thrown,       // Wurfwaffe
  ranged,       // Fernkampfwaffe
  twoHanded,    // Zweihändig
  light,        // Leicht – für Zwei-Waffen-Kampf
  heavy,        // Schwer – kleine Wesen haben Nachteil
  reach,        // Reichweite – +1,5 m Reichweite
  loading,      // Nachladen – nur 1 Angriff pro Aktion
  ammunition,   // Munition benötigt
}

extension WeaponPropertyExtension on WeaponProperty {
  String get label {
    switch (this) {
      case WeaponProperty.finesse:    return 'Finesse';
      case WeaponProperty.versatile:  return 'Vielseitig';
      case WeaponProperty.thrown:     return 'Wurfwaffe';
      case WeaponProperty.ranged:     return 'Fernkampf';
      case WeaponProperty.twoHanded:  return 'Zweihändig';
      case WeaponProperty.light:      return 'Leicht';
      case WeaponProperty.heavy:      return 'Schwer';
      case WeaponProperty.reach:      return 'Reichweite';
      case WeaponProperty.loading:    return 'Nachladen';
      case WeaponProperty.ammunition: return 'Munition';
    }
  }
}

enum WeaponCategory {
  simple,  // Einfache Waffe
  martial, // Kriegswaffe
}

extension WeaponCategoryExtension on WeaponCategory {
  String get label {
    switch (this) {
      case WeaponCategory.simple:  return 'Einfache Waffe';
      case WeaponCategory.martial: return 'Kriegswaffe';
    }
  }
}

enum ArmorType {
  light,  // Leichte Rüstung  – max GES unbegrenzt
  medium, // Mittlere Rüstung – max GES +2
  heavy,  // Schwere Rüstung  – kein GES-Bonus
}

extension ArmorTypeExtension on ArmorType {
  String get label {
    switch (this) {
      case ArmorType.light:  return 'Leichte Rüstung';
      case ArmorType.medium: return 'Mittlere Rüstung';
      case ArmorType.heavy:  return 'Schwere Rüstung';
    }
  }

  // Standardmäßiger max GES-Bonus laut 5e-Regeln.
  // -1 = unbegrenzt, 0 = kein Bonus, 2 = max +2
  int get defaultMaxDexBonus {
    switch (this) {
      case ArmorType.light:  return -1;
      case ArmorType.medium: return 2;
      case ArmorType.heavy:  return 0;
    }
  }
}

// ── Basisklasse ───────────────────────────────────────────────────────────────

class Item {
  final String id;
  String name;
  String description;

  ItemCategory category;
  ItemRarity rarity;
  bool requiresAttunement;
  bool isMagical;

  double _weight = 0.0;
  int _valueInCopper = 0;
  int _magicBonus    = 0;

  Item({
    String? id,
    required this.name,
    this.description       = '',
    this.category          = ItemCategory.misc,
    this.rarity            = ItemRarity.common,
    this.requiresAttunement = false,
    this.isMagical         = false,
    double weight          = 0.0,
    int valueInCopper      = 0,
    int magicBonus         = 0,
  }) : id = id ?? const Uuid().v4() {
    _weight        = weight.clamp(0.0, 9999.0);
    _valueInCopper = valueInCopper.clamp(0, 99999999);
    _magicBonus    = magicBonus.clamp(0, 3);
  }

  // ── Getter & Setter ───────────────────────────────────────────────────────

  double get weight => _weight;
  set weight(double v) => _weight = v.clamp(0.0, 9999.0);

  int get valueInCopper => _valueInCopper;
  set valueInCopper(int v) => _valueInCopper = v.clamp(0, 99999999);

  int get magicBonus => _magicBonus;
  set magicBonus(int v) => _magicBonus = v.clamp(0, 3);

  // Gewicht pro Einheit – Gesamtgewicht wird von CharacterItem berechnet
  double get weightPerUnit => _weight;

  String get valueDisplay {
    if (_valueInCopper == 0) return 'Wertlos';
    final gm = _valueInCopper / 100.0;
    if (gm == gm.truncateToDouble()) {
      return '${gm.toInt()} GM';
    }
    return '${gm.toStringAsFixed(2)} GM';
  }

  // ── Datenbank ─────────────────────────────────────────────────────────────
  //
  // itemType ist die Diskriminante für fromMap – damit weiß die DB beim Laden
  // welche Unterklasse zu instanziieren ist.

  Map<String, dynamic> toMap() {
    return {
      'id':                 id,
      'itemType':           'base',
      'name':               name,
      'description':        description,
      'category':           category.name,
      'rarity':             rarity.name,
      'requiresAttunement': requiresAttunement ? 1 : 0,
      'isMagical':          isMagical ? 1 : 0,
      'weight':             weight,
      'valueInCopper':      valueInCopper,
      'magicBonus':         magicBonus,
      // Unterklassen-Felder – in der Basisklasse leer
      'damageDice':         null,
      'damageType':         null,
      'weaponProperties':   null,
      'rangeNormal':        null,
      'rangeMax':           null,
      'versatileDice':      null,
      'armorClassBonus':    null,
      'minStrength':        null,
      'maxDexBonusOverride': null,
      'stealthDisadvantage': null,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    final type = map['itemType'] ?? 'base';
    switch (type) {
      case 'weapon': return WeaponItem.fromMap(map);
      case 'armor':  return ArmorItem.fromMap(map);
      case 'shield': return ShieldItem.fromMap(map);
      default:       return _baseFromMap(map);
    }
  }

  static Item _baseFromMap(Map<String, dynamic> map) {
    return Item(
      id:                 map['id'],
      name:               map['name'],
      description:        map['description'] ?? '',
      category:           ItemCategory.values.byName(map['category'] ?? 'misc'),
      rarity:             ItemRarity.values.byName(map['rarity'] ?? 'common'),
      requiresAttunement: map['requiresAttunement'] == 1,
      isMagical:          map['isMagical'] == 1,
      weight:             (map['weight'] ?? 0.0).toDouble(),
      valueInCopper:      map['valueInCopper'] ?? 0,
      magicBonus:         map['magicBonus'] ?? 0,
    );
  }
}

// ── WeaponItem ────────────────────────────────────────────────────────────────

class WeaponItem extends Item {
  WeaponCategory weaponCategory;
  String damageDice;           // z.B. '1d8'
  String damageType;           // z.B. 'Hieb', 'Stich', 'Wucht'
  List<WeaponProperty> properties;
  int rangeNormal;             // Reichweite in Metern (Nahkampf: 1 oder 2)
  int rangeMax;                // Maximale Reichweite (nur Fernkampf/Wurfwaffe)
  String? versatileDice;       // Würfel für zweihändige Nutzung, z.B. '1d10'

  WeaponItem({
    super.id,
    required super.name,
    super.description,
    super.rarity,
    super.requiresAttunement,
    super.isMagical,
    super.weight,
    super.valueInCopper,
    super.magicBonus,
    this.weaponCategory  = WeaponCategory.simple,
    required this.damageDice,
    required this.damageType,
    this.properties  = const [],
    this.rangeNormal = 1,
    this.rangeMax    = 1,
    this.versatileDice,
  }) : super(category: ItemCategory.weapon);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'itemType':         'weapon',
      'weaponCategory':   weaponCategory.name,
      'damageDice':       damageDice,
      'damageType':       damageType,
      'weaponProperties': properties.map((p) => p.name).join(','),
      'rangeNormal':      rangeNormal,
      'rangeMax':         rangeMax,
      'versatileDice':    versatileDice,
    };
  }

  factory WeaponItem.fromMap(Map<String, dynamic> map) {
    final rawProps = map['weaponProperties'] as String?;
    final props = rawProps == null || rawProps.isEmpty
        ? <WeaponProperty>[]
        : rawProps
            .split(',')
            .map((s) => WeaponProperty.values.byName(s))
            .toList();

    return WeaponItem(
      id:              map['id'],
      name:            map['name'],
      description:     map['description'] ?? '',
      rarity:          ItemRarity.values.byName(map['rarity'] ?? 'common'),
      requiresAttunement: map['requiresAttunement'] == 1,
      isMagical:       map['isMagical'] == 1,
      weight:          (map['weight'] ?? 0.0).toDouble(),
      valueInCopper:   map['valueInCopper'] ?? 0,
      magicBonus:      map['magicBonus'] ?? 0,
      weaponCategory:  WeaponCategory.values.byName(map['weaponCategory'] ?? 'simple'),
      damageDice:      map['damageDice'] ?? '1d4',
      damageType:      map['damageType'] ?? 'Hieb',
      properties:      props,
      rangeNormal:     map['rangeNormal'] ?? 1,
      rangeMax:        map['rangeMax'] ?? 1,
      versatileDice:   map['versatileDice'],
    );
  }
}

// ── ArmorItem ─────────────────────────────────────────────────────────────────

class ArmorItem extends Item {
  int _armorClassBonus;
  ArmorType armorType;
  int minStrength;         // Mindest-STR um die Rüstung zu tragen (0 = keine)
  int? maxDexBonusOverride; // null = vom armorType ableiten, sonst manueller Wert
  bool stealthDisadvantage;

  ArmorItem({
    super.id,
    required super.name,
    super.description,
    super.rarity,
    super.requiresAttunement,
    super.isMagical,
    super.weight,
    super.valueInCopper,
    super.magicBonus,
    int armorClassBonus      = 0,
    this.armorType           = ArmorType.medium,
    this.minStrength         = 0,
    this.maxDexBonusOverride,
    this.stealthDisadvantage = false,
  })  : _armorClassBonus = armorClassBonus.clamp(0, 30),
        super(category: ItemCategory.armor);

  int get armorClassBonus => _armorClassBonus;
  set armorClassBonus(int v) => _armorClassBonus = v.clamp(0, 30);

  // Max GES-Bonus: entweder manuell überschrieben oder vom Rüstungstyp abgeleitet
  int get maxDexBonus => maxDexBonusOverride ?? armorType.defaultMaxDexBonus;

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'itemType':           'armor',
      'armorClassBonus':    armorClassBonus,
      'armorType':          armorType.name,
      'minStrength':        minStrength,
      'maxDexBonusOverride': maxDexBonusOverride,
      'stealthDisadvantage': stealthDisadvantage ? 1 : 0,
    };
  }

  factory ArmorItem.fromMap(Map<String, dynamic> map) {
    return ArmorItem(
      id:               map['id'],
      name:             map['name'],
      description:      map['description'] ?? '',
      rarity:           ItemRarity.values.byName(map['rarity'] ?? 'common'),
      requiresAttunement: map['requiresAttunement'] == 1,
      isMagical:        map['isMagical'] == 1,
      weight:           (map['weight'] ?? 0.0).toDouble(),
      valueInCopper:    map['valueInCopper'] ?? 0,
      magicBonus:       map['magicBonus'] ?? 0,
      armorClassBonus:     map['armorClassBonus'] ?? 0,
      armorType:           ArmorType.values.byName(map['armorType'] ?? 'medium'),
      minStrength:         map['minStrength'] ?? 0,
      maxDexBonusOverride: map['maxDexBonusOverride'] as int?,
      stealthDisadvantage: map['stealthDisadvantage'] == 1 || map['stealthDisadvantage'] == true,
    );
  }
}

// ── ShieldItem ────────────────────────────────────────────────────────────────

class ShieldItem extends Item {
  int _armorClassBonus;

  ShieldItem({
    super.id,
    required super.name,
    super.description,
    super.rarity,
    super.requiresAttunement,
    super.isMagical,
    super.weight,
    super.valueInCopper,
    super.magicBonus,
    int armorClassBonus = 2, // Schilde geben standardmäßig +2 RK
  })  : _armorClassBonus = armorClassBonus.clamp(0, 10),
        super(category: ItemCategory.shield);

  int get armorClassBonus => _armorClassBonus;
  set armorClassBonus(int v) => _armorClassBonus = v.clamp(0, 10);

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'itemType':        'shield',
      'armorClassBonus': armorClassBonus,
    };
  }

  factory ShieldItem.fromMap(Map<String, dynamic> map) {
    return ShieldItem(
      id:               map['id'],
      name:             map['name'],
      description:      map['description'] ?? '',
      rarity:           ItemRarity.values.byName(map['rarity'] ?? 'common'),
      requiresAttunement: map['requiresAttunement'] == 1,
      isMagical:        map['isMagical'] == 1,
      weight:           (map['weight'] ?? 0.0).toDouble(),
      valueInCopper:    map['valueInCopper'] ?? 0,
      magicBonus:       map['magicBonus'] ?? 0,
      armorClassBonus:  map['armorClassBonus'] ?? 2,
    );
  }
}