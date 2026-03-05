/// Zentrale Definitionen aller D&D 5e Attribute.
/// Wird von basic_info_step.dart, overview_tab.dart und skills_tab.dart genutzt.
class Attributes {
  Attributes._();

  static const Map<String, String> labels = {
    'strength':     'Stärke',
    'dexterity':    'Geschicklichkeit',
    'constitution': 'Konstitution',
    'intelligence': 'Intelligenz',
    'wisdom':       'Weisheit',
    'charisma':     'Charisma',
  };

  static const Map<String, String> abbreviations = {
    'strength':     'STR',
    'dexterity':    'GES',
    'constitution': 'KON',
    'intelligence': 'INT',
    'wisdom':       'WEI',
    'charisma':     'CHA',
  };

  static String label(String key) => labels[key] ?? key;
  static String abbreviation(String key) => abbreviations[key] ?? key;
}