class Background {
  final String name;
  final List<String> skillProficiencies;    // immer 2 Fertigkeiten
  final List<String> toolProficiencies;     // Werkzeugübungen
  final List<String> languages;             // zusätzliche Sprachen
  final String? bonusAttribute2024;         // nur 2024: welches Attribut
  final int bonusValue2024;                 // nur 2024: wie viel Bonus
  final String description;

  const Background({
    required this.name,
    required this.skillProficiencies,
    this.toolProficiencies = const [],
    this.languages = const [],
    this.bonusAttribute2024,
    this.bonusValue2024 = 1,
    this.description = '',
  });
}

const List<Background> backgrounds = [
  Background(
    name: 'Soldat',
    skillProficiencies: ['athletics', 'intimidation'],
    toolProficiencies: ['Spielzeug', 'Landfahrzeuge'],
    bonusAttribute2024: 'strength',
    description: 'Du hast als Soldat gedient.',
  ),
  Background(
    name: 'Krimineller',
    skillProficiencies: ['deception', 'stealth'],
    toolProficiencies: ["Diebeswerkzeug"],
    bonusAttribute2024: 'dexterity',
    description: 'Du hast als Krimineller gelebt.',
  ),
  Background(
    name: 'Volksmensch',
    skillProficiencies: ['insight', 'persuasion'],
    toolProficiencies: ['Ein Handwerkswerkzeug'],
    languages: ['Eine Sprache nach Wahl'],
    bonusAttribute2024: 'charisma',
    description: 'Du warst ein einfacher Bürger.',
  ),
  Background(
    name: 'Einsiedler',
    skillProficiencies: ['medicine', 'religion'],
    toolProficiencies: ['Kräuterkundeset'],
    languages: ['Eine Sprache nach Wahl'],
    bonusAttribute2024: 'wisdom',
    description: 'Du hast in Abgeschiedenheit gelebt.',
  ),
  Background(
    name: 'Adliger',
    skillProficiencies: ['history', 'persuasion'],
    toolProficiencies: ['Ein Spielzeug'],
    languages: ['Eine Sprache nach Wahl'],
    bonusAttribute2024: 'charisma',
    description: 'Du entstammst einer adligen Familie.',
  ),
  Background(
    name: 'Weise',
    skillProficiencies: ['arcana', 'history'],
    languages: ['Zwei Sprachen nach Wahl'],
    bonusAttribute2024: 'intelligence',
    description: 'Du hast dein Leben dem Studium gewidmet.',
  ),
  Background(
    name: 'Ausgestoßener',
    skillProficiencies: ['athletics', 'survival'],
    languages: ['Eine Sprache nach Wahl'],
    bonusAttribute2024: 'constitution',
    description: 'Du hast in der Wildnis überlebt.',
  ),
  Background(
    name: 'Gildenhandwerker',
    skillProficiencies: ['insight', 'persuasion'],
    toolProficiencies: ['Ein Handwerkswerkzeug'],
    languages: ['Eine Sprache nach Wahl'],
    bonusAttribute2024: 'charisma',
    description: 'Du warst Mitglied einer Handwerksgilde.',
  ),
  Background(
    name: 'Unterweltler',
    skillProficiencies: ['deception', 'stealth'],
    toolProficiencies: ['Diebeswerkzeug', 'Ein Spielzeug'],
    bonusAttribute2024: 'dexterity',
    description: 'Du hast in den Schatten der Gesellschaft gelebt.',
  ),
  Background(
    name: 'Seemann',
    skillProficiencies: ['athletics', 'perception'],
    toolProficiencies: ['Navigationsset', 'Wasserfahrzeuge'],
    bonusAttribute2024: 'strength',
    description: 'Du hast auf See gelebt.',
  ),
  Background(
    name: 'Entertainer',
    skillProficiencies: ['acrobatics', 'performance'],
    toolProficiencies: ['Verkleidungsset', 'Ein Musikinstrument'],
    bonusAttribute2024: 'charisma',
    description: 'Du hast als Entertainer die Massen begeistert.',
  ),
  Background(
    name: 'Gefolgsmann',
    skillProficiencies: ['history', 'persuasion'],
    toolProficiencies: ['Ein Spielzeug'],
    languages: ['Eine Sprache nach Wahl'],
    bonusAttribute2024: 'charisma',
    description: 'Du hast einem Adligen oder einer Kirche gedient.',
  ),
];