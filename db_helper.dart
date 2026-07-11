import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/history_entry.dart';
import '../models/rule_models.dart';
import '../utils/constants.dart';

/// Singleton wrapper around the local SQLite database.
///
/// This is the ONLY place raw SQL lives in the app. Everything else
/// (predictor, screens, services) talks to the database through this
/// helper, which keeps the app fully offline - there is no network
/// client anywhere in the codebase.
class DBHelper {
  DBHelper._internal();
  static final DBHelper instance = DBHelper._internal();

  static const String _dbName = 'kb_predictor.db';

  /// Bump this and add a migration step in [_onUpgrade] whenever the
  /// schema changes. This is the SQLite migration support required by
  /// the spec.
  static const int _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device TEXT NOT NULL,
        browser TEXT NOT NULL,
        minute INTEGER NOT NULL,
        match1 TEXT NOT NULL,
        match2 TEXT NOT NULL,
        match3 TEXT,
        result TEXT NOT NULL,
        score TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE time_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        browser TEXT,
        startMinute INTEGER NOT NULL,
        endMinute INTEGER NOT NULL,
        result TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE device_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device TEXT NOT NULL UNIQUE,
        result TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE streak_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pattern TEXT NOT NULL UNIQUE,
        result TEXT NOT NULL
      )
    ''');

    await _seedDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Example migration pattern for future schema changes:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE history ADD COLUMN note TEXT');
    // }
  }

  Future<void> _seedDefaults(Database db) async {
    final batch = db.batch();
    for (final r in AppConstants.defaultTimeRules()) {
      batch.insert('time_rules', r.toMap()..remove('id'));
    }
    for (final r in AppConstants.defaultBrowserRules()) {
      batch.insert('time_rules', r.toMap()..remove('id'));
    }
    for (final r in AppConstants.defaultDeviceRules()) {
      batch.insert('device_rules', r.toMap()..remove('id'));
    }
    for (final r in AppConstants.defaultStreakRules()) {
      batch.insert('streak_rules', r.toMap()..remove('id'));
    }
    await batch.commit(noResult: true);
  }

  // ---------------------------------------------------------------------
  // History CRUD
  // ---------------------------------------------------------------------

  Future<int> insertHistory(HistoryEntry entry) async {
    final db = await database;
    return db.insert('history', entry.toMap()..remove('id'));
  }

  Future<int> updateHistory(HistoryEntry entry) async {
    final db = await database;
    return db.update('history', entry.toMap(), where: 'id = ?', whereArgs: [entry.id]);
  }

  Future<int> deleteHistory(int id) async {
    final db = await database;
    return db.delete('history', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HistoryEntry>> getAllHistory({String orderBy = 'timestamp DESC'}) async {
    final db = await database;
    final rows = await db.query('history', orderBy: orderBy);
    return rows.map(HistoryEntry.fromMap).toList();
  }

  Future<List<HistoryEntry>> getHistoryByDevice(String device) async {
    final db = await database;
    final rows = await db.query(
      'history',
      where: 'device = ?',
      whereArgs: [device],
      orderBy: 'timestamp DESC',
    );
    return rows.map(HistoryEntry.fromMap).toList();
  }

  Future<List<HistoryEntry>> getHistoryByBrowser(String browser) async {
    final db = await database;
    final rows = await db.query(
      'history',
      where: 'browser = ?',
      whereArgs: [browser],
      orderBy: 'timestamp DESC',
    );
    return rows.map(HistoryEntry.fromMap).toList();
  }

  Future<List<String>> getDistinctDevices() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT DISTINCT device FROM history ORDER BY device');
    return rows.map((r) => r['device'] as String).toList();
  }

  Future<List<String>> getDistinctBrowsers() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT DISTINCT browser FROM history ORDER BY browser');
    return rows.map((r) => r['browser'] as String).toList();
  }

  Future<void> clearAllHistory() async {
    final db = await database;
    await db.delete('history');
  }

  // ---------------------------------------------------------------------
  // Time rules (generic + browser-specific share the same table)
  // ---------------------------------------------------------------------

  Future<List<TimeRule>> getGenericTimeRules() async {
    final db = await database;
    final rows = await db.query('time_rules', where: 'browser IS NULL', orderBy: 'startMinute ASC');
    return rows.map(TimeRule.fromMap).toList();
  }

  Future<List<TimeRule>> getBrowserTimeRules(String browser) async {
    final db = await database;
    final rows = await db.query(
      'time_rules',
      where: 'browser = ?',
      whereArgs: [browser],
      orderBy: 'startMinute ASC',
    );
    return rows.map(TimeRule.fromMap).toList();
  }

  Future<List<TimeRule>> getAllTimeRules() async {
    final db = await database;
    final rows = await db.query('time_rules', orderBy: 'browser, startMinute ASC');
    return rows.map(TimeRule.fromMap).toList();
  }

  Future<int> insertTimeRule(TimeRule rule) async {
    final db = await database;
    return db.insert('time_rules', rule.toMap()..remove('id'));
  }

  Future<int> updateTimeRule(TimeRule rule) async {
    final db = await database;
    return db.update('time_rules', rule.toMap(), where: 'id = ?', whereArgs: [rule.id]);
  }

  Future<int> deleteTimeRule(int id) async {
    final db = await database;
    return db.delete('time_rules', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // Device rules
  // ---------------------------------------------------------------------

  Future<List<DeviceRule>> getAllDeviceRules() async {
    final db = await database;
    final rows = await db.query('device_rules', orderBy: 'device ASC');
    return rows.map(DeviceRule.fromMap).toList();
  }

  Future<DeviceRule?> getDeviceRule(String device) async {
    final db = await database;
    final rows = await db.query('device_rules', where: 'device = ?', whereArgs: [device]);
    if (rows.isEmpty) return null;
    return DeviceRule.fromMap(rows.first);
  }

  Future<int> insertDeviceRule(DeviceRule rule) async {
    final db = await database;
    return db.insert('device_rules', rule.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateDeviceRule(DeviceRule rule) async {
    final db = await database;
    return db.update('device_rules', rule.toMap(), where: 'id = ?', whereArgs: [rule.id]);
  }

  Future<int> deleteDeviceRule(int id) async {
    final db = await database;
    return db.delete('device_rules', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------------------------------------------------------------
  // Streak rules
  // ---------------------------------------------------------------------

  Future<List<StreakRule>> getAllStreakRules() async {
    final db = await database;
    final rows = await db.query('streak_rules', orderBy: 'LENGTH(pattern) DESC');
    return rows.map(StreakRule.fromMap).toList();
  }

  Future<int> insertStreakRule(StreakRule rule) async {
    final db = await database;
    return db.insert('streak_rules', rule.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateStreakRule(StreakRule rule) async {
    final db = await database;
    return db.update('streak_rules', rule.toMap(), where: 'id = ?', whereArgs: [rule.id]);
  }

  Future<int> deleteStreakRule(int id) async {
    final db = await database;
    return db.delete('streak_rules', where: 'id = ?', whereArgs: [id]);
  }

  /// Resets every rule table back to the built-in defaults.
  Future<void> resetRulesToDefault() async {
    final db = await database;
    await db.delete('time_rules');
    await db.delete('device_rules');
    await db.delete('streak_rules');
    await _seedDefaults(db);
  }

  /// Closes the database - used before restoring a backup file.
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  /// Re-opens the database - used after restoring a backup file.
  Future<void> reopen() async {
    await close();
    _db = await _initDb();
  }

  Future<String> getDbPath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, _dbName);
  }
}
