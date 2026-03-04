class CharacterClass {
  final String name;
  final int hitDie;
  final String spellcastingAttribute; // '' wenn keine Zauberei
  final List<String> availableSkills; // Fertigkeiten aus denen gewählt werden kann
  final int skillChoices;             // Anzahl der wählbaren Fertigkeiten

  const CharacterClass({
    required this.name,
    required this.hitDie,
    this.spellcastingAttribute = '',
    required this.availableSkills,
    required this.skillChoices,
  });
}

const List<CharacterClass> characterClasses = [
  CharacterClass(
    name: 'Barbar',
    hitDie: 12,
    skillChoices: 2,
    availableSkills: [
      'animalHandling', 'athletics', 'intimidation',
      'nature', 'perception', 'survival',
    ],
  ),
  CharacterClass(
    name: 'Barde',
    hitDie: 8,
    spellcastingAttribute: 'charisma',
    skillChoices: 3,
    availableSkills: [
      'acrobatics', 'animalHandling', 'arcana', 'athletics',
      'deception', 'history', 'insight', 'intimidation',
      'investigation', 'medicine', 'nature', 'perception',
      'performance', 'persuasion', 'religion', 'sleightOfHand',
      'stealth', 'survival',
    ],
  ),
  CharacterClass(
    name: 'Druide',
    hitDie: 8,
    spellcastingAttribute: 'wisdom',
    skillChoices: 2,
    availableSkills: [
      'arcana', 'animalHandling', 'insight', 'medicine',
      'nature', 'perception', 'religion', 'survival',
    ],
  ),
  CharacterClass(
    name: 'Kämpfer',
    hitDie: 10,
    skillChoices: 2,
    availableSkills: [
      'acrobatics', 'animalHandling', 'athletics', 'history',
      'insight', 'intimidation', 'perception', 'survival',
    ],
  ),
  CharacterClass(
    name: 'Kleriker',
    hitDie: 8,
    spellcastingAttribute: 'wisdom',
    skillChoices: 2,
    availableSkills: [
      'history', 'insight', 'medicine', 'persuasion', 'religion',
    ],
  ),
  CharacterClass(
    name: 'Magier',
    hitDie: 6,
    spellcastingAttribute: 'intelligence',
    skillChoices: 2,
    availableSkills: [
      'arcana', 'history', 'insight', 'investigation',
      'medicine', 'religion',
    ],
  ),
  CharacterClass(
    name: 'Mönch',
    hitDie: 8,
    skillChoices: 2,
    availableSkills: [
      'acrobatics', 'athletics', 'history', 'insight',
      'religion', 'stealth',
    ],
  ),
  CharacterClass(
    name: 'Paladin',
    hitDie: 10,
    spellcastingAttribute: 'charisma',
    skillChoices: 2,
    availableSkills: [
      'athletics', 'insight', 'intimidation',
      'medicine', 'persuasion', 'religion',
    ],
  ),
  CharacterClass(
    name: 'Schurke',
    hitDie: 8,
    skillChoices: 4,
    availableSkills: [
      'acrobatics', 'athletics', 'deception', 'insight',
      'intimidation', 'investigation', 'perception', 'performance',
      'persuasion', 'sleightOfHand', 'stealth',
    ],
  ),
  CharacterClass(
    name: 'Waldläufer',
    hitDie: 8,
    spellcastingAttribute: 'wisdom',
    skillChoices: 3,
    availableSkills: [
      'animalHandling', 'athletics', 'insight', 'investigation',
      'nature', 'perception', 'stealth', 'survival',
    ],
  ),
  CharacterClass(
    name: 'Hexenmeister',
    hitDie: 8,
    spellcastingAttribute: 'charisma',
    skillChoices: 2,
    availableSkills: [
      'arcana', 'deception', 'history', 'intimidation',
      'investigation', 'nature', 'religion',
    ],
  ),
  CharacterClass(
    name: 'Zauberer',
    hitDie: 6,
    spellcastingAttribute: 'intelligence',
    skillChoices: 2,
    availableSkills: [
      'arcana', 'history', 'insight', 'investigation',
      'medicine', 'religion',
    ],
  ),
];