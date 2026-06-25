import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/history/usecases/record_transfer_usecase.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/presentation/transfer/transfer_progress_projector.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/core/utils/app_logger.dart';
import 'package:safe_send/features/send/domain/send_history_mapper.dart';
import 'package:safe_send/features/send/domain/usecases/start_send_usecase.dart';
import 'package:uuid/uuid.dart';

/// Drives the send progress/complete screens (#004) by projecting the engine's
/// [TransferSnapshot] stream into a [TransferView] (Constitution VIII — the
/// engine is the single source of truth). Speed/ETA derive from the shared
/// [TransferProgressProjector]. On a terminal state for a transfer that
/// actually started, it writes one history record (#006, FR-001) — best-effort:
/// a record failure only logs and never changes the transfer outcome.
@injectable
class SendTransferCubit extends AppCubit<TransferView> {
  SendTransferCubit(this._startSend, this._recordTransfer);

  final StartSendUseCase _startSend;
  final RecordTransferUseCase _recordTransfer;
  final TransferProgressProjector _projector = TransferProgressProjector();
  static const _uuid = Uuid();

  StreamSubscription<TransferSnapshot>? _sub;
  List<FileSource> _sources = const [];
  bool _started = false;
  bool _recorded = false;

  /// Begin sending [sources] over the already-open [transport].
  Future<void> start(List<FileSource> sources, DataTransport transport) async {
    emitLoading();
    _sources = sources;
    _projector.start();
    _sub = _startSend.snapshots.listen(_onSnapshot);
    // The snapshot stream drives state; the result is awaited for completion.
    await _startSend(sources: sources, transport: transport);
  }

  /// Cancel the in-flight transfer.
  Future<void> cancel() => _startSend.cancel();

  void _onSnapshot(TransferSnapshot snapshot) {
    final eta = _projector.update(snapshot);
    if (snapshot.phase == TransferPhase.transferring ||
        snapshot.phase == TransferPhase.done) {
      _started = true;
    }
    final view = TransferView.fromSnapshot(
      snapshot,
      speedBytesPerSec: _projector.speedBytesPerSec,
      etaSeconds: eta,
      elapsed: _projector.elapsed,
    );
    if (isTerminalPhase(snapshot.phase)) _maybeRecord(view);
    if (snapshot.phase == TransferPhase.failed && snapshot.failure != null) {
      emitError(snapshot.failure!);
      return;
    }
    emitLoaded(view);
  }

  /// Record exactly one history entry for an agreed-and-started transfer
  /// (FR-001/FR-004). Pairing-stage failures never reach a started state.
  void _maybeRecord(TransferView view) {
    if (!_started || _recorded) return;
    _recorded = true;
    final record = SendHistoryMapper.toRecord(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      sources: _sources,
      view: view,
    );
    unawaited(
      _recordTransfer(record).then(
        (r) => r.fold(
          (_) {},
          (_) => AppLogger.warning('history.record(send) failed'),
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _startSend.dispose();
    return super.close();
  }
}
