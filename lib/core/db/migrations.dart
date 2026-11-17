import 'package:sqflite/sqflite.dart';

typedef Migration = Future<void> Function(Database db);

final List<Migration> migrations = [
  // Version 1
  (Database db) async {
    await db.execute('''
      CREATE TABLE usage_daily (
        day        TEXT PRIMARY KEY,
        mobile_rx  INTEGER NOT NULL DEFAULT 0,
        mobile_tx  INTEGER NOT NULL DEFAULT 0,
        wifi_rx    INTEGER NOT NULL DEFAULT 0,
        wifi_tx    INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE speed_tests (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        ts           INTEGER NOT NULL,
        ping_ms      REAL NOT NULL,
        jitter_ms    REAL NOT NULL,
        down_mbps    REAL NOT NULL,
        up_mbps      REAL NOT NULL,
        network_type TEXT NOT NULL,
        server       TEXT NOT NULL
      );
    ''');

    await db.execute('CREATE INDEX idx_speed_ts ON speed_tests(ts DESC);');
  },

  // Version 2: past bundles history table
  (Database db) async {
    await db.execute('''
      CREATE TABLE bundles (
        id         INTEGER PRIMARY KEY,
        start_ms   INTEGER NOT NULL,
        end_ms     INTEGER NOT NULL,
        size_bytes INTEGER NOT NULL,
        used_bytes INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_bundles_end ON bundles(end_ms DESC);');
  },
];
