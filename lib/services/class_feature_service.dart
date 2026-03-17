// lib/services/class_feature_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/models/class_feature.dart';

class ClassFeatureService {
  // Singleton
  static final ClassFeatureService _instance = ClassFeatureService._internal();
  factory ClassFeatureService() => _instance;
  ClassFeatureService._internal();

  // Cache: className → alle geladenen Features (Basis + Unterklassen)
  final Map<String, List<ClassFeature>> _cache = {};

  // Fluff-Cache: "$className/$subclassName" → fluff-Text
  final Map<String, String> _fluffCache = {};

  // Mapping: Klassenname → explizite Asset-Pfade
  static const _classPaths = {
    'Kleriker': [
      'assets/json/class_features/cleric/cleric.json',
      'assets/json/class_features/cleric/life.json',
    ],
    'Paladin': [
      'assets/json/class_features/paladin/paladin.json',
      'assets/json/class_features/paladin/devotion.json',
    ],
    'Schurke': [
      'assets/json/class_features/rogue/rogue.json',
      'assets/json/class_features/rogue/thief.json',
    ],
    'Magier': [
      'assets/json/class_features/wizard/wizard.json',
      'assets/json/class_features/wizard/evocation.json',
    ],
  };

  // ── Laden ──────────────────────────────────────────────────────────────────

  Future<void> loadForClass(String className) async {
    if (_cache.containsKey(className)) return;

    final paths = _classPaths[className];
    if (paths == null) {
      _cache[className] = [];
      return;
    }

    final List<ClassFeature> all = [];
    for (final path in paths) {
      try {
        final raw = await rootBundle.loadString(path);
        if (raw.trim().isEmpty) continue;
        final data = json.decode(raw) as Map<String, dynamic>;
        final subclassName = data['subclassName'] as String?;

        // Fluff speichern
        if (subclassName != null && data['fluff'] != null) {
          _fluffCache['$className/$subclassName'] = data['fluff'] as String;
        }

        for (final f in (data['features'] as List)) {
          all.add(ClassFeature.fromJson(f as Map<String, dynamic>));
        }
      } catch (e) {
        debugPrint('ClassFeatureService: Fehler beim Laden von $path: $e');
      }
    }

    _cache[className] = _mergeExtensions(all);
  }

  /// Mergt `extends`-Features in ihr Basis-Feature.
  List<ClassFeature> _mergeExtensions(List<ClassFeature> all) {
    final extensions = all.where((f) => f.extendsFeatureId != null).toList();
    final bases      = all.where((f) => f.extendsFeatureId == null).toList();

    return bases.map((base) {
      final exts = extensions
          .where((e) => e.extendsFeatureId == base.id)
          .toList();
      return exts.isEmpty ? base : base.withExtensions(exts);
    }).toList();
  }

  // ── Abfragen ───────────────────────────────────────────────────────────────

  /// Gibt alle für den Charakter relevanten Features zurück:
  /// - Basisklassen-Features bis c.level (subclassName == null)
  /// - Unterklassen-Features falls c.subclass gesetzt und unlocksAtLevel <= c.level
  Future<List<ClassFeature>> getFeaturesForCharacter(Character c) async {
    await loadForClass(c.characterClass);
    final all = _cache[c.characterClass] ?? [];

    return all.where((f) {
      if (f.unlocksAtLevel > c.level) return false;
      if (f.subclassName == null) return true; // Basisklasse
      return f.subclassName == c.subclass;     // Unterklasse
    }).toList()
      ..sort((a, b) => a.unlocksAtLevel.compareTo(b.unlocksAtLevel));
  }

  /// Gibt den Fluff-Text einer Unterklasse zurück, oder null.
  Future<String?> getSubclassFluff(String className, String subclassName) async {
    await loadForClass(className);
    return _fluffCache['$className/$subclassName'];
  }

  /// Gibt alle `grantedSpells`-IDs zurück die für den Charakter bei seinem
  /// aktuellen Level fällig sind.
  Future<List<String>> getGrantedSpellIds(Character c) async {
    final features = await getFeaturesForCharacter(c);
    final ids = <String>[];
    for (final f in features) {
      if (f.grantedSpells == null) continue;
      for (final gs in f.grantedSpells!) {
        if (gs.atLevel <= c.level) ids.add(gs.spellId);
      }
    }
    return ids;
  }
}