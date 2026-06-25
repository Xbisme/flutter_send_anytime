import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/features/send/domain/models/send_transfer_view.dart';
import 'package:safe_send/features/send/domain/usecases/start_send_usecase.dart';

/// Drives the send progress/complete screens (#004) by projecting the engine's
/// [TransferSnapshot] stream into a [SendTransferView] (Constitution VIII — the
/// engine is the single source of truth). Derives speed/ETA across snapshots.
@injectable
class SendTransferCubit extends AppCubit<SendTransferView> {
  SendTransferCubit(this._startSend);

  final StartSendUseCase _startSend;
  final Stopwatch _stopwatch = Stopwatch();

  StreamSubscription<TransferSnapshot>? _sub;
  int _lastBytes = 0;
  Duration _lastElapsed = Duration.zero;
  double _speed = 0;

  /// Begin sending [sources] over the already-open [transport].
  Future<void> start(List<FileSource> sources, DataTransport transport) async {
    emitLoading();
    _stopwatch
      ..reset()
      ..start();
    _sub = _startSend.snapshots.listen(_onSnapshot);
    // The snapshot stream drives state; the result is awaited for completion.
    await _startSend(sources: sources, transport: transport);
  }

  /// Cancel the in-flight transfer.
  Future<void> cancel() => _startSend.cancel();

  void _onSnapshot(TransferSnapshot snapshot) {
    final elapsed = _stopwatch.elapsed;
    final dtMs = (elapsed - _lastElapsed).inMilliseconds;
    if (dtMs > 0) {
      final deltaBytes = snapshot.progress.overallBytesTransferred - _lastBytes;
      final instant = deltaBytes / (dtMs / 1000.0);
      // Exponential smoothing keeps the readout from jumping.
      _speed = _speed == 0 ? instant : _speed * 0.6 + instant * 0.4;
      _lastBytes = snapshot.progress.overallBytesTransferred;
      _lastElapsed = elapsed;
    }
    final remaining =
        snapshot.progress.overallTotalBytes -
        snapshot.progress.overallBytesTransferred;
    final eta = _speed > 0 && remaining > 0
        ? (remaining / _speed).round()
        : null;

    if (snapshot.phase == TransferPhase.failed && snapshot.failure != null) {
      emitError(snapshot.failure!);
      return;
    }
    emitLoaded(
      SendTransferView.fromSnapshot(
        snapshot,
        speedBytesPerSec: _speed,
        etaSeconds: eta,
        elapsed: elapsed,
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
