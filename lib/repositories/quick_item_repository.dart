// lib/repositories/quick_item_repository.dart

import 'package:dnd_app/models/quick_item.dart';
import 'package:dnd_app/repositories/database_helper.dart';
import 'package:sqflite/sqflite.dart';

class QuickItemRepository {
  final _db = DatabaseHelper();

  // ── Laden ─────────────────────────────────────────────────────────────────

  Future<List<QuickItem>> getQuickItemsForCharacter(String characterId) async {
    final db = await _db.database;
    final results = await db.query(
      'character_quick_items',
      where:   'characterId = ?',
      whereArgs: [characterId],
      orderBy: 'name ASC',
    );
    return results.map(QuickItem.fromMap).toList();
  }

  // ── Erstellen ─────────────────────────────────────────────────────────────

  Future<void> insertQuickItem(QuickItem item) async {
    final db = await _db.database;
    await db.insert(
      'character_quick_items',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Aktualisieren ─────────────────────────────────────────────────────────

  Future<void> updateQuickItem(QuickItem item) async {
    final db = await _db.database;
    await db.update(
      'character_quick_items',
      item.toMap(),
      where:     'id = ?',
      whereArgs: [item.id],
    );
  }

  // ── Menge aktualisieren, bei 0 entfernen ─────────────────────────────────

  Future<void> updateQuantity(QuickItem item, int newQuantity) async {
    if (newQuantity <= 0) {
      await deleteQuickItem(item.id);
    } else {
      item.quantity = newQuantity;
      await updateQuickItem(item);
    }
  }

  // ── Löschen ───────────────────────────────────────────────────────────────

  Future<void> deleteQuickItem(String id) async {
    final db = await _db.database;
    await db.delete(
      'character_quick_items',
      where:     'id = ?',
      whereArgs: [id],
    );
  }
}