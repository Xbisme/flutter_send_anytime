import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer/transfer_session.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/core/services/transport/transfer_engine.dart';

/// Drives a send over an already-open [DataTransport] (#004). Owns one
/// [TransferEngine] (the transfer state machine) and exposes its [snapshots]
/// stream so the cubit observes the single source of truth (Constitution VIII).
@injectable
class StartSendUseCase {
  StartSendUseCase(this._engine);

  final TransferEngine _engine;

  /// The transfer state-machine stream.
  Stream<TransferSnapshot> get snapshots => _engine.snapshots;

  /// Build the session from [sources] and start sending over [transport].
  Future<Result<void>> call({
    required List<FileSource> sources,
    required DataTransport transport,
  }) => _engine.startSendOnTransport(
    transport: transport,
    session: TransferSession.fromSources(sources),
  );

  /// Cancel the in-flight transfer (honored on both ends).
  Future<void> cancel() => _engine.cancel();

  /// Tear down the engine and its transport.
  Future<void> dispose() => _engine.dispose();
}
