import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'migrations.dart';

class AppDatabase {
  static Database? _instance;

  static Future<Database> getInstance({String dbName = 'mega.db'}) async {
    if (_instance != null && _instance!.isOpen) {
      return _instance!;
    }
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, dbName);
    _instance = await openDatabase(
      path,
      version: migrations.length,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        for (var i = 0; i < version; i++) {
          await migrations[i](db);
        }
        await db.execute('PRAGMA user_version = $version');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        for (var i = oldVersion; i < newVersion; i++) {
          await migrations[i](db);
        }
        await db.execute('PRAGMA user_version = $newVersion');
      },
    );
    return _instance!;
  }

  static Future<void> close() async {
    if (_instance != null && _instance!.isOpen) {
      await _instance!.close();
      _instance = null;
    }
  }
}
