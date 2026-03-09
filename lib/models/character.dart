// lib/models/character.dart

import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:dnd_app/models/skills.dart';
import 'spell_slot.dart';

class Character {
  final String id;

  // ── Einfache Felder ohne Validierung ──────────────────────────────────────
  //
  String name;
  String race;
  String characterClass;
  String subclass;
  String background;
  String alignment;
  String notes;
  String personalityTraits;
  String ideals;
  String bonds;
  String flaws;
  int hitDie;
  bool useEdition2024;
  Map<int, SpellSlot> spellSlots;

  // ── Private Felder mit Validierung ────────────────────────────────────────
  // Der Unterstrich macht sie privat – Zugriff nur über Getter/Setter
  int _level = 1;
  int _experiencePoints = 0;

  int _strength = 10;
  int _dexterity = 10;
  int _constitution = 10;
  int _intelligence = 10;
  int _wisdom = 10;
  int _charisma = 10;

  int _maxHitPoints = 8;
  int _currentHitPoints = 8;
  int _temporaryHitPoints = 0;
  int _armorClass = 10;
  int _speed = 9;

  int _goldPieces = 0;
  int _silverPieces = 0;
  int _copperPieces = 0;
  int _electrumPieces = 0;
  int _platinumPieces = 0;

  int _deathSaveSuccesses = 0;
  int _deathSaveFailures = 0;

  bool isStabilized = false;

  int _usedHitDice = 0;

  // ── Fertigkeiten: true = geübt ─────────────────────────────────────────────
  Map<String, bool> skillProficiencies;
  Map<String, bool> skillExpertise;
  Map<String, bool> savingThrowProficiencies;

  // ── Konstruktor ────────────────────────────────────────────────────────────
  Character({
    String? id,
    required this.name,
    this.race = '',
    this.characterClass = '',
    this.subclass = '',
    this.background = '',
    this.alignment = '',
    this.notes = '',
    this.personalityTraits = '',
    this.ideals = '',
    this.bonds = '',
    this.flaws = '',
    this.hitDie = 8,
    this.useEdition2024 = false,
    int level = 1,
    int experiencePoints = 0,
    int strength = 10,
    int dexterity = 10,
    int constitution = 10,
    int intelligence = 10,
    int wisdom = 10,
    int charisma = 10,
    int maxHitPoints = 8,
    int currentHitPoints = 8,
    int temporaryHitPoints = 0,
    int armorClass = 10,
    int speed = 9,
    int goldPieces = 0,
    int silverPieces = 0,
    int copperPieces = 0,
    int electrumPieces = 0,
    int platinumPieces = 0,
    int usedHitDice = 0,
    int deathSaveSuccesses = 0,
    int deathSaveFailures = 0,
    bool isStabilized = false,
    Map<int, SpellSlot>? spellSlots,
    Map<String, bool>? skillProficiencies,
    Map<String, bool>? skillExpertise,
    Map<String, bool>? savingThrowProficiencies,
  }) : id = id ?? const Uuid().v4(),
       skillProficiencies = skillProficiencies ?? _defaultSkillMap(),
       skillExpertise = skillExpertise ?? _defaultSkillMap(),
       savingThrowProficiencies =
           savingThrowProficiencies ?? _defaultSavingThrowMap(),
       spellSlots = spellSlots ?? {} {
    // Setter werden hier aufgerufen damit die Validierung greift –
    // auch beim ersten Erstellen eines Charakters
    _level = level.clamp(1, 20);
    _experiencePoints = experiencePoints.clamp(0, 355000);
    _strength = strength.clamp(1, 30);
    _dexterity = dexterity.clamp(1, 30);
    _constitution = constitution.clamp(1, 30);
    _intelligence = intelligence.clamp(1, 30);
    _wisdom = wisdom.clamp(1, 30);
    _charisma = charisma.clamp(1, 30);
    _maxHitPoints = maxHitPoints.clamp(1, 9999);
    _currentHitPoints = currentHitPoints.clamp(0, _maxHitPoints);
    _temporaryHitPoints = temporaryHitPoints.clamp(0, 9999);
    _armorClass = armorClass.clamp(1, 30);
    _speed = speed.clamp(0, 99);
    _goldPieces = goldPieces.clamp(0, 9999999);
    _silverPieces = silverPieces.clamp(0, 9999999);
    _copperPieces = copperPieces.clamp(0, 9999999);
    _electrumPieces = electrumPieces.clamp(0, 9999999);
    _platinumPieces = platinumPieces.clamp(0, 9999999);
    _deathSaveSuccesses = deathSaveSuccesses.clamp(0, 3);
    _deathSaveFailures = deathSaveFailures.clamp(0, 3);
    _usedHitDice = usedHitDice.clamp(0, _level);
  }

  // ── Getter & Setter mit Validierung ───────────────────────────────────────

  int get deathSaveSuccesses => _deathSaveSuccesses;
  set deathSaveSuccesses(int value) => _deathSaveSuccesses = value.clamp(0, 3);

  int get deathSaveFailures => _deathSaveFailures;
  set deathSaveFailures(int value) => _deathSaveFailures = value.clamp(0, 3);

  int get level => _level;
  set level(int value) => _level = value.clamp(1, 20);

  // Erfahrungspunkte: 355.000 XP ist das Maximum (Stufe 20 in D&D 5e)
  int get experiencePoints => _experiencePoints;
  set experiencePoints(int value) => _experiencePoints = value.clamp(0, 355000);

  // Attribute: Minimum 1, Maximum 30 (Göttliche Intervention etc.)
  int get strength => _strength;
  set strength(int value) => _strength = value.clamp(1, 30);

  int get dexterity => _dexterity;
  set dexterity(int value) => _dexterity = value.clamp(1, 30);

  int get constitution => _constitution;
  set constitution(int value) => _constitution = value.clamp(1, 30);

  int get intelligence => _intelligence;
  set intelligence(int value) => _intelligence = value.clamp(1, 30);

  int get wisdom => _wisdom;
  set wisdom(int value) => _wisdom = value.clamp(1, 30);

  int get charisma => _charisma;
  set charisma(int value) => _charisma = value.clamp(1, 30);

  // Maximale TP: mindestens 1
  int get maxHitPoints => _maxHitPoints;
  set maxHitPoints(int value) {
    _maxHitPoints = value.clamp(1, 9999);
    // Aktuelle TP dürfen das neue Maximum nicht überschreiten
    _currentHitPoints = _currentHitPoints.clamp(0, _maxHitPoints);
  }

  // Aktuelle TP: 0 (bewusstlos) bis maxHP
  int get currentHitPoints => _currentHitPoints;
  set currentHitPoints(int value) =>
      _currentHitPoints = value.clamp(0, _maxHitPoints);

  // Temporäre TP: nicht negativ, stapeln sich nicht mit sich selbst
  int get temporaryHitPoints => _temporaryHitPoints;
  set temporaryHitPoints(int value) =>
      _temporaryHitPoints = value.clamp(0, 9999);

  // Rüstungsklasse: Minimum 1, praktisches Maximum ~30
  int get armorClass => _armorClass;
  set armorClass(int value) => _armorClass = value.clamp(1, 30);

  // Bewegungsgeschwindigkeit: 0 ist möglich (gelähmt), Maximum 99m
  int get speed => _speed;
  set speed(int value) => _speed = value.clamp(0, 99);

  // Währung: nicht negativ (kein Schulden-System)
  int get goldPieces => _goldPieces;
  set goldPieces(int value) => _goldPieces = value.clamp(0, 9999999);

  int get silverPieces => _silverPieces;
  set silverPieces(int value) => _silverPieces = value.clamp(0, 9999999);

  int get copperPieces => _copperPieces;
  set copperPieces(int value) => _copperPieces = value.clamp(0, 9999999);

  int get electrumPieces => _electrumPieces;
  set electrumPieces(int value) => _electrumPieces = value.clamp(0, 9999999);

  int get platinumPieces => _platinumPieces;
  set platinumPieces(int value) => _platinumPieces = value.clamp(0, 9999999);

  int get usedHitDice => _usedHitDice;
  set usedHitDice(int value) => _usedHitDice = value.clamp(0, _level);

  // ── Automatische Berechnungen ─────────────────────────────────────────────

  /// Modifikator-Formel: (Attributwert - 10) / 2, abrunden
  static int modifier(int score) => ((score - 10) / 2).floor();

  int get strModifier => modifier(strength);
  int get dexModifier => modifier(dexterity);
  int get conModifier => modifier(constitution);
  int get intModifier => modifier(intelligence);
  int get wisModifier => modifier(wisdom);
  int get chaModifier => modifier(charisma);

  /// Übungsbonus nach Stufe
  int get proficiencyBonus {
    if (level <= 4) return 2;
    if (level <= 8) return 3;
    if (level <= 12) return 4;
    if (level <= 16) return 5;
    return 6;
  }

  int get initiative => dexModifier;
  int get passivePerception => 10 + skillBonus('perception');

  /// Bonus für eine Fertigkeit (inkl. Übung und Expertise)
  int skillBonus(String skillKey) {
    final base = _skillBaseModifier(skillKey);
    final isProficient = skillProficiencies[skillKey] ?? false;
    final hasExpertise = skillExpertise[skillKey] ?? false;
    if (hasExpertise) return base + proficiencyBonus * 2;
    if (isProficient) return base + proficiencyBonus;
    return base;
  }

  /// Rettungswurf-Bonus
  int savingThrowBonus(String attribute) {
    final base = _attributeModifier(attribute);
    final isProficient = savingThrowProficiencies[attribute] ?? false;
    return isProficient ? base + proficiencyBonus : base;
  }

  // ── Hilfsmethoden ──────────────────────────────────────────────────────────

  int _attributeModifier(String attribute) {
    switch (attribute) {
      case 'strength':
        return strModifier;
      case 'dexterity':
        return dexModifier;
      case 'constitution':
        return conModifier;
      case 'intelligence':
        return intModifier;
      case 'wisdom':
        return wisModifier;
      case 'charisma':
        return chaModifier;
      default:
        return 0;
    }
  }

  int _skillBaseModifier(String skillKey) =>
      _attributeModifier(Skills.attributekeys[skillKey] ?? '');

  static Map<String, bool> _defaultSkillMap() => {
    'acrobatics': false,
    'animalHandling': false,
    'arcana': false,
    'athletics': false,
    'deception': false,
    'history': false,
    'insight': false,
    'intimidation': false,
    'investigation': false,
    'medicine': false,
    'nature': false,
    'perception': false,
    'performance': false,
    'persuasion': false,
    'religion': false,
    'sleightOfHand': false,
    'stealth': false,
    'survival': false,
  };

  static Map<String, bool> _defaultSavingThrowMap() => {
    'strength': false,
    'dexterity': false,
    'constitution': false,
    'intelligence': false,
    'wisdom': false,
    'charisma': false,
  };

  // ── Datenbank: Konvertierung ───────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'race': race,
      'characterClass': characterClass,
      'subclass': subclass,
      'level': level,
      'background': background,
      'alignment': alignment,
      'experiencePoints': experiencePoints,
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
      'maxHitPoints': maxHitPoints,
      'currentHitPoints': currentHitPoints,
      'temporaryHitPoints': temporaryHitPoints,
      'hitDie': hitDie,
      'armorClass': armorClass,
      'speed': speed,
      'goldPieces': goldPieces,
      'silverPieces': silverPieces,
      'copperPieces': copperPieces,
      'electrumPieces': electrumPieces,
      'platinumPieces': platinumPieces,
      'notes': notes,
      'personalityTraits': personalityTraits,
      'ideals': ideals,
      'bonds': bonds,
      'flaws': flaws,
      'useEdition2024': useEdition2024 ? 1 : 0,
      'skillProficiencies': jsonEncode(skillProficiencies),
      'skillExpertise': jsonEncode(skillExpertise),
      'savingThrowProficiencies': jsonEncode(savingThrowProficiencies),
      'spellSlots': jsonEncode(
        spellSlots.map((k, v) => MapEntry(k.toString(), v.toMap())),
      ),
      'usedHitDice': usedHitDice,
      'deathSaveSuccesses': deathSaveSuccesses,
      'deathSaveFailures': deathSaveFailures,
      'isStabilized': isStabilized ? 1 : 0,
    };
  }

  factory Character.fromMap(Map<String, dynamic> map) {
    return Character(
      id: map['id'],
      name: map['name'],
      race: map['race'] ?? '',
      characterClass: map['characterClass'] ?? '',
      subclass: map['subclass'] ?? '',
      level: map['level'] ?? 1,
      background: map['background'] ?? '',
      alignment: map['alignment'] ?? '',
      experiencePoints: map['experiencePoints'] ?? 0,
      strength: map['strength'] ?? 10,
      dexterity: map['dexterity'] ?? 10,
      constitution: map['constitution'] ?? 10,
      intelligence: map['intelligence'] ?? 10,
      wisdom: map['wisdom'] ?? 10,
      charisma: map['charisma'] ?? 10,
      maxHitPoints: map['maxHitPoints'] ?? 8,
      currentHitPoints: map['currentHitPoints'] ?? 8,
      temporaryHitPoints: map['temporaryHitPoints'] ?? 0,
      hitDie: map['hitDie'] ?? 8,
      armorClass: map['armorClass'] ?? 10,
      speed: map['speed'] ?? 9,
      goldPieces: map['goldPieces'] ?? 0,
      silverPieces: map['silverPieces'] ?? 0,
      copperPieces: map['copperPieces'] ?? 0,
      electrumPieces: map['electrumPieces'] ?? 0,
      platinumPieces: map['platinumPieces'] ?? 0,
      notes: map['notes'] ?? '',
      personalityTraits: map['personalityTraits'] ?? '',
      ideals: map['ideals'] ?? '',
      bonds: map['bonds'] ?? '',
      flaws: map['flaws'] ?? '',
      useEdition2024: map['useEdition2024'] == 1,
      skillProficiencies: map['skillProficiencies'] != null
          ? Map<String, bool>.from(jsonDecode(map['skillProficiencies']))
          : null,
      skillExpertise: map['skillExpertise'] != null
          ? Map<String, bool>.from(jsonDecode(map['skillExpertise']))
          : null,
      savingThrowProficiencies: map['savingThrowProficiencies'] != null
          ? Map<String, bool>.from(jsonDecode(map['savingThrowProficiencies']))
          : null,
      usedHitDice: map['usedHitDice'] ?? 0,
      deathSaveSuccesses: map['deathSaveSuccesses'] ?? 0,
      deathSaveFailures: map['deathSaveFailures'] ?? 0,
      isStabilized: (map['isStabilized'] ?? 0) == 1,
      spellSlots: map['spellSlots'] != null
          ? (jsonDecode(map['spellSlots']) as Map<String, dynamic>).map(
              (k, v) => MapEntry(int.parse(k), SpellSlot.fromMap(v)),
            )
          : null,
    );
  }
}
