// lib/repositories/item_repository.dart

import 'package:dnd_app/models/item.dart';
import 'package:dnd_app/models/character_items.dart';
import 'package:dnd_app/repositories/database_helper.dart';

class ItemRepository {
  final _db = DatabaseHelper();

  // ── Gegenstände eines Charakters laden ────────────────────────────────────

  Future<List<CharacterItem>> getItemsForCharacter(String characterId) async {
    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT i.*, ci.quantity, ci.isEquipped, ci.isAttuned, ci.characterId
      FROM items i
      JOIN character_items ci ON i.id = ci.itemId
      WHERE ci.characterId = ?
    ''', [characterId]);

    return results.map((map) {
      final item = Item.fromMap(map);
      return CharacterItem.fromMap(map, item);
    }).toList();
  }

  // ── Gegenstand erstellen und Charakter zuweisen ───────────────────────────

  Future<void> addItemToCharacter(CharacterItem characterItem) async {
    final db = await _db.database;
    await db.insert('items', characterItem.item.toMap());
    await db.insert('character_items', characterItem.toMap());
  }

  // ── Item-Vorlage aktualisieren ────────────────────────────────────────────

  Future<void> updateItem(Item item) async {
    final db = await _db.database;
    await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // ── Charakterspezifischen Zustand aktualisieren ───────────────────────────

  Future<void> updateCharacterItem(CharacterItem characterItem) async {
    final db = await _db.database;
    await db.update(
      'character_items',
      characterItem.toMap(),
      where: 'characterId = ? AND itemId = ?',
      whereArgs: [characterItem.characterId, characterItem.item.id],
    );
  }

  // ── Gegenstand entfernen ──────────────────────────────────────────────────

  Future<void> removeItemFromCharacter(CharacterItem characterItem) async {
    final db = await _db.database;
    await db.delete(
      'character_items',
      where: 'characterId = ? AND itemId = ?',
      whereArgs: [characterItem.characterId, characterItem.item.id],
    );
  }

  // ── Menge aktualisieren, bei 0 entfernen ─────────────────────────────────

  Future<void> updateQuantity(CharacterItem characterItem, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItemFromCharacter(characterItem);
    } else {
      characterItem.quantity = newQuantity;
      await updateCharacterItem(characterItem);
    }
  }
}