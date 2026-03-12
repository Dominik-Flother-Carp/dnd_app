import 'package:dnd_app/models/spell_slot.dart';

class CharacterClass {
  final String name;
  final int hitDie;
  final String spellcastingAttribute; // '' wenn keine Zauberei
  final String? casterType;           // 'full', 'half' oder null
  final List<String> availableSkills; // Fertigkeiten aus denen gewählt werden kann
  final List<String> proficientSavingThrows;
  final int skillChoices;             // Anzahl der wählbaren Fertigkeiten

  const CharacterClass({
    required this.name,
    required this.hitDie,
    this.spellcastingAttribute = '',
    required this.availableSkills,
    required this.proficientSavingThrows,
    required this.skillChoices,
    this.casterType,
  });
}


// ── Unterklassen-Modell ───────────────────────────────────────────────────────

class CharacterSubclass {
  final String name;
  final String className;      // Name der Elternklasse
  final int unlocksAtLevel;    // Ab welcher Stufe wählbar

  const CharacterSubclass({
    required this.name,
    required this.className,
    required this.unlocksAtLevel,
  });
}

const List<CharacterSubclass> characterSubclasses = [
  // ── Kämpfer ────────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Champion',          className: 'Kämpfer',  unlocksAtLevel: 3),
  CharacterSubclass(name: 'Kampfmeister',      className: 'Kämpfer',  unlocksAtLevel: 3),
  CharacterSubclass(name: 'Mystischer Ritter', className: 'Kämpfer',  unlocksAtLevel: 3),

  // ── Kleriker ───────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Domäne des Krieges', className: 'Kleriker', unlocksAtLevel: 1),
  CharacterSubclass(name: 'Domäne des Lebens',  className: 'Kleriker', unlocksAtLevel: 1),
  CharacterSubclass(name: 'Domäne des Lichts',  className: 'Kleriker', unlocksAtLevel: 1),
  CharacterSubclass(name: 'Domäne der List',    className: 'Kleriker', unlocksAtLevel: 1),
  CharacterSubclass(name: 'Domäne der Natur',   className: 'Kleriker', unlocksAtLevel: 1),
  CharacterSubclass(name: 'Domäne des Sturms',  className: 'Kleriker', unlocksAtLevel: 1),
  CharacterSubclass(name: 'Domäne des Wissens', className: 'Kleriker', unlocksAtLevel: 1),

  // ── Magier ─────────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Schule der Bannmagie',    className: 'Magier', unlocksAtLevel: 2),
  CharacterSubclass(name: 'Schule der Beschwörung',  className: 'Magier', unlocksAtLevel: 2),
  CharacterSubclass(name: 'Schule der Erkenntnis',   className: 'Magier', unlocksAtLevel: 2),
  CharacterSubclass(name: 'Schule der Hervorrufung', className: 'Magier', unlocksAtLevel: 2),
  CharacterSubclass(name: 'Schule der Illusion',     className: 'Magier', unlocksAtLevel: 2),
  CharacterSubclass(name: 'Schule der Nekromantie',  className: 'Magier', unlocksAtLevel: 2),
  CharacterSubclass(name: 'Schule der Verwandlung',  className: 'Magier', unlocksAtLevel: 2),
  CharacterSubclass(name: 'Schule der Verzauberung', className: 'Magier', unlocksAtLevel: 2),

  // ── Paladin ────────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Schwur der Alten',   className: 'Paladin', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Schwur der Hingabe', className: 'Paladin', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Schwur der Rache',   className: 'Paladin', unlocksAtLevel: 3),

  // ── Schurke ────────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Arkaner Betrüger', className: 'Schurke', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Assassine',        className: 'Schurke', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Dieb',             className: 'Schurke', unlocksAtLevel: 3),
];

/// Gibt alle verfügbaren Unterklassen für eine Klasse bei gegebenem Level zurück.
List<CharacterSubclass> availableSubclasses(String className, int level) {
  return characterSubclasses
      .where((s) => s.className == className && s.unlocksAtLevel <= level)
      .toList();
}

const List<CharacterClass> characterClasses = [
  CharacterClass(
    name: 'Barbar',
    hitDie: 12,
    casterType: '',
    skillChoices: 2,
    availableSkills: [
      'animalHandling', 'athletics', 'intimidation',
      'nature', 'perception', 'survival',
    ],
    proficientSavingThrows: [
      'strength', 'constitution'
    ]
  ),
  CharacterClass(
    name: 'Barde',
    hitDie: 8,
    casterType: 'full',
    spellcastingAttribute: 'charisma',
    skillChoices: 3,
    availableSkills: [
      'acrobatics', 'animalHandling', 'arcana', 'athletics',
      'deception', 'history', 'insight', 'intimidation',
      'investigation', 'medicine', 'nature', 'perception',
      'performance', 'persuasion', 'religion', 'sleightOfHand',
      'stealth', 'survival',
    ],
    proficientSavingThrows: [
      'dexterity', 'charisma'
    ]
  ),
  CharacterClass(
    name: 'Druide',
    hitDie: 8,
    casterType: 'full',
    spellcastingAttribute: 'wisdom',
    skillChoices: 2,
    availableSkills: [
      'arcana', 'animalHandling', 'insight', 'medicine',
      'nature', 'perception', 'religion', 'survival',
    ],
    proficientSavingThrows: [
      'intelligence', 'wisdom'
    ]
  ),
  CharacterClass(
    name: 'Hexenmeister',
    hitDie: 8,
    casterType: 'full',
    spellcastingAttribute: 'charisma',
    skillChoices: 2,
    availableSkills: [
      'arcana', 'deception', 'history', 'intimidation',
      'investigation', 'nature', 'religion',
    ],
    proficientSavingThrows: [
      'wisdom', 'charisma'
    ]
  ),
  CharacterClass(
    name: 'Kämpfer',
    hitDie: 10,
    casterType: '',
    skillChoices: 2,
    availableSkills: [
      'acrobatics', 'animalHandling', 'athletics', 'history',
      'insight', 'intimidation', 'perception', 'survival',
    ],
    proficientSavingThrows: [
      'strength', 'constitution'
    ]
  ),
  CharacterClass(
    name: 'Kleriker',
    hitDie: 8,
    casterType: 'full',
    spellcastingAttribute: 'wisdom',
    skillChoices: 2,
    availableSkills: [
      'history', 'insight', 'medicine', 'persuasion', 'religion',
    ],
    proficientSavingThrows: [
      'wisdom', 'charisma'
    ]
  ),
  CharacterClass(
    name: 'Magier',
    hitDie: 6,
    casterType: 'full',
    spellcastingAttribute: 'intelligence',
    skillChoices: 2,
    availableSkills: [
      'arcana', 'history', 'insight', 'investigation',
      'medicine', 'religion',
    ],
    proficientSavingThrows: [
      'intelligence', 'wisdom'
    ]
  ),
  CharacterClass(
    name: 'Mönch',
    hitDie: 8,
    casterType: '',
    skillChoices: 2,
    availableSkills: [
      'acrobatics', 'athletics', 'history', 'insight',
      'religion', 'stealth',
    ],
    proficientSavingThrows: [
      'strength', 'dexterity'
    ]
  ),
  CharacterClass(
    name: 'Paladin',
    hitDie: 10,
    casterType: 'half',
    spellcastingAttribute: 'charisma',
    skillChoices: 2,
    availableSkills: [
      'athletics', 'insight', 'intimidation',
      'medicine', 'persuasion', 'religion',
    ],
    proficientSavingThrows: [
      'wisdom', 'charisma'
    ]
  ),
  CharacterClass(
    name: 'Schurke',
    hitDie: 8,
    casterType: '',
    skillChoices: 4,
    availableSkills: [
      'acrobatics', 'athletics', 'deception', 'insight',
      'intimidation', 'investigation', 'perception', 'performance',
      'persuasion', 'sleightOfHand', 'stealth',
    ],
    proficientSavingThrows: [
      'dexterity', 'intelligence'
    ]
  ),
  CharacterClass(
    name: 'Waldläufer',
    hitDie: 8,
    casterType: 'half',
    spellcastingAttribute: 'wisdom',
    skillChoices: 3,
    availableSkills: [
      'animalHandling', 'athletics', 'insight', 'investigation',
      'nature', 'perception', 'stealth', 'survival',
    ],
    proficientSavingThrows: [
      'strength', 'dexterity'
    ]
  ),
  CharacterClass(
    name: 'Zauberer',
    hitDie: 6,
    casterType: 'full',
    spellcastingAttribute: 'charisma',
    skillChoices: 2,
    availableSkills: [
      'arcana', 'deception', 'insight', 'intimidation',
      'persuasion', 'religion', 'survival',
    ],
    proficientSavingThrows: [
      'charisma', 'constitution'
    ]
  ),
];

const Map<String, Map<int, List<int>>> spellSlotTable = {
  'full': {
     1: [2,0,0,0,0,0,0,0,0],
     2: [3,0,0,0,0,0,0,0,0],
     3: [4,2,0,0,0,0,0,0,0],
     4: [4,3,0,0,0,0,0,0,0],
     5: [4,3,2,0,0,0,0,0,0],
     6: [4,3,3,0,0,0,0,0,0],
     7: [4,3,3,1,0,0,0,0,0],
     8: [4,3,3,2,0,0,0,0,0],
     9: [4,3,3,3,1,0,0,0,0],
    10: [4,3,3,3,2,0,0,0,0],
    11: [4,3,3,3,2,1,0,0,0],
    12: [4,3,3,3,2,1,0,0,0],
    13: [4,3,3,3,2,1,1,0,0],
    14: [4,3,3,3,2,1,1,0,0],
    15: [4,3,3,3,2,1,1,1,0],
    16: [4,3,3,3,2,1,1,1,0],
    17: [4,3,3,3,2,1,1,1,1],
    18: [4,3,3,3,3,1,1,1,1],
    19: [4,3,3,3,3,2,1,1,1],
    20: [4,3,3,3,3,2,2,1,1],
  },
  'half': {
     1: [0,0,0,0,0,0,0,0,0],
     2: [2,0,0,0,0,0,0,0,0],
     3: [3,0,0,0,0,0,0,0,0],
     4: [3,0,0,0,0,0,0,0,0],
     5: [4,2,0,0,0,0,0,0,0],
     6: [4,2,0,0,0,0,0,0,0],
     7: [4,3,0,0,0,0,0,0,0],
     8: [4,3,0,0,0,0,0,0,0],
     9: [4,3,2,0,0,0,0,0,0],
    10: [4,3,2,0,0,0,0,0,0],
    11: [4,3,3,0,0,0,0,0,0],
    12: [4,3,3,0,0,0,0,0,0],
    13: [4,3,3,1,0,0,0,0,0],
    14: [4,3,3,1,0,0,0,0,0],
    15: [4,3,3,2,0,0,0,0,0],
    16: [4,3,3,2,0,0,0,0,0],
    17: [4,3,3,3,1,0,0,0,0],
    18: [4,3,3,3,1,0,0,0,0],
    19: [4,3,3,3,2,0,0,0,0],
    20: [4,3,3,3,2,0,0,0,0],
  },
};

Map<int, SpellSlot> calculateSpellSlots(String className, int level) {
  final selectedClass = characterClasses
      .where((c) => c.name == className)
      .firstOrNull;

  final casterType = selectedClass?.casterType;

  // Kein Zauberer: casterType ist null oder leer
  if (casterType == null || casterType.isEmpty) return {};

  // Unbekannter casterType (sollte nicht vorkommen, aber sicher ist sicher)
  final table = spellSlotTable[casterType];
  if (table == null) return {};

  final slots = table[level.clamp(1, 20)];
  if (slots == null) return {};

  final result = <int, SpellSlot>{};
  for (int i = 0; i < slots.length; i++) {
    if (slots[i] > 0) {
      result[i + 1] = SpellSlot(max: slots[i], current: slots[i]);
    }
  }
  return result;
}