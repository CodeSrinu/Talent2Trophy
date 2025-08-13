import 'package:sqflite/sqlite_api.dart';

import '../domain/local_video.dart';

class LocalVideoDao {
  final Database db;
  LocalVideoDao(this.db);

  static const table = 'videos';

  static const createTableSql = '''
  CREATE TABLE IF NOT EXISTS $table (
    id TEXT PRIMARY KEY,
    sport TEXT NOT NULL,
    drill TEXT,
    title TEXT NOT NULL,
    file_path TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    duration_secs INTEGER,
    notes TEXT,
    analysis_status TEXT,
    analysis_score REAL,
    metrics_json TEXT
  );
  ''';

  Future<void> insert(LocalVideo video) async {
    await db.insert(table, video.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<LocalVideo>> listAll({String? sport}) async {
    final maps = await db.query(
      table,
      where: sport != null ? 'sport = ?' : null,
      whereArgs: sport != null ? [sport] : null,
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => LocalVideo.fromMap(m)).toList();
  }

  Future<void> delete(String id) async {
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTitle(String id, String title) async {
    await db.update(table, {'title': title}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateNotes(String id, String? notes) async {
    await db.update(table, {'notes': notes}, where: 'id = ?', whereArgs: [id]);
  }
}

