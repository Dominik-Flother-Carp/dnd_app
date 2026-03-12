// lib/services/compendium_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:dnd_app/models/item.dart';
import 'package:dnd_app/models/spell.dart';

class CompendiumService {
  // ── Singleton ─────────────────────────────────────────────────────────────

  static final CompendiumService _instance = CompendiumService._internal();
  factory CompendiumService() => _instance;
  CompendiumService._internal();

  // ── State ─────────────────────────────────────────────────────────────────

  List<Item>  _items  = [];
  List<Spell> _spells = [];
  bool _loaded = false;

  List<Item>  get items  => List.unmodifiable(_items);
  List<Spell> get spells => List.unmodifiable(_spells);

  // ── Asset-Pfade ───────────────────────────────────────────────────────────

  static const _itemPaths = [
    'assets/json/compendium_items/weapons/martial.json',
    'assets/json/compendium_items/weapons/simple.json',
    'assets/json/compendium_items/armors/light.json',
    'assets/json/compendium_items/armors/medium.json',
    'assets/json/compendium_items/armors/heavy.json',
    'assets/json/compendium_items/armors/shields.json',
    'assets/json/compendium_items/tools.json',
    'assets/json/compendium_items/consumables.json',
  ];

  static const _spellPaths = [
    'assets/json/spells/spell_0.json',
    'assets/json/spells/spell_1.json',
    'assets/json/spells/spell_2.json',
  ];

  // ── Laden ─────────────────────────────────────────────────────────────────

  Future<void> load() async {
    if (_loaded) return;

    final items  = <Item>[];
    final spells = <Spell>[];

    for (final path in _itemPaths) {
      try {
        final raw  = await rootBundle.loadString(path);
        final list = json.decode(raw) as List<dynamic>;
        for (final map in list) {
          final m = Map<String, dynamic>.from(map as Map);
          // weaponProperties in JSON ist ein Array – für Item.fromMap in String umwandeln
          if (m['weaponProperties'] is List) {
            final props = (m['weaponProperties'] as List).cast<String>();
            m['weaponProperties'] = props.join(',');
          }
          // JSON liefert echte Booleans, SQLite liefert 0/1.
          // Alles auf int normalisieren damit fromMap einheitlich == 1 prüfen kann.
          for (final key in ['requiresAttunement', 'isMagical', 'stealthDisadvantage']) {
            if (m[key] is bool) m[key] = (m[key] as bool) ? 1 : 0;
          }
          final item = Item.fromMap(m);
          // treasure und misc sind QuickItem-Kategorien und
          // gehören nicht ins Kompendium
          if (item.category != ItemCategory.treasure &&
              item.category != ItemCategory.misc) {
            items.add(item);
          }
        }
      } catch (e) {
        // Datei noch nicht vorhanden (z.B. tools.json, consumables.json)
        // wird stillschweigend übersprungen
      }
    }

    for (final path in _spellPaths) {
      try {
        final raw  = await rootBundle.loadString(path);
        final list = json.decode(raw) as List<dynamic>;
        for (final map in list) {
          final m = Map<String, dynamic>.from(map as Map);
          for (final key in ['concentration', 'ritual', 'componentVerbal',
                             'componentSomatic', 'componentMaterial']) {
            if (m[key] is bool) m[key] = (m[key] as bool) ? 1 : 0;
          }
          // classes kommt aus JSON als List<dynamic>, fromMap erwartet String
          if (m['classes'] is List) {
            m['classes'] = (m['classes'] as List).join(',');
          }
          spells.add(Spell.fromMap(m));
        }
      } catch (e) {
        // übersprungen
      }
    }

    // Sortierung: Items nach Name, Zauber nach Grad dann Name
    items.sort((a, b) => a.name.compareTo(b.name));
    spells.sort((a, b) {
      final byLevel = a.level.compareTo(b.level);
      return byLevel != 0 ? byLevel : a.name.compareTo(b.name);
    });

    _items  = items;
    _spells = spells;
    _loaded = true;
  }

  // ── Suche & Filter ────────────────────────────────────────────────────────

  List<Item> searchItems(String query, {ItemCategory? category}) {
    final q = query.toLowerCase().trim();
    return _items.where((item) {
      final matchesQuery = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
      final matchesCategory = category == null || item.category == category;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  List<Spell> searchSpells(String query, {String? className}) {
    final q = query.toLowerCase().trim();
    return _spells.where((spell) {
      final matchesQuery = q.isEmpty ||
          spell.name.toLowerCase().contains(q) ||
          spell.effectDescription.toLowerCase().contains(q);
      final matchesClass = className == null ||
          spell.classes.contains(className);
      return matchesQuery && matchesClass;
    }).toList();
  }
}