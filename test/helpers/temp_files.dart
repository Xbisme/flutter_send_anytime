import 'dart:io';
import 'dart:typed_data';

/// Create a unique temporary directory for a test (caller deletes it).
Directory createTempDir(String prefix) =>
    Directory.systemTemp.createTempSync('safesend_$prefix');

/// Write a deterministic file of [size] bytes into [dir]; returns its path.
/// Bytes depend on [seed] so different files differ and corruption is testable.
String writeTempFile(Directory dir, String name, int size, {int seed = 0}) {
  final file = File('${dir.path}/$name');
  final bytes = Uint8List(size);
  for (var i = 0; i < size; i++) {
    bytes[i] = (i * 31 + seed * 7 + 13) & 0xFF;
  }
  file.writeAsBytesSync(bytes);
  return file.path;
}

/// Read a file's bytes (for byte-identical assertions).
Uint8List readBytes(String path) => File(path).readAsBytesSync();
