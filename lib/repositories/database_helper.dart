// lib/repositories/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // ── Singleton-Pattern ─────────────────────────────────────────────────────
  //
  // _instance ist die einzige Instanz dieser Klasse.
  // Sie ist privat (_) damit niemand von außen eine neue erstellen kann.
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  // Die eigentliche Datenbankverbindung – nullable weil sie erst
  // beim ersten Zugriff geöffnet wird (lazy initialization)
  static Database? _database;

  // Privater Konstruktor – verhindert dass jemand DatabaseHelper() aufruft
  DatabaseHelper._internal();

  // Factory-Konstruktor: gibt immer dieselbe Instanz zurück
  factory DatabaseHelper() => _instance;

  // ── Datenbankzugriff ──────────────────────────────────────────────────────

  // getter für die Datenbank – öffnet sie beim ersten Aufruf
  Future<Database> get database async {
    // Falls bereits geöffnet, direkt zurückgeben; Sonst: öffnen und merken
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Gerätespezifischen Pfad für Datenbankdateien ermitteln
    final documentsDir = await getApplicationDocumentsDirectory();
    final path = join(documentsDir.path, 'dnd_app.db');

    return await openDatabase(
      path,
      version: 7,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  // Wird nur einmal aufgerufen – wenn die Datenbank neu angelegt wird
Future<void> _createTables(Database db, int version) async {
  // ── Charaktere ──────────────────────────────────────────────────────────
  await db.execute('''
    CREATE TABLE characters (
      id                       TEXT PRIMARY KEY,
      name                     TEXT NOT NULL,
      race                     TEXT,
      characterClass           TEXT,
      subclass                 TEXT,
      level                    INTEGER DEFAULT 1,
      background               TEXT,
      alignment                TEXT,
      experiencePoints         INTEGER DEFAULT 0,
      strength                 INTEGER DEFAULT 10,
      dexterity                INTEGER DEFAULT 10,
      constitution             INTEGER DEFAULT 10,
      intelligence             INTEGER DEFAULT 10,
      wisdom                   INTEGER DEFAULT 10,
      charisma                 INTEGER DEFAULT 10,
      maxHitPoints             INTEGER DEFAULT 8,
      currentHitPoints         INTEGER DEFAULT 8,
      temporaryHitPoints       INTEGER DEFAULT 0,
      hitDie                   INTEGER DEFAULT 8,
      usedHitDice              INTEGER DEFAULT 0,
      armorClass               INTEGER DEFAULT 10,
      speed                    REAL DEFAULT 9.0,
      walletInCopper           INTEGER DEFAULT 0,
      notes                    TEXT,
      personalityTraits        TEXT,
      ideals                   TEXT,
      bonds                    TEXT,
      flaws                    TEXT,
      useEdition2024           INTEGER DEFAULT 0,
      skillProficiencies       TEXT,
      skillExpertise           TEXT,
      savingThrowProficiencies TEXT,
      deathSaveSuccesses       INTEGER DEFAULT 0,
      deathSaveFailures        INTEGER DEFAULT 0,
      isStabilized             INTEGER DEFAULT 0,
      spellSlots               TEXT
    )
  ''');

  // ── Zauber ───────────────────────────────────────────────────────────────
  await db.execute('''
    CREATE TABLE spells (
      id                   TEXT PRIMARY KEY,
      name                 TEXT NOT NULL,
      school               TEXT,
      level                INTEGER DEFAULT 0,
      castingTime          TEXT,
      range                TEXT,
      duration             TEXT,
      concentration        INTEGER DEFAULT 0,
      ritual               INTEGER DEFAULT 0,
      componentVerbal      INTEGER DEFAULT 0,
      componentSomatic     INTEGER DEFAULT 0,
      componentMaterial    INTEGER DEFAULT 0,
      materialComponent    TEXT,
      attackRollType       TEXT,
      savingThrowAttribute TEXT,
      damageDice           TEXT,
      damageType           TEXT,
      effectDescription    TEXT,
      atHigherLevels       TEXT,
      classes              TEXT DEFAULT ''
    )
  ''');

  // ── Fähigkeiten ──────────────────────────────────────────────────────────
  await db.execute('''
    CREATE TABLE abilities (
      id                   TEXT PRIMARY KEY,
      name                 TEXT NOT NULL,
      source               TEXT,
      actionType           TEXT,
      maxUses              INTEGER,
      currentUses          INTEGER,
      rechargeOn           TEXT,
      requiresAttackRoll   INTEGER DEFAULT 0,
      savingThrowAttribute TEXT,
      effectDescription    TEXT,
      prerequisite         TEXT
    )
  ''');

  // ── Gegenstände ──────────────────────────────────────────────────────────
  await db.execute('''
    CREATE TABLE items (
      id                   TEXT PRIMARY KEY,
      itemType             TEXT NOT NULL DEFAULT 'base',
      name                 TEXT NOT NULL,
      description          TEXT,
      category             TEXT,
      rarity               TEXT,
      requiresAttunement   INTEGER DEFAULT 0,
      isMagical            INTEGER DEFAULT 0,
      magicBonus           INTEGER DEFAULT 0,
      weight               REAL DEFAULT 0,
      valueInCopper        INTEGER DEFAULT 0,
      weaponCategory       TEXT,
      damageDice           TEXT,
      damageType           TEXT,
      weaponProperties     TEXT,
      rangeNormal          INTEGER DEFAULT 1,
      rangeMax             INTEGER DEFAULT 1,
      versatileDice        TEXT,
      armorClassBonus      INTEGER DEFAULT 0,
      armorType            TEXT,
      minStrength          INTEGER DEFAULT 0,
      maxDexBonusOverride  INTEGER,
      stealthDisadvantage  INTEGER DEFAULT 0
    )
  ''');

  // ── Verknüpfungstabellen ─────────────────────────────────────────────────
  await db.execute('''
    CREATE TABLE character_spells (
      characterId TEXT NOT NULL,
      spellId     TEXT NOT NULL,
      isPrepared  INTEGER DEFAULT 0,
      PRIMARY KEY (characterId, spellId),
      FOREIGN KEY (characterId) REFERENCES characters(id) ON DELETE CASCADE,
      FOREIGN KEY (spellId)     REFERENCES spells(id)     ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE character_abilities (
      characterId TEXT NOT NULL,
      abilityId   TEXT NOT NULL,
      PRIMARY KEY (characterId, abilityId),
      FOREIGN KEY (characterId) REFERENCES characters(id) ON DELETE CASCADE,
      FOREIGN KEY (abilityId)   REFERENCES abilities(id)  ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE character_items (
      characterId TEXT NOT NULL,
      itemId      TEXT NOT NULL,
      quantity    INTEGER DEFAULT 1,
      isEquipped  INTEGER DEFAULT 0,
      isAttuned   INTEGER DEFAULT 0,
      notes       TEXT DEFAULT '',
      PRIMARY KEY (characterId, itemId),
      FOREIGN KEY (characterId) REFERENCES characters(id) ON DELETE CASCADE,
      FOREIGN KEY (itemId)      REFERENCES items(id)      ON DELETE CASCADE
    )
  ''');

  await db.execute('''
    CREATE TABLE character_quick_items (
      id            TEXT PRIMARY KEY,
      characterId   TEXT NOT NULL,
      name          TEXT NOT NULL,
      category      TEXT DEFAULT 'misc',
      notes         TEXT,
      quantity      INTEGER DEFAULT 1,
      weight        REAL DEFAULT 0,
      valueInCopper INTEGER DEFAULT 0,
      FOREIGN KEY (characterId) REFERENCES characters(id) ON DELETE CASCADE
    )
  ''');

  // ── Klassen-Feature-Ressourcen ───────────────────────────────────────────
  await db.execute('''
    CREATE TABLE character_feature_resources (
      characterId  TEXT NOT NULL,
      featureId    TEXT NOT NULL,
      currentUses  INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (characterId, featureId),
      FOREIGN KEY (characterId) REFERENCES characters(id) ON DELETE CASCADE
    )
  ''');

  // ── Klassen-Feature-Wahlen ───────────────────────────────────────────────
  await db.execute('''
    CREATE TABLE character_feature_choices (
      characterId    TEXT NOT NULL,
      featureId      TEXT NOT NULL,
      chosenOptionId TEXT NOT NULL,
      PRIMARY KEY (characterId, featureId),
      FOREIGN KEY (characterId) REFERENCES characters(id) ON DELETE CASCADE
    )
  ''');
}

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  // Kein Migrationssystem – einfach alles löschen und neu anlegen.
  // Bestehende Charaktere gehen dabei verloren.
  final tables = ['character_feature_choices', 'character_feature_resources',
                  'character_quick_items', 'character_items',
                  'character_abilities', 'character_spells',
                  'items', 'abilities', 'spells', 'characters'];
  for (final table in tables) {
    await db.execute('DROP TABLE IF EXISTS $table');
  }
  await _createTables(db, newVersion);
}
}