import 'package:sqflite/sqflite.dart';
import '../domain/speed_test_record.dart';

class SpeedTestRepository {
  final Database db;

  SpeedTestRepository({required this.db});

  Future<int> insertTest(SpeedTestRecord record) async {
    return await db.insert('speed_tests', record.toMap());
  }

  Future<List<SpeedTestRecord>> getHistory({int limit = 50}) async {
    final rows = await db.query(
      'speed_tests',
      orderBy: 'ts DESC',
      limit: limit,
    );
    return rows.map((r) => SpeedTestRecord.fromMap(r)).toList();
  }

  Future<SpeedTestRecord?> getLatest() async {
    final rows = await db.query(
      'speed_tests',
      orderBy: 'ts DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SpeedTestRecord.fromMap(rows.first);
  }
}
