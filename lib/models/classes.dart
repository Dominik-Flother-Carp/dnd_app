import 'package:dnd_app/models/spell_slot.dart';

class CharacterClass {
  final String name;
  final int hitDie;
  final String spellcastingAttribute; // '' wenn keine Zauberei
  final String? casterType;           // 'full', 'half', 'spellbook' oder null
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
  // ── Barbar ─────────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Pfad des Berserkers',    className: 'Barbar', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Pfad des Totemkriegers', className: 'Barbar', unlocksAtLevel: 3),

  // ── Barde ──────────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Schule des Wissens',   className: 'Barde', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Schule des Wagemuts',  className: 'Barde', unlocksAtLevel: 3),

  // ── Druide ─────────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Zirkel des Landes', className: 'Druide', unlocksAtLevel: 2),
  CharacterSubclass(name: 'Zirkel des Mondes', className: 'Druide', unlocksAtLevel: 2),

  // ── Hexenmeister ───────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Der Unhold',       className: 'Hexenmeister', unlocksAtLevel: 1),
  CharacterSubclass(name: 'Der Grosse Alte',  className: 'Hexenmeister', unlocksAtLevel: 1),
  CharacterSubclass(name: 'Erzfee',           className: 'Hexenmeister', unlocksAtLevel: 1),

  // ── Kämpfer ────────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Champion',          className: 'Kämpfer', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Kampfmeister',      className: 'Kämpfer', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Mystischer Ritter', className: 'Kämpfer', unlocksAtLevel: 3),

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

  // ── Mönch ──────────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Weg der offenen Hand',  className: 'Mönch', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Weg des Schattens',     className: 'Mönch', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Weg der vier Elemente', className: 'Mönch', unlocksAtLevel: 3),

  // ── Paladin ────────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Schwur der Alten',   className: 'Paladin', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Schwur der Hingabe', className: 'Paladin', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Schwur der Rache',   className: 'Paladin', unlocksAtLevel: 3),

  // ── Schurke ────────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Arkaner Betrüger', className: 'Schurke', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Assassine',        className: 'Schurke', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Dieb',             className: 'Schurke', unlocksAtLevel: 3),

  // ── Waldläufer ─────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Herr der Tiere', className: 'Waldläufer', unlocksAtLevel: 3),
  CharacterSubclass(name: 'Jäger',          className: 'Waldläufer', unlocksAtLevel: 3),

  // ── Zauberer ───────────────────────────────────────────────────────────────
  CharacterSubclass(name: 'Drachenblutlinie', className: 'Zauberer', unlocksAtLevel: 1),
  CharacterSubclass(name: 'Wilde Magie',      className: 'Zauberer', unlocksAtLevel: 1),
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
    casterType: 'pact',
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
    casterType: 'spellbook',
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

// Paktmagie-Tabelle: [slotGrad, anzahlSlots]
// Der Hexenmeister hat immer nur einen Slot-Grad und lädt bei kurzer Rast auf.
const Map<int, List<int>> pactSlotTable = {
   1: [1, 1],   // Grad 1, 1 Slot
   2: [1, 2],
   3: [2, 2],
   4: [2, 2],
   5: [3, 2],
   6: [3, 2],
   7: [4, 2],
   8: [4, 2],
   9: [5, 2],
  10: [5, 2],
  11: [5, 3],
  12: [5, 3],
  13: [5, 3],
  14: [5, 3],
  15: [5, 3],
  16: [5, 3],
  17: [5, 4],
  18: [5, 4],
  19: [5, 4],
  20: [5, 4],
};

Map<int, SpellSlot> calculateSpellSlots(String className, int level) {
  final selectedClass = characterClasses
      .where((c) => c.name == className)
      .firstOrNull;

  final casterType = selectedClass?.casterType;

  // Kein Zauberer: casterType ist null oder leer
  if (casterType == null || casterType.isEmpty) return {};

  // Paktmagie (Hexenmeister): eigene Tabelle, nur ein Slot-Grad
  if (casterType == 'pact') {
    final row = pactSlotTable[level.clamp(1, 20)];
    if (row == null) return {};
    final grade = row[0];
    final count = row[1];
    return { grade: SpellSlot(max: count, current: count) };
  }

  // 'spellbook' nutzt dieselbe Slot-Tabelle wie 'full'
  final lookupType = casterType == 'spellbook' ? 'full' : casterType;
  final table = spellSlotTable[lookupType];
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