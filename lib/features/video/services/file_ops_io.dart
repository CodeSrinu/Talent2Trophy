import 'dart:io';

Future<bool> deleteFilePath(String path) async {
  try {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
    return true;
  } catch (_) {
    return false;
  }
}

