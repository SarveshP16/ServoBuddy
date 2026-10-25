import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Keeps copies of picked photos (vehicle pictures, receipts) inside the app's
/// own storage, so they survive the gallery original being deleted.
class ImageStore {
  ImageStore({Future<Directory> Function()? root})
    : _root = root ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() _root;
  final _random = Random();

  /// Copies [source] in and returns the stored file's path.
  Future<String> import(String source, {required String folder}) async {
    final dir = Directory(p.join((await _root()).path, folder));
    await dir.create(recursive: true);
    final ext = p.extension(source).isEmpty ? '.jpg' : p.extension(source);
    final name =
        '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 20)}$ext';
    final copy = await File(source).copy(p.join(dir.path, name));
    return copy.path;
  }

  /// Writes [bytes] in as a new file (a photo coming back from a backup) and
  /// returns its path.
  Future<String> save(
    List<int> bytes, {
    required String folder,
    String extension = '.jpg',
  }) async {
    final dir = Directory(p.join((await _root()).path, folder));
    await dir.create(recursive: true);
    final name =
        '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(1 << 20)}'
        '${extension.isEmpty ? '.jpg' : extension}';
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Best-effort: a missing file is already the desired outcome.
  Future<void> delete(String? path) async {
    if (path == null) return;
    try {
      await File(path).delete();
    } on FileSystemException {
      // Already gone.
    }
  }
}
