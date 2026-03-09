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
        id                  TEXT PRIMARY KEY,
        name                TEXT NOT NULL,
        race                TEXT,
        characterClass      TEXT,
        subclass            TEXT,
        level               INTEGER DEFAULT 1,
        background          TEXT,
        alignment           TEXT,
        experiencePoints    INTEGER DEFAULT 0,
        strength            INTEGER DEFAULT 10,
        dexterity           INTEGER DEFAULT 10,
        constitution        INTEGER DEFAULT 10,
        intelligence        INTEGER DEFAULT 10,
        wisdom              INTEGER DEFAULT 10,
        charisma            INTEGER DEFAULT 10,
        maxHitPoints        INTEGER DEFAULT 8,
        currentHitPoints    INTEGER DEFAULT 8,
        temporaryHitPoints  INTEGER DEFAULT 0,
        hitDie              INTEGER DEFAULT 8,
        usedHitDice         INTEGER DEFAULT 0,
        armorClass          INTEGER DEFAULT 10,
        speed               INTEGER DEFAULT 9,
        goldPieces          INTEGER DEFAULT 0,
        silverPieces        INTEGER DEFAULT 0,
        copperPieces        INTEGER DEFAULT 0,
        electrumPieces      INTEGER DEFAULT 0,
        platinumPieces      INTEGER DEFAULT 0,
        notes               TEXT,
        personalityTraits   TEXT,
        ideals              TEXT,
        bonds               TEXT,
        flaws               TEXT,
        useEdition2024      INTEGER DEFAULT 0,
        skillProficiencies       TEXT,
        skillExpertise           TEXT,
        savingThrowProficiencies TEXT,
        deathSaveSuccesses  INTEGER DEFAULT 0,
        deathSaveFailures   INTEGER DEFAULT 0,
        isStabilized        INTEGER DEFAULT 0,
        spellSlots          TEXT
      )
    ''');

    // ── Zauber ───────────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE spells (
        id                    TEXT PRIMARY KEY,
        name                  TEXT NOT NULL,
        isCustom              INTEGER DEFAULT 0,
        creatorId             TEXT,
        school                TEXT,
        level                 INTEGER DEFAULT 0,
        castingTime           TEXT,
        range                 TEXT,
        duration              TEXT,
        concentration         INTEGER DEFAULT 0,
        ritual                INTEGER DEFAULT 0,
        componentVerbal       INTEGER DEFAULT 0,
        componentSomatic      INTEGER DEFAULT 0,
        componentMaterial     INTEGER DEFAULT 0,
        materialComponent     TEXT,
        attackRollType        TEXT,
        savingThrowAttribute  TEXT,
        damageDice            TEXT,
        damageType            TEXT,
        effectDescription     TEXT,
        atHigherLevels        TEXT
      )
    ''');

    // ── Fähigkeiten ──────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE abilities (
        id                    TEXT PRIMARY KEY,
        name                  TEXT NOT NULL,
        isCustom              INTEGER DEFAULT 0,
        creatorId             TEXT,
        source                TEXT,
        actionType            TEXT,
        maxUses               INTEGER,
        currentUses           INTEGER,
        rechargeOn            TEXT,
        requiresAttackRoll    INTEGER DEFAULT 0,
        savingThrowAttribute  TEXT,
        effectDescription     TEXT,
        prerequisite          TEXT
      )
    ''');

    // ── Gegenstände ──────────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE items (
        id                  TEXT PRIMARY KEY,
        name                TEXT NOT NULL,
        description         TEXT,
        isCustom            INTEGER DEFAULT 0,
        creatorId           TEXT,
        category            TEXT,
        rarity              TEXT,
        requiresAttunement  INTEGER DEFAULT 0,
        isAttuned           INTEGER DEFAULT 0,
        weight              REAL DEFAULT 0,
        quantity            INTEGER DEFAULT 1,
        isEquipped          INTEGER DEFAULT 0,
        damageDice          TEXT,
        damageType          TEXT,
        isMagical           INTEGER DEFAULT 0,
        magicBonus          INTEGER DEFAULT 0,
        armorClassBonus     INTEGER DEFAULT 0,
        valueInCopper       INTEGER DEFAULT 0
      )
    ''');

    // ── Verknüpfungstabellen ─────────────────────────────────────────────────
    // Ein Charakter kann viele Zauber haben, ein Zauber kann vielen
    // Charakteren gehören → many-to-many Beziehung

    await db.execute('''
      CREATE TABLE character_spells (
        characterId   TEXT NOT NULL,
        spellId       TEXT NOT NULL,
        isPrepared    INTEGER DEFAULT 0,
        PRIMARY KEY (characterId, spellId),
        FOREIGN KEY (characterId) REFERENCES characters(id) ON DELETE CASCADE,
        FOREIGN KEY (spellId)     REFERENCES spells(id)     ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE character_abilities (
        characterId   TEXT NOT NULL,
        abilityId     TEXT NOT NULL,
        PRIMARY KEY (characterId, abilityId),
        FOREIGN KEY (characterId) REFERENCES characters(id) ON DELETE CASCADE,
        FOREIGN KEY (abilityId)   REFERENCES abilities(id)  ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE character_items (
        characterId   TEXT NOT NULL,
        itemId        TEXT NOT NULL,
        PRIMARY KEY (characterId, itemId),
        FOREIGN KEY (characterId) REFERENCES characters(id) ON DELETE CASCADE,
        FOREIGN KEY (itemId)      REFERENCES items(id)      ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE characters ADD COLUMN useEdition2024 INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE characters ADD COLUMN skillProficiencies TEXT',
      );
      await db.execute('ALTER TABLE characters ADD COLUMN skillExpertise TEXT');
      await db.execute(
        'ALTER TABLE characters ADD COLUMN savingThrowProficiencies TEXT',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE characters ADD COLUMN usedHitDice INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 5) {
      await db.execute(
        'ALTER TABLE characters ADD COLUMN deathSaveSuccesses INTEGER DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE characters ADD COLUMN deathSaveFailures INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE characters ADD COLUMN isStabilized INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 7) {
      await db.execute('ALTER TABLE characters ADD COLUMN spellSlots TEXT');
    }
  }
}
