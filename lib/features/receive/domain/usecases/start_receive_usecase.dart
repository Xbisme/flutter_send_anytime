import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/transfer_manifest.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/file/received_files_service.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/core/services/transport/transfer_engine.dart';

/// Drives a receive over an already-open [DataTransport] (#005). Resolves the
/// app-owned destination directory, then runs the engine's
/// `startReceiveOnTransport` (no second handshake). Owns one [TransferEngine]
/// and exposes its [snapshots] so the cubit observes the single source of truth
/// (Constitution VIII).
@injectable
class StartReceiveUseCase {
  StartReceiveUseCase(this._engine, this._files);

  final TransferEngine _engine;
  final ReceivedFilesService _files;

  /// The transfer state-machine stream.
  Stream<TransferSnapshot> get snapshots => _engine.snapshots;

  /// Begin receiving over [transport]; [onManifest] is the accept/reject bridge.
  /// Resolves to the destination-dir failure or the terminal transfer result.
  Future<Result<void>> call({
    required DataTransport transport,
    required Future<bool> Function(TransferManifest) onManifest,
  }) async {
    final dir = await _files.destinationDirectory();
    return dir.fold(
      (directory) => _engine.startReceiveOnTransport(
        transport: transport,
        destinationDir: directory,
        onManifest: onManifest,
      ),
      Result<void>.failure,
    );
  }

  /// Cancel the in-flight receive (honored on both ends).
  Future<void> cancel() => _engine.cancel();

  /// Tear down the engine and its transport.
  Future<void> dispose() => _engine.dispose();
}
