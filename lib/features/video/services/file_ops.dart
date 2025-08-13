import 'file_ops_stub.dart' if (dart.library.io) 'file_ops_io.dart' as impl;

Future<bool> deleteFilePath(String path) => impl.deleteFilePath(path);

