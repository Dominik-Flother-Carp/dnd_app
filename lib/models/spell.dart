// lib/models/spell.dart

import 'package:uuid/uuid.dart';
import 'package:dnd_app/models/enums.dart';

enum SpellSchool {
  abjuration,    // Bannmagie
  conjuration,   // Beschwörung
  divination,    // Divination
  enchantment,   // Verzauberung
  evocation,     // Evokation
  illusion,      // Illusion
  necromancy,    // Nekromantie
  transmutation, // Verwandlung
}

// Welches Attribut wird für den Angriffswurf genutzt?
enum AttackRollType {
  none,      // Kein Angriffswurf
  melee,     // Nahkampf-Zauberangriff
  ranged,    // Fernkampf-Zauberangriff
}

class Spell {
  final String id;
  String name;
  // ── Zauber-Metadaten ──────────────────────────────────────────────────────
  SpellSchool school;
  int _level = 0;      // 0 = Zaubertrick, 1–9 = Zaubergrad
  String castingTime;  // z.B. '1 Aktion', '1 Bonusaktion', '1 Minute'
  String range;        // z.B. '18 m', 'Berührung', 'Selbst'
  String duration;     // z.B. 'Sofort', 'Konzentration, bis zu 1 Minute'
  bool concentration;  // Benötigt Konzentration?
  bool ritual;         // Kann als Ritual gewirkt werden?

  // ── Komponenten ───────────────────────────────────────────────────────────
  bool componentVerbal;    // V
  bool componentSomatic;   // S
  bool componentMaterial;  // M
  String materialComponent; // Beschreibung des Materials, z.B. 'Eine Fledermaus'

  // ── Mechanik ──────────────────────────────────────────────────────────────
  AttackRollType attackRollType;
  SavingThrowAttribute savingThrowAttribute;
  String? damageDice;   // z.B. '8d6', null wenn kein Schaden
  String? damageType;   // z.B. 'Feuer', 'Kälte', null wenn kein Schaden

  // ── Beschreibung ──────────────────────────────────────────────────────────
  String effectDescription;  // Hauptbeschreibung des Effekts
  String? atHigherLevels;    // Optionale Skalierung auf höheren Graden
  List<String> classes;      // Klassenname(n) die diesen Zauber nutzen können

  Spell({
    String? id,
    required this.name,
    this.school = SpellSchool.evocation,
    int level = 0,
    this.castingTime = '1 Aktion',
    this.range = 'Selbst',
    this.duration = 'Sofort',
    this.concentration = false,
    this.ritual = false,
    this.componentVerbal = true,
    this.componentSomatic = false,
    this.componentMaterial = false,
    this.materialComponent = '',
    this.attackRollType = AttackRollType.none,
    this.savingThrowAttribute = SavingThrowAttribute.none,
    this.damageDice,
    this.damageType,
    required this.effectDescription,
    this.atHigherLevels,
    List<String>? classes,
  })  : classes = classes ?? [],
        id = id ?? const Uuid().v4() {
    _level = level.clamp(0, 9);
  }

  // ── Getter & Setter ───────────────────────────────────────────────────────

  // Zaubergrad: 0 (Zaubertrick) bis 9
  int get level => _level;
  set level(int value) => _level = value.clamp(0, 9);

  // Ob der Zauber einen Angriffswurf benötigt
  bool get requiresAttackRoll => attackRollType != AttackRollType.none;

  // Ob der Zauber einen Rettungswurf auslöst
  bool get requiresSavingThrow => savingThrowAttribute != SavingThrowAttribute.none;

  // Ob der Zauber Schaden verursacht
  bool get dealsDamage => damageDice != null && damageDice!.isNotEmpty;

  // Lesbare Komponentenliste, z.B. 'V, S, M (Eine Fledermaus)'
  String get componentsDisplay {
    final parts = <String>[];
    if (componentVerbal) parts.add('V');
    if (componentSomatic) parts.add('S');
    if (componentMaterial) {
      parts.add(materialComponent.isNotEmpty ? 'M ($materialComponent)' : 'M');
    }
    return parts.join(', ');
  }

  // ── Datenbank: Konvertierung ──────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id':                     id,
      'name':                   name,
      'school':                 school.name,
      'level':                  level,
      'castingTime':            castingTime,
      'range':                  range,
      'duration':               duration,
      'concentration':          concentration ? 1 : 0,
      'ritual':                 ritual ? 1 : 0,
      'componentVerbal':        componentVerbal ? 1 : 0,
      'componentSomatic':       componentSomatic ? 1 : 0,
      'componentMaterial':      componentMaterial ? 1 : 0,
      'materialComponent':      materialComponent,
      'attackRollType':         attackRollType.name,
      'savingThrowAttribute':   savingThrowAttribute.name,
      'damageDice':             damageDice,
      'damageType':             damageType,
      'effectDescription':      effectDescription,
      'atHigherLevels':         atHigherLevels,
      'classes':                classes.join(','),
    };
  }

  factory Spell.fromMap(Map<String, dynamic> map) {
    return Spell(
      id:                   map['id'],
      name:                 map['name'],
      school:               SpellSchool.values.byName(map['school'] ?? 'evocation'),
      level:                map['level'] ?? 0,
      castingTime:          map['castingTime'] ?? '1 Aktion',
      range:                map['range'] ?? 'Selbst',
      duration:             map['duration'] ?? 'Sofort',
      concentration:        map['concentration'] == 1,
      ritual:               map['ritual'] == 1,
      componentVerbal:      map['componentVerbal'] == 1,
      componentSomatic:     map['componentSomatic'] == 1,
      componentMaterial:    map['componentMaterial'] == 1,
      materialComponent:    map['materialComponent'] ?? '',
      attackRollType:       AttackRollType.values.byName(
                              map['attackRollType'] ?? 'none'),
      savingThrowAttribute: SavingThrowAttribute.values.byName(
                              map['savingThrowAttribute'] ?? 'none'),
      damageDice:           map['damageDice'],
      damageType:           map['damageType'],
      effectDescription:    map['effectDescription'] ?? '',
      atHigherLevels:       map['atHigherLevels'],
      classes:              (map['classes'] as String? ?? '').isEmpty
                              ? []
                              : (map['classes'] as String).split(','),
    );
  }
}