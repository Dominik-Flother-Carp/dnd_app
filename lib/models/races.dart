class Race {
  final String name;
  final int speed;                          // Bewegungsgeschwindigkeit in Metern
  final Map<String, int> attributeBonuses2014; // Feste Boni in 2014
  final int freeAttributePoints2024;        // Frei verteilbare Punkte in 2024
  final List<String> languages;
  final List<String> skillProficiencies;    // Fertigkeitsübungen durch Rasse

  const Race({
    required this.name,
    required this.speed,
    this.attributeBonuses2014 = const {},
    this.freeAttributePoints2024 = 3,
    this.languages = const ['Gemeinsprache'],
    this.skillProficiencies = const [],
  });
}

const List<Race> races = [
  Race(
    name: 'Mensch',
    speed: 9,
    attributeBonuses2014: {
      'strength': 1, 'dexterity': 1, 'constitution': 1,
      'intelligence': 1, 'wisdom': 1, 'charisma': 1,
    },
    languages: ['Gemeinsprache', 'Eine weitere Sprache'],
  ),
  Race(
    name: 'Zwerg (Bergzwerg)',
    speed: 7,
    attributeBonuses2014: {'constitution': 2, 'strength': 2},
    languages: ['Gemeinsprache', 'Zwergisch'],
  ),
  Race(
    name: 'Zwerg (Hügelzwerg)',
    speed: 7,
    attributeBonuses2014: {'constitution': 2, 'wisdom': 1},
    skillProficiencies: ['history'],
    languages: ['Gemeinsprache', 'Zwergisch'],
  ),
  Race(
    name: 'Elf (Hochelf)',
    speed: 9,
    attributeBonuses2014: {'dexterity': 2, 'intelligence': 1},
    skillProficiencies: ['perception'],
    languages: ['Gemeinsprache', 'Elfisch', 'Eine weitere Sprache'],
  ),
  Race(
    name: 'Elf (Waldelf)',
    speed: 10,
    attributeBonuses2014: {'dexterity': 2, 'wisdom': 1},
    skillProficiencies: ['perception'],
    languages: ['Gemeinsprache', 'Elfisch'],
  ),
  Race(
    name: 'Elf (Dunkelelfe)',
    speed: 9,
    attributeBonuses2014: {'dexterity': 2, 'charisma': 1},
    skillProficiencies: ['perception'],
    languages: ['Gemeinsprache', 'Elfisch', 'Unterdunkel'],
  ),
  Race(
    name: 'Halbling (Füßling)',
    speed: 7,
    attributeBonuses2014: {'dexterity': 2, 'constitution': 1},
    languages: ['Gemeinsprache', 'Halblingisch'],
  ),
  Race(
    name: 'Halbling (Leichtfuß)',
    speed: 7,
    attributeBonuses2014: {'dexterity': 2, 'charisma': 1},
    languages: ['Gemeinsprache', 'Halblingisch'],
  ),
  Race(
    name: 'Halbelf',
    speed: 9,
    attributeBonuses2014: {'charisma': 2, 'strength': 1, 'dexterity': 1},
    skillProficiencies: ['perception'],
    languages: ['Gemeinsprache', 'Elfisch', 'Eine weitere Sprache'],
  ),
  Race(
    name: 'Halbork',
    speed: 9,
    attributeBonuses2014: {'strength': 2, 'constitution': 1},
    skillProficiencies: ['intimidation'],
    languages: ['Gemeinsprache', 'Orkisch'],
  ),
  Race(
    name: 'Tieflinge',
    speed: 9,
    attributeBonuses2014: {'intelligence': 1, 'charisma': 2},
    languages: ['Gemeinsprache', 'Infernal'],
  ),
  Race(
    name: 'Drachentöter (Dragonborn)',
    speed: 9,
    attributeBonuses2014: {'strength': 2, 'charisma': 1},
    languages: ['Gemeinsprache', 'Drakonisch'],
  ),
  Race(
    name: 'Gnom (Felsengnom)',
    speed: 7,
    attributeBonuses2014: {'intelligence': 2, 'constitution': 1},
    skillProficiencies: ['history'],
    languages: ['Gemeinsprache', 'Gnomisch'],
  ),
  Race(
    name: 'Gnom (Waldgnom)',
    speed: 7,
    attributeBonuses2014: {'intelligence': 2, 'dexterity': 1},
    languages: ['Gemeinsprache', 'Gnomisch'],
  ),
];