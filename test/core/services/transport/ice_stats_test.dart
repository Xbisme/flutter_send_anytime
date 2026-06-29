import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/services/transport/ice_stats.dart';

void main() {
  group('isRelaySelected', () {
    IceStatReport pair(
      String id, {
      required String state,
      bool nominated = false,
      String local = 'lc',
      String remote = 'rc',
    }) => IceStatReport(
      id: id,
      type: 'candidate-pair',
      values: {
        'state': state,
        'nominated': nominated,
        'localCandidateId': local,
        'remoteCandidateId': remote,
      },
    );

    IceStatReport candidate(String id, String type) => IceStatReport(
      id: id,
      type: 'local-candidate',
      values: {'candidateType': type},
    );

    test('relay local candidate on the selected pair → true', () {
      final reports = [
        pair('p', state: 'succeeded', nominated: true),
        candidate('lc', 'relay'),
        candidate('rc', 'host'),
      ];
      expect(isRelaySelected(reports), isTrue);
    });

    test('relay remote candidate → true', () {
      final reports = [
        pair('p', state: 'succeeded', nominated: true),
        candidate('lc', 'srflx'),
        candidate('rc', 'relay'),
      ];
      expect(isRelaySelected(reports), isTrue);
    });

    test('direct (host/srflx) selected pair → false', () {
      final reports = [
        pair('p', state: 'succeeded', nominated: true),
        candidate('lc', 'host'),
        candidate('rc', 'srflx'),
      ];
      expect(isRelaySelected(reports), isFalse);
    });

    test('falls back to any succeeded pair when none nominated', () {
      final reports = [
        pair('p', state: 'succeeded'),
        candidate('lc', 'relay'),
        candidate('rc', 'host'),
      ];
      expect(isRelaySelected(reports), isTrue);
    });

    test('no succeeded pair → false', () {
      final reports = [
        pair('p', state: 'in-progress', nominated: true),
        candidate('lc', 'relay'),
      ];
      expect(isRelaySelected(reports), isFalse);
    });

    test('empty stats → false', () {
      expect(isRelaySelected(const []), isFalse);
    });
  });
}
