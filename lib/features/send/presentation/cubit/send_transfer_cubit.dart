import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/presentation/transfer/transfer_progress_projector.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/send/domain/usecases/start_send_usecase.dart';

/// Drives the send progress/complete screens (#004) by projecting the engine's
/// [TransferSnapshot] stream into a [TransferView] (Constitution VIII — the
/// engine is the single source of truth). Speed/ETA derive from the shared
/// [TransferProgressProjector].
@injectable
class SendTransferCubit extends AppCubit<TransferView> {
  SendTransferCubit(this._startSend);

  final StartSendUseCase _startSend;
  final TransferProgressProjector _projector = TransferProgressProjector();

  StreamSubscription<TransferSnapshot>? _sub;

  /// Begin sending [sources] over the already-open [transport].
  Future<void> start(List<FileSource> sources, DataTransport transport) async {
    emitLoading();
    _projector.start();
    _sub = _startSend.snapshots.listen(_onSnapshot);
    // The snapshot stream drives state; the result is awaited for completion.
    await _startSend(sources: sources, transport: transport);
  }

  /// Cancel the in-flight transfer.
  Future<void> cancel() => _startSend.cancel();

  void _onSnapshot(TransferSnapshot snapshot) {
    final eta = _projector.update(snapshot);
    if (snapshot.phase == TransferPhase.failed && snapshot.failure != null) {
      emitError(snapshot.failure!);
      return;
    }
    emitLoaded(
      TransferView.fromSnapshot(
        snapshot,
        speedBytesPerSec: _projector.speedBytesPerSec,
        etaSeconds: eta,
        elapsed: _projector.elapsed,
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
