import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/usecases/record_transfer_usecase.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/incoming_offer.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/presentation/transfer/transfer_progress_projector.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/core/utils/app_logger.dart';
import 'package:safe_send/features/receive/domain/receive_history_mapper.dart';
import 'package:safe_send/features/receive/domain/usecases/start_receive_usecase.dart';
import 'package:uuid/uuid.dart';

/// Drives the receive progress/complete screens (#005) by projecting the
/// engine's [TransferSnapshot] stream into a [TransferView], and bridging the
/// engine's accept/reject gate: when the manifest arrives the cubit surfaces an
/// `awaitingDecision` view carrying the [IncomingOffer] and resolves the
/// engine's `Future<bool>` on the user's [accept]/[reject] (Constitution VIII).
@injectable
class ReceiveTransferCubit extends AppCubit<TransferView> {
  ReceiveTransferCubit(this._startReceive, this._recordTransfer);

  final StartReceiveUseCase _startReceive;
  final RecordTransferUseCase _recordTransfer;
  final TransferProgressProjector _projector = TransferProgressProjector();
  static const _uuid = Uuid();

  StreamSubscription<TransferSnapshot>? _sub;
  Completer<bool>? _decision;
  IncomingOffer? _offer;
  int? _lastEta;
  PairingMethod _method = PairingMethod.sixDigitCode;
  bool _rejectedByUser = false;
  bool _accepted = false;
  bool _recorded = false;

  /// Whether the most recent terminal failure was the user declining the
  /// transfer (drives Home) vs. a recoverable failure (drives code-entry).
  bool get rejectedByUser => _rejectedByUser;

  /// Begin receiving over [transport]. [senderLabel] is the generic localized
  /// peer label shown at the prompt (resolved by the UI).
  Future<void> start(
    DataTransport transport, {
    required String senderLabel,
    PairingMethod method = PairingMethod.sixDigitCode,
  }) async {
    emitLoading();
    _method = method;
    _projector.start();
    _sub = _startReceive.snapshots.listen(_onSnapshot);
    final result = await _startReceive(
      transport: transport,
      onManifest: (manifest) {
        _offer = IncomingOffer.fromManifest(manifest, senderLabel: senderLabel);
        _decision = Completer<bool>();
        emitLoaded(
          TransferView(
            phase: TransferPhase.handshaking,
            role: TransferRole.receiver,
            fileCount: _offer!.fileCount,
            bytesTotal: _offer!.totalBytes,
            awaitingDecision: true,
            incomingOffer: _offer,
          ),
        );
        return _decision!.future;
      },
    );
    // The dir-resolution failure happens before any snapshot — surface it here.
    result.fold((_) {}, (failure) {
      if (state is! AppError<TransferView>) emitError(failure);
    });
  }

  /// Accept the incoming transfer — the engine begins writing files.
  void accept() {
    _accepted = true;
    _offer = null;
    final decision = _decision;
    if (decision != null && !decision.isCompleted) decision.complete(true);
  }

  /// Reject the incoming transfer — the engine declines and terminates; the flow
  /// then returns Home (FR-009).
  void reject() {
    _rejectedByUser = true;
    _offer = null;
    final decision = _decision;
    if (decision != null && !decision.isCompleted) decision.complete(false);
  }

  /// Cancel an in-progress receive (after a confirm dialog).
  Future<void> cancel() => _startReceive.cancel();

  /// Open a received file in a system viewer.
  Future<Result<void>> openFile(String path) => _startReceive.open(path);

  /// Hand all received files to the system share sheet.
  Future<Result<void>> shareFiles(List<String> paths) =>
      _startReceive.share(paths);

  void _onSnapshot(TransferSnapshot snapshot) {
    _lastEta = _projector.update(snapshot);
    final view = TransferView.fromSnapshot(
      snapshot,
      speedBytesPerSec: _projector.speedBytesPerSec,
      etaSeconds: _lastEta,
      elapsed: _projector.elapsed,
    );
    if (isTerminalPhase(snapshot.phase)) _maybeRecord(view);
    if (snapshot.phase == TransferPhase.failed && snapshot.failure != null) {
      // FR-013a: if some files already arrived + verified (and this wasn't a
      // user reject), keep them and present a partial outcome rather than a bare
      // error. Otherwise surface the recoverable failure.
      if (!_rejectedByUser && view.completedCount > 0) {
        emitLoaded(view);
        return;
      }
      emitError(snapshot.failure!);
      return;
    }
    emitLoaded(view);
  }

  /// Record one history entry for an accepted transfer that reached a terminal
  /// state (FR-001/FR-004). A rejected or never-accepted transfer records
  /// nothing. Best-effort: a record failure only logs.
  void _maybeRecord(TransferView view) {
    if (!_accepted || _recorded) return;
    _recorded = true;
    final record = ReceiveHistoryMapper.toRecord(
      id: _uuid.v4(),
      createdAt: DateTime.now(),
      view: view,
      pairingMethod: _method,
    );
    unawaited(
      _recordTransfer(record).then(
        (r) => r.fold(
          (_) {},
          (_) => AppLogger.warning('history.record(receive) failed'),
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _startReceive.dispose();
    return super.close();
  }
}
