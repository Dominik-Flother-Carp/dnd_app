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
  // Reihenfolge: erst Basisklasse, dann Unterklassen alphabetisch.
  // Unterklassen ohne Features (nur fluff) können trotzdem eingetragen werden –
  // der Service ignoriert JSON-Dateien ohne 'features'-Array fehlerfrei.
  static const _classPaths = {
    'Barbar': [
      'assets/json/class_features/barbarian/barbarian.json',
      'assets/json/class_features/barbarian/berserker.json',
      'assets/json/class_features/barbarian/totem.json',
    ],
    'Barde': [
      'assets/json/class_features/bard/bard.json',
      'assets/json/class_features/bard/lore.json',
      'assets/json/class_features/bard/valor.json',
    ],
    'Druide': [
      'assets/json/class_features/druid/druid.json',
      'assets/json/class_features/druid/land.json',
      'assets/json/class_features/druid/moon.json',
    ],
    'Hexenmeister': [
      'assets/json/class_features/warlock/warlock.json',
      'assets/json/class_features/warlock/archfey.json',
      'assets/json/class_features/warlock/fiend.json',
      'assets/json/class_features/warlock/great_old_one.json',
    ],
    'Kämpfer': [
      'assets/json/class_features/fighter/fighter.json',
      'assets/json/class_features/fighter/battle_master.json',
      'assets/json/class_features/fighter/champion.json',
      'assets/json/class_features/fighter/eldritch_knight.json',
    ],
    'Kleriker': [
      'assets/json/class_features/cleric/cleric.json',
      'assets/json/class_features/cleric/knowledge.json',
      'assets/json/class_features/cleric/life.json',
      'assets/json/class_features/cleric/light.json',
      'assets/json/class_features/cleric/nature.json',
      'assets/json/class_features/cleric/tempest.json',
      'assets/json/class_features/cleric/trickery.json',
      'assets/json/class_features/cleric/war.json',
    ],
    'Magier': [
      'assets/json/class_features/wizard/wizard.json',
      'assets/json/class_features/wizard/abjuration.json',
      'assets/json/class_features/wizard/conjuration.json',
      'assets/json/class_features/wizard/divination.json',
      'assets/json/class_features/wizard/enchantment.json',
      'assets/json/class_features/wizard/evocation.json',
      'assets/json/class_features/wizard/illusion.json',
      'assets/json/class_features/wizard/necromancy.json',
      'assets/json/class_features/wizard/transmutation.json',
    ],
    'Mönch': [
      'assets/json/class_features/monk/monk.json',
      'assets/json/class_features/monk/elements.json',
      'assets/json/class_features/monk/open_hand.json',
      'assets/json/class_features/monk/shadow.json',
    ],
    'Paladin': [
      'assets/json/class_features/paladin/paladin.json',
      'assets/json/class_features/paladin/ancients.json',
      'assets/json/class_features/paladin/devotion.json',
      'assets/json/class_features/paladin/vengeance.json',
    ],
    'Schurke': [
      'assets/json/class_features/rogue/rogue.json',
      'assets/json/class_features/rogue/arcane_trickster.json',
      'assets/json/class_features/rogue/assassin.json',
      'assets/json/class_features/rogue/thief.json',
    ],
    'Waldläufer': [
      'assets/json/class_features/ranger/ranger.json',
      'assets/json/class_features/ranger/beast_master.json',
      'assets/json/class_features/ranger/hunter.json',
    ],
    'Zauberer': [
      'assets/json/class_features/sorcerer/sorcerer.json',
      'assets/json/class_features/sorcerer/draconic.json',
      'assets/json/class_features/sorcerer/wild_magic.json',
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

        // Fluff speichern – Klasse (kein subclassName) oder Unterklasse
        if (subclassName != null && data['fluff'] != null) {
          _fluffCache['$className/$subclassName'] = data['fluff'] as String;
        } else if (subclassName == null && data['fluff'] != null) {
          _fluffCache[className] = data['fluff'] as String;
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
  /// - Resource-Upgrades werden auf das Basis-Feature angewendet wenn
  ///   ihr unlocksAtLevel <= c.level (höchstes passendes Upgrade gewinnt)
  Future<List<ClassFeature>> getFeaturesForCharacter(Character c) async {
    await loadForClass(c.characterClass);
    final all = _cache[c.characterClass] ?? [];

    // Alle Features die für diesen Charakter relevant sind (Level + Unterklasse)
    final relevant = all.where((f) {
      if (f.unlocksAtLevel > c.level) return false;
      if (f.subclassName == null) return true;
      return f.subclassName == c.subclass;
    }).toList()
      ..sort((a, b) => a.unlocksAtLevel.compareTo(b.unlocksAtLevel));

    // Resource-Upgrades sammeln: upgradesResourceId → höchstes aktives Upgrade
    final upgrades = <String, ClassFeature>{};
    for (final f in relevant) {
      if (f.upgradesResourceId == null || f.resource == null) continue;
      final existing = upgrades[f.upgradesResourceId!];
      if (existing == null ||
          f.unlocksAtLevel > existing.unlocksAtLevel) {
        upgrades[f.upgradesResourceId!] = f;
      }
    }

    // Upgrades auf Basis-Features anwenden, Upgrade-Features aus Liste entfernen
    return relevant
        .where((f) => f.upgradesResourceId == null) // Upgrade-Features ausblenden
        .map((f) {
          final upgrade = upgrades[f.id];
          if (upgrade == null || upgrade.resource == null) return f;
          return f.withResource(upgrade.resource!);
        })
        .toList();
  }

  /// Gibt den Fluff-Text einer Unterklasse zurück, oder null.
  Future<String?> getSubclassFluff(String className, String subclassName) async {
    await loadForClass(className);
    return _fluffCache['$className/$subclassName'];
  }

  /// Gibt den Fluff-Text einer Klasse zurück, oder null.
  Future<String?> getClassFluff(String className) async {
    await loadForClass(className);
    return _fluffCache[className];
  }

  /// Gibt alle `grantedSpells`-IDs zurück die für den Charakter bei seinem
  /// aktuellen Level fällig sind – inklusive Zauber aus gewählten Optionen
  /// (z.B. Terrain-Zauber des Zirkels des Landes).
  Future<List<String>> getGrantedSpellIds(
      Character c, Map<String, String> featureChoices) async {
    final features = await getFeaturesForCharacter(c);
    final ids = <String>[];
    for (final f in features) {
      // Fest zugewiesene Zauber
      if (f.grantedSpells != null) {
        for (final gs in f.grantedSpells!) {
          if (gs.atLevel <= c.level) ids.add(gs.spellId);
        }
      }
      // Zauber aus der gewählten Option (z.B. Terrain-Wahl)
      if (f.choice != null) {
        final chosenId = featureChoices[f.id];
        if (chosenId != null) {
          final option = f.choice!.options
              .where((o) => o.id == chosenId)
              .firstOrNull;
          if (option != null) {
            for (final gs in option.grantedSpells) {
              if (gs.atLevel <= c.level) ids.add(gs.spellId);
            }
          }
        }
      }
    }
    return ids;
  }
}