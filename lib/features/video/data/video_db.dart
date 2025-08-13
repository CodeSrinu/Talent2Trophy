import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'local_video_dao.dart';

class VideoDb {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final basePath = await getDatabasesPath();
    final dbPath = p.join(basePath, 'videos.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(LocalVideoDao.createTableSql);
      },
    );
    return _db!;
  }
}

