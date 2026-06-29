import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/presentation/transfer/background_transfer_projector.dart';
import 'package:safe_send/core/services/background/background_transfer_state.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

void main() {
  group('mapBackgroundPhase', () {
    test('maps terminal phases and collapses the rest to transferring', () {
      expect(mapBackgroundPhase(TransferPhase.done), BackgroundPhase.done);
      expect(mapBackgroundPhase(TransferPhase.failed), BackgroundPhase.failed);
      expect(
        mapBackgroundPhase(TransferPhase.cancelled),
        BackgroundPhase.cancelled,
      );
      expect(
        mapBackgroundPhase(TransferPhase.connecting),
        BackgroundPhase.transferring,
      );
      expect(
        mapBackgroundPhase(TransferPhase.transferring),
        BackgroundPhase.transferring,
      );
    });
  });

  group('projectBackgroundTransfer', () {
    late AppLocalizations vi;

    setUp(() async {
      vi = await AppLocalizations.delegate.load(const Locale('vi'));
    });

    TransferView view({
      required TransferPhase phase,
      double progress = 0.64,
      int? eta = 48,
    }) => TransferView(
      phase: phase,
      role: TransferRole.sender,
      overallProgress: progress,
      bytesDone: 153,
      bytesTotal: 240,
      speedBytesPerSec: 2400000,
      etaSeconds: eta,
      fileCount: 18,
    );

    test('send: accent direction, percent, file count, eta present', () {
      final s = projectBackgroundTransfer(
        l10n: vi,
        direction: TransferDirection.sent,
        peerName: 'Minh',
        view: view(phase: TransferPhase.transferring),
      );
      expect(s.direction, TransferDirection.sent);
      expect(s.percent, 64);
      expect(s.phase, BackgroundPhase.transferring);
      expect(s.fileCount, 18);
      expect(s.title, contains('18'));
      expect(s.etaLabel, isNotEmpty);
      expect(s.cancelLabel, isNotEmpty);
    });

    test('receive direction projects the receiving variant', () {
      final s = projectBackgroundTransfer(
        l10n: vi,
        direction: TransferDirection.received,
        peerName: 'Linh',
        view: view(phase: TransferPhase.transferring),
      );
      expect(s.direction, TransferDirection.received);
      expect(s.peerLine, contains('Linh'));
    });

    test('unknown ETA yields an empty eta label', () {
      final s = projectBackgroundTransfer(
        l10n: vi,
        direction: TransferDirection.sent,
        peerName: 'Minh',
        view: view(phase: TransferPhase.transferring, eta: null),
      );
      expect(s.etaLabel, isEmpty);
    });

    test('percent clamps to 0..100', () {
      final s = projectBackgroundTransfer(
        l10n: vi,
        direction: TransferDirection.sent,
        peerName: 'Minh',
        view: view(phase: TransferPhase.transferring, progress: 1.5),
      );
      expect(s.percent, 100);
    });

    test('toContentState carries the keys the iOS widget expects', () {
      final s = projectBackgroundTransfer(
        l10n: vi,
        direction: TransferDirection.sent,
        peerName: 'Minh',
        view: view(phase: TransferPhase.transferring),
      );
      final map = s.toContentState();
      expect(map['direction'], 'send');
      expect(map['percent'], 64);
      expect(map.keys, containsAll(<String>['title', 'peerLine', 'phase']));
    });
  });
}
