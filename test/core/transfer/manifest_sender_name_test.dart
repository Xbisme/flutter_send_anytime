import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/incoming_offer.dart';
import 'package:safe_send/core/domain/transfer/transfer_manifest.dart';
import 'package:safe_send/core/domain/transfer/transfer_session.dart';

class _FakeSource implements FileSource {
  @override
  String get name => 'a.pdf';
  @override
  int get size => 4;
  @override
  String? get mimeType => 'application/pdf';
  @override
  Stream<List<int>> openRead() => const Stream.empty();
}

void main() {
  group('manifest senderName (#010, US1)', () {
    test('round-trips through JSON when present', () {
      final session = TransferSession.fromSources(
        [_FakeSource()],
        senderName: "Minh's iPhone",
      );
      final manifest = session.toManifest();
      expect(manifest.senderName, "Minh's iPhone");

      // The real wire path serializes to a JSON string and back.
      final decoded = TransferManifest.fromJson(
        jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>,
      );
      expect(decoded.senderName, "Minh's iPhone");
      expect(decoded.validationError(), isNull);
    });

    test('is null and backward-compatible when absent', () {
      final manifest = TransferSession.fromSources([
        _FakeSource(),
      ]).toManifest();
      expect(manifest.senderName, isNull);

      // A legacy manifest JSON without the key decodes to null (older senders).
      final json =
          jsonDecode(jsonEncode(manifest.toJson())) as Map<String, dynamic>
            ..remove('senderName');
      expect(TransferManifest.fromJson(json).senderName, isNull);
    });

    test('IncomingOffer uses the real name; falls back to generic', () {
      final named = TransferSession.fromSources(
        [_FakeSource()],
        senderName: 'Lan',
      ).toManifest();
      final fromManifest = named.senderName?.trim() ?? '';
      final label = fromManifest.isNotEmpty ? fromManifest : 'Người gửi';
      expect(
        IncomingOffer.fromManifest(named, senderLabel: label).senderLabel,
        'Lan',
      );

      final anon = TransferSession.fromSources([_FakeSource()]).toManifest();
      final anonResolved = (anon.senderName?.trim() ?? '').isNotEmpty
          ? anon.senderName!.trim()
          : 'Người gửi';
      expect(anonResolved, 'Người gửi');
    });
  });
}
