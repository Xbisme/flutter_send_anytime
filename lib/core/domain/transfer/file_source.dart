import 'dart:io';

/// A reference to a file the engine can stream from, decoupling the transport
/// engine from any file-picker UI (#004). The path is never exposed in logs.
abstract interface class FileSource {
  /// Display file name (basename only; no directory component).
  String get name;

  /// Total size in bytes (`>= 0`; 0 is allowed).
  int get size;

  /// Best-effort content type, or null if unknown.
  String? get mimeType;

  /// Streamed read of the file contents; MUST NOT load the whole file at once.
  Stream<List<int>> openRead();
}

/// A [FileSource] backed by an on-disk file path.
class DiskFileSource implements FileSource {
  DiskFileSource(String path, {this.mimeType})
    : _file = File(path),
      name = _basename(path),
      size = File(path).existsSync() ? File(path).lengthSync() : 0;

  final File _file;

  @override
  final String name;

  @override
  final int size;

  @override
  final String? mimeType;

  @override
  Stream<List<int>> openRead() => _file.openRead();

  static String _basename(String path) {
    final normalized = path.replaceAll(r'\', '/');
    final segments = normalized.split('/').where((s) => s.isNotEmpty).toList();
    return segments.isEmpty ? path : segments.last;
  }
}
