// lib/models/class_feature.dart

import 'package:dnd_app/models/character.dart';

// ── Ressource ─────────────────────────────────────────────────────────────────

class ClassFeatureResource {
  final String label;
  final String maxFormula;
  final String restType; // 'short' | 'long'

  const ClassFeatureResource({
    required this.label,
    required this.maxFormula,
    required this.restType,
  });

  factory ClassFeatureResource.fromJson(Map<String, dynamic> j) =>
      ClassFeatureResource(
        label:      j['label'] as String,
        maxFormula: j['maxFormula'] as String,
        restType:   j['restType'] as String,
      );

  /// Wertet die Formel für einen gegebenen Charakter aus.
  /// Unterstützte Tokens: level, charisma_modifier, strength_modifier,
  /// dexterity_modifier, constitution_modifier, intelligence_modifier,
  /// wisdom_modifier
  /// Unterstützte Operatoren: +, *, floor(), ceil()
  int evaluate(Character c) => ClassFeature.evaluateFormula(maxFormula, c);
}

// ── Wahl ──────────────────────────────────────────────────────────────────────

class ClassFeatureChoiceOption {
  final String id;
  final String name;
  final String description;

  const ClassFeatureChoiceOption({
    required this.id,
    required this.name,
    required this.description,
  });

  factory ClassFeatureChoiceOption.fromJson(Map<String, dynamic> j) =>
      ClassFeatureChoiceOption(
        id:          j['id'] as String,
        name:        j['name'] as String,
        description: j['description'] as String,
      );
}

class ClassFeatureChoice {
  final String prompt;
  final List<ClassFeatureChoiceOption> options;

  const ClassFeatureChoice({required this.prompt, required this.options});

  factory ClassFeatureChoice.fromJson(Map<String, dynamic> j) =>
      ClassFeatureChoice(
        prompt:  j['prompt'] as String,
        options: (j['options'] as List)
            .map((o) => ClassFeatureChoiceOption.fromJson(o as Map<String, dynamic>))
            .toList(),
      );
}

// ── Zauberwirken ──────────────────────────────────────────────────────────────

class ClassFeatureSpellcasting {
  final String type; // 'prepared' | 'known'
  final Map<int, int>? spellsKnownByLevel;
  final List<String>? allowedSchools; // für spellPickerFilter
  final bool canSwapOnLevelUp;

  const ClassFeatureSpellcasting({
    required this.type,
    this.spellsKnownByLevel,
    this.allowedSchools,
    this.canSwapOnLevelUp = false,
  });

  factory ClassFeatureSpellcasting.fromJson(Map<String, dynamic> j) {
    final filter = j['spellPickerFilter'] as Map<String, dynamic>?;
    final knownRaw = j['spellsKnownByLevel'] as Map<String, dynamic>?;
    return ClassFeatureSpellcasting(
      type: j['type'] as String,
      spellsKnownByLevel: knownRaw?.map(
        (k, v) => MapEntry(int.parse(k), v as int),
      ),
      allowedSchools: filter != null
          ? (filter['schools'] as List).cast<String>()
          : null,
      canSwapOnLevelUp: j['canSwapOnLevelUp'] as bool? ?? false,
    );
  }
}

// ── Gewährter Zauber ──────────────────────────────────────────────────────────

class GrantedSpell {
  final String spellId;
  final int atLevel;

  const GrantedSpell({required this.spellId, required this.atLevel});

  factory GrantedSpell.fromJson(Map<String, dynamic> j) => GrantedSpell(
        spellId: j['spellId'] as String,
        atLevel: j['atLevel'] as int,
      );
}

// ── Hauptmodell ───────────────────────────────────────────────────────────────

class ClassFeature {
  final String id;
  final String name;
  final int unlocksAtLevel;
  final String? subclassName;
  final String description;
  final ClassFeatureResource? resource;
  final ClassFeatureChoice? choice;
  final ClassFeatureSpellcasting? spellcasting;
  final List<GrantedSpell>? grantedSpells;

  /// Falls gesetzt, ist dieses Feature eine Erweiterung des Features mit
  /// dieser ID (z.B. Domänen-Erweiterung von Göttliche Macht fokussieren).
  final String? extendsFeatureId;

  /// Unterklassen-Features die dieses Feature erweitern (wird beim Mergen
  /// vom Service befüllt, steht nicht in der JSON).
  final List<ClassFeature> extensions;

  const ClassFeature({
    required this.id,
    required this.name,
    required this.unlocksAtLevel,
    this.subclassName,
    required this.description,
    this.resource,
    this.choice,
    this.spellcasting,
    this.grantedSpells,
    this.extendsFeatureId,
    this.extensions = const [],
  });

  factory ClassFeature.fromJson(Map<String, dynamic> j) => ClassFeature(
        id:              j['id'] as String,
        name:            j['name'] as String,
        unlocksAtLevel:  j['unlocksAtLevel'] as int,
        subclassName:    j['subclassName'] as String?,
        description:     j['description'] as String? ?? '',
        resource:        j['resource'] != null
            ? ClassFeatureResource.fromJson(
                j['resource'] as Map<String, dynamic>)
            : null,
        choice:          j['choice'] != null
            ? ClassFeatureChoice.fromJson(
                j['choice'] as Map<String, dynamic>)
            : null,
        spellcasting:    j['spellcasting'] != null
            ? ClassFeatureSpellcasting.fromJson(
                j['spellcasting'] as Map<String, dynamic>)
            : null,
        grantedSpells:   j['grantedSpells'] != null
            ? (j['grantedSpells'] as List)
                .map((g) => GrantedSpell.fromJson(g as Map<String, dynamic>))
                .toList()
            : null,
        extendsFeatureId: j['extends'] as String?,
      );

  ClassFeature withExtensions(List<ClassFeature> exts) => ClassFeature(
        id:               id,
        name:             name,
        unlocksAtLevel:   unlocksAtLevel,
        subclassName:     subclassName,
        description:      description,
        resource:         resource,
        choice:           choice,
        spellcasting:     spellcasting,
        grantedSpells:    grantedSpells,
        extendsFeatureId: extendsFeatureId,
        extensions:       exts,
      );

  // ── Formel-Auswertung ──────────────────────────────────────────────────────

  static int evaluateFormula(String formula, Character c) {
    // Token-Ersetzung
    String expr = formula
        .replaceAll('charisma_modifier',    '${c.chaModifier}')
        .replaceAll('strength_modifier',    '${c.strModifier}')
        .replaceAll('dexterity_modifier',   '${c.dexModifier}')
        .replaceAll('constitution_modifier','${c.conModifier}')
        .replaceAll('intelligence_modifier','${c.intModifier}')
        .replaceAll('wisdom_modifier',      '${c.wisModifier}')
        .replaceAll('level',                '${c.level}');

    // floor() und ceil() auflösen
    expr = _resolveRounding(expr);

    // Einfache Arithmetik auswerten (nur +, -, *)
    return _evalArithmetic(expr);
  }

  static String _resolveRounding(String expr) {
    // floor(x) → x abgerundet, ceil(x) → x aufgerundet
    final floorRe = RegExp(r'floor\(([^)]+)\)');
    final ceilRe  = RegExp(r'ceil\(([^)]+)\)');
    expr = expr.replaceAllMapped(floorRe,
        (m) => '${(_evalArithmetic(m.group(1)!.trim()))}');
    expr = expr.replaceAllMapped(ceilRe,
        (m) => '${(_evalArithmetic(m.group(1)!.trim(), ceil: true))}');
    return expr;
  }

  static int _evalArithmetic(String expr, {bool ceil = false}) {
    // Unterstützt: a + b, a - b, a * b, gemischt links-nach-rechts
    final tokens = expr.replaceAll(' ', '').split(RegExp(r'(?=[+\-*])|(?<=[+\-*])'));
    if (tokens.isEmpty) return 0;
    double result = double.tryParse(tokens[0]) ?? 0;
    int i = 1;
    while (i < tokens.length - 1) {
      final op  = tokens[i];
      final val = double.tryParse(tokens[i + 1]) ?? 0;
      if (op == '+') {result += val;}
      else if (op == '-') {result -= val;}
      else if (op == '*') {result *= val;}
      i += 2;
    }
    return ceil ? result.ceil() : result.floor();
  }
}