// lib/models/skills.dart

/// Zentrale Definitionen aller D&D 5e Fertigkeiten.
/// Wird von skills_step.dart, skills_tab.dart und basic_info_step.dart genutzt.
class Skills {
  Skills._();

  /// Deutsche Bezeichnungen aller 18 Fertigkeiten
  static const Map<String, String> labels = {
    'acrobatics':     'Akrobatik',
    'animalHandling': 'Mit Tieren umgehen',
    'arcana':         'Arkane Kunde',
    'athletics':      'Athletik',
    'deception':      'Täuschen',
    'history':        'Geschichte',
    'insight':        'Motiv erkennen',
    'intimidation':   'Einschüchtern',
    'investigation':  'Nachforschung',
    'medicine':       'Heilkunde',
    'nature':         'Naturkunde',
    'perception':     'Wahrnehmung',
    'performance':    'Auftreten',
    'persuasion':     'Überzeugen',
    'religion':       'Religion',
    'sleightOfHand':  'Fingerfertigkeit',
    'stealth':        'Heimlichkeit',
    'survival':       'Überleben',
  };

  /// Zugehöriges Attribut jeder Fertigkeit
  static const Map<String, String> attributes = {
    'acrobatics':     'GES',
    'animalHandling': 'WEI',
    'arcana':         'INT',
    'athletics':      'STR',
    'deception':      'CHA',
    'history':        'INT',
    'insight':        'WEI',
    'intimidation':   'CHA',
    'investigation':  'INT',
    'medicine':       'WEI',
    'nature':         'INT',
    'perception':     'WEI',
    'performance':    'CHA',
    'persuasion':     'CHA',
    'religion':       'INT',
    'sleightOfHand':  'GES',
    'stealth':        'GES',
    'survival':       'WEI',
  };

  static const Map<String, String> attributekeys = {
    'acrobatics':     'dexterity',
      'animalHandling': 'wisdom',
      'arcana':         'intelligence',
      'athletics':      'strength',
      'deception':      'charisma',
      'history':        'intelligence',
      'insight':        'wisdom',
      'intimidation':   'charisma',
      'investigation':  'intelligence',
      'medicine':       'wisdom',
      'nature':         'intelligence',
      'perception':     'wisdom',
      'performance':    'charisma',
      'persuasion':     'charisma',
      'religion':       'intelligence',
      'sleightOfHand':  'dexterity',
      'stealth':        'dexterity',
      'survival':       'wisdom',
  };

  /// Gibt den deutschen Namen einer Fertigkeit zurück
  static String label(String key) => labels[key] ?? key;

  /// Gibt das zugehörige Attributkürzel zurück
  static String attribute(String key) => attributes[key] ?? '';
}