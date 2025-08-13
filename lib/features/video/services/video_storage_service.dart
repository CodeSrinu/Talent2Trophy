import 'dart:io';

import 'package:path_provider/path_provider.dart';

class VideoStorageService {
  // Directory where we store local videos
  Future<Directory> get appVideoDir async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/videos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> reserveFilePath(String fileName) async {
    final dir = await appVideoDir;
    final file = File('${dir.path}/$fileName');
    return file;
  }
}

