import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/repositories/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:dnd_app/models/spell.dart';

class CharacterRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // ── Create ─────────────────────────────────────────────────────────────────

  Future<void> insertCharacter(Character character) async {
    final db = await _dbHelper.database;
    await db.insert(
      'characters',
      character.toMap(),
      // Falls ein Charakter mit derselben ID bereits existiert,
      // wird er komplett ersetzt – praktisch für Updates
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  // Alle Charaktere laden – für die Charakterliste
  Future<List<Character>> getAllCharacters() async {
    final db = await _dbHelper.database;
    final maps = await db.query('characters', orderBy: 'name ASC');
    return maps.map((map) => Character.fromMap(map)).toList();
  }

  // Einen einzelnen Charakter laden – für den Charakterbogen
  Future<Character?> getCharacterById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'characters',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Character.fromMap(maps.first);
  }

  // ── Update ─────────────────────────────────────────────────────────────────

  Future<void> updateCharacter(Character character) async {
    final db = await _dbHelper.database;
    await db.update(
      'characters',
      character.toMap(),
      where: 'id = ?',
      whereArgs: [character.id],
    );
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> deleteCharacter(String id) async {
    final db = await _dbHelper.database;

    // ON DELETE CASCADE räumt automatisch character_spells,
    // character_abilities und character_items auf
    await db.delete(
      'characters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }


  // ── Zauber-Verknüpfungen ───────────────────────────────────────────────────

  // Zauber einem Charakter hinzufügen
  // Zauber in die spells-Tabelle schreiben (INSERT OR IGNORE)
  Future<void> upsertSpell(Spell spell) async {
    final db = await _dbHelper.database;
    await db.insert('spells', spell.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> addSpellToCharacter(
      String characterId, String spellId, {bool isPrepared = false}) async {
    final db = await _dbHelper.database;
    await db.insert(
      'character_spells',
      {
        'characterId': characterId,
        'spellId':     spellId,
        'isPrepared':  isPrepared ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  // Vorbereitungsstatus eines Zaubers ändern
  Future<void> setSpellPrepared(
      String characterId, String spellId, bool isPrepared) async {
    final db = await _dbHelper.database;
    await db.update(
      'character_spells',
      {'isPrepared': isPrepared ? 1 : 0},
      where: 'characterId = ? AND spellId = ?',
      whereArgs: [characterId, spellId],
    );
  }

  // Zauber von einem Charakter entfernen
  Future<void> removeSpellFromCharacter(
      String characterId, String spellId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'character_spells',
      where: 'characterId = ? AND spellId = ?',
      whereArgs: [characterId, spellId],
    );
  }

  // Alle Zauber eines Charakters laden
  Future<List<Map<String, dynamic>>> getSpellsForCharacter(
      String characterId) async {
    final db = await _dbHelper.database;

    // JOIN: Daten aus character_spells und spells zusammenführen
    return await db.rawQuery('''
      SELECT spells.*, character_spells.isPrepared
      FROM spells
      INNER JOIN character_spells
        ON spells.id = character_spells.spellId
      WHERE character_spells.characterId = ?
      ORDER BY spells.level ASC, spells.name ASC
    ''', [characterId]);
  }

  // ── Fähigkeiten-Verknüpfungen ──────────────────────────────────────────────

  Future<void> addAbilityToCharacter(
      String characterId, String abilityId) async {
    final db = await _dbHelper.database;
    await db.insert(
      'character_abilities',
      {'characterId': characterId, 'abilityId': abilityId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeAbilityFromCharacter(
      String characterId, String abilityId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'character_abilities',
      where: 'characterId = ? AND abilityId = ?',
      whereArgs: [characterId, abilityId],
    );
  }

  Future<List<Map<String, dynamic>>> getAbilitiesForCharacter(
      String characterId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT abilities.*
      FROM abilities
      INNER JOIN character_abilities
        ON abilities.id = character_abilities.abilityId
      WHERE character_abilities.characterId = ?
      ORDER BY abilities.name ASC
    ''', [characterId]);
  }

  // ── Item-Verknüpfungen ─────────────────────────────────────────────────────

  Future<void> addItemToCharacter(
      String characterId, String itemId) async {
    final db = await _dbHelper.database;
    await db.insert(
      'character_items',
      {'characterId': characterId, 'itemId': itemId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeItemFromCharacter(
      String characterId, String itemId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'character_items',
      where: 'characterId = ? AND itemId = ?',
      whereArgs: [characterId, itemId],
    );
  }

  Future<List<Map<String, dynamic>>> getItemsForCharacter(
      String characterId) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT items.*
      FROM items
      INNER JOIN character_items
        ON items.id = character_items.itemId
      WHERE character_items.characterId = ?
      ORDER BY items.name ASC
    ''', [characterId]);
  }

  // ── Feature-Ressourcen ─────────────────────────────────────────────────────

  /// Lädt alle aktuellen Nutzungszähler für einen Charakter.
  Future<Map<String, int>> getFeatureUses(String characterId) async {
    final db   = await _dbHelper.database;
    final rows = await db.query(
      'character_feature_resources',
      where:     'characterId = ?',
      whereArgs: [characterId],
    );
    return {
      for (final r in rows) r['featureId'] as String: r['currentUses'] as int,
    };
  }

  /// Setzt den Nutzungszähler eines Features (upsert).
  Future<void> setFeatureUses(
      String characterId, String featureId, int uses) async {
    final db = await _dbHelper.database;
    await db.insert(
      'character_feature_resources',
      {'characterId': characterId, 'featureId': featureId, 'currentUses': uses},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Setzt alle Feature-Ressourcen eines Typs zurück.
  /// [restType] = 'short' setzt kurze UND lange Rast-Ressourcen zurück,
  /// [restType] = 'long'  setzt nur lange Rast-Ressourcen zurück.
  /// Die Logik welche Features betroffen sind liegt im Tab – hier wird nur
  /// der Zähler auf 0 gesetzt (verbraucht = 0 bedeutet alle verfügbar).
  Future<void> resetFeatureUses(
      String characterId, List<String> featureIds) async {
    final db = await _dbHelper.database;
    for (final id in featureIds) {
      await db.insert(
        'character_feature_resources',
        {'characterId': characterId, 'featureId': id, 'currentUses': 0},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // ── Feature-Wahlen ─────────────────────────────────────────────────────────

  /// Gibt die gewählte Option-ID für ein Feature zurück, oder null.
  Future<String?> getFeatureChoice(
      String characterId, String featureId) async {
    final db   = await _dbHelper.database;
    final rows = await db.query(
      'character_feature_choices',
      where:     'characterId = ? AND featureId = ?',
      whereArgs: [characterId, featureId],
      limit:     1,
    );
    if (rows.isEmpty) return null;
    return rows.first['chosenOptionId'] as String;
  }

  /// Speichert die Wahl für ein Feature (upsert).
  Future<void> setFeatureChoice(
      String characterId, String featureId, String optionId) async {
    final db = await _dbHelper.database;
    await db.insert(
      'character_feature_choices',
      {
        'characterId':    characterId,
        'featureId':      featureId,
        'chosenOptionId': optionId,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lädt alle Feature-Wahlen eines Charakters.
  Future<Map<String, String>> getAllFeatureChoices(String characterId) async {
    final db   = await _dbHelper.database;
    final rows = await db.query(
      'character_feature_choices',
      where:     'characterId = ?',
      whereArgs: [characterId],
    );
    return {
      for (final r in rows)
        r['featureId'] as String: r['chosenOptionId'] as String,
    };
  }
}