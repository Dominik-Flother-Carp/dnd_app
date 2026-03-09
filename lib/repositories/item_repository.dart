// lib/repositories/item_repository.dart

import 'package:dnd_app/models/item.dart';
import 'package:dnd_app/repositories/database_helper.dart';

class ItemRepository {
  final DatabaseHelper _db = DatabaseHelper();

  // ── Gegenstände eines Charakters laden ────────────────────────────────────

  Future<List<Item>> getItemsForCharacter(String characterId) async {
    final db = await _db.database;
    final results = await db.rawQuery('''
      SELECT i.*, ci.isEquipped, ci.isAttuned
      FROM items i
      JOIN character_items ci ON i.id = ci.itemId
      WHERE ci.characterId = ?
    ''', [characterId]);
    return results.map((map) => Item.fromMap(map)).toList();
  }

  // ── Gegenstand erstellen und Charakter zuweisen ───────────────────────────

  Future<void> addItemToCharacter(String characterId, Item item) async {
    final db = await _db.database;
    await db.insert('items', item.toMap());
    await db.insert('character_items', {
      'characterId': characterId,
      'itemId':      item.id,
    });
  }

  // ── Gegenstand aktualisieren ──────────────────────────────────────────────

  Future<void> updateItem(Item item) async {
    final db = await _db.database;
    await db.update(
      'items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // ── Gegenstand entfernen ──────────────────────────────────────────────────

  Future<void> removeItemFromCharacter(
      String characterId, String itemId) async {
    final db = await _db.database;
    await db.delete(
      'character_items',
      where: 'characterId = ? AND itemId = ?',
      whereArgs: [characterId, itemId],
    );
    // Gegenstand selbst nur löschen wenn er keinem anderen Charakter gehört
    final remaining = await db.query(
      'character_items',
      where: 'itemId = ?',
      whereArgs: [itemId],
    );
    if (remaining.isEmpty) {
      await db.delete('items', where: 'id = ?', whereArgs: [itemId]);
    }
  }

  // ── Menge aktualisieren, bei 0 entfernen ─────────────────────────────────

  Future<void> updateQuantity(
      String characterId, Item item, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItemFromCharacter(characterId, item.id);
    } else {
      item.quantity = newQuantity;
      await updateItem(item);
    }
  }
}