import 'package:dnd_app/models/character.dart';
import 'package:dnd_app/repositories/database_helper.dart';
import 'package:sqflite/sqflite.dart';

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

    // Schritt 1: Custom Zauber löschen die dieser Charakter erstellt hat
    // und die kein anderer Charakter kennt
    await _deleteOrphanedCustomContent(db, id);

    // Schritt 2: Charakter löschen
    // ON DELETE CASCADE räumt automatisch character_spells,
    // character_abilities und character_items auf
    await db.delete(
      'characters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Löscht custom content dessen Ersteller gelöscht wird
  // und der keinem anderen Charakter mehr zugewiesen ist
  Future<void> _deleteOrphanedCustomContent(dynamic db, String creatorId) async {

    // Alle custom Zauber dieses Erstellers finden
    final customSpells = await db.query(
      'spells',
      where: 'creatorId = ? AND isCustom = 1',
      whereArgs: [creatorId],
    );

    for (final spell in customSpells) {
      final spellId = spell['id'];

      // Prüfen ob noch ein anderer Charakter diesen Zauber kennt
      final otherOwners = await db.query(
        'character_spells',
        where: 'spellId = ? AND characterId != ?',
        whereArgs: [spellId, creatorId],
        limit: 1,
      );

      // Keine anderen Besitzer → Zauber löschen
      if (otherOwners.isEmpty) {
        await db.delete('spells', where: 'id = ?', whereArgs: [spellId]);
      }
    }

    // Dasselbe für custom Fähigkeiten
    final customAbilities = await db.query(
      'abilities',
      where: 'creatorId = ? AND isCustom = 1',
      whereArgs: [creatorId],
    );

    for (final ability in customAbilities) {
      final abilityId = ability['id'];

      final otherOwners = await db.query(
        'character_abilities',
        where: 'abilityId = ? AND characterId != ?',
        whereArgs: [abilityId, creatorId],
        limit: 1,
      );

      if (otherOwners.isEmpty) {
        await db.delete('abilities', where: 'id = ?', whereArgs: [abilityId]);
      }
    }
  }

  // ── Zauber-Verknüpfungen ───────────────────────────────────────────────────

  // Zauber einem Charakter hinzufügen
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
}