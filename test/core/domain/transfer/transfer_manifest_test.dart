import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/transfer/transfer_manifest.dart';

TransferManifest manifest({
  int v = 1,
  int fileCount = 1,
  int totalBytes = 5,
  List<ManifestFileEntry> files = const [
    ManifestFileEntry(index: 0, name: 'a.txt', size: 5),
  ],
}) => TransferManifest(
  v: v,
  sessionId: 's',
  fileCount: fileCount,
  totalBytes: totalBytes,
  files: files,
);

void main() {
  test('a well-formed manifest validates', () {
    expect(manifest().validationError(), isNull);
  });

  test('wrong protocol version is rejected', () {
    expect(manifest(v: 2).validationError(), 'version');
  });

  test('file count mismatch is rejected', () {
    expect(manifest(fileCount: 2).validationError(), 'count');
  });

  test('total-bytes mismatch is rejected', () {
    expect(manifest(totalBytes: 999).validationError(), 'totalBytesMismatch');
  });

  test('path-traversal and unsafe names are rejected', () {
    for (final bad in ['../evil.txt', 'a/b.txt', r'a\b.txt', '', '..', '.']) {
      final m = manifest(
        files: [ManifestFileEntry(index: 0, name: bad, size: 5)],
      );
      expect(m.validationError(), 'unsafeName', reason: bad);
    }
  });

  test('JSON round-trips through the wire (jsonEncode/Decode)', () {
    final m = manifest();
    final decoded = jsonDecode(jsonEncode(m.toJson())) as Map<String, dynamic>;
    expect(TransferManifest.fromJson(decoded), m);
  });
}
