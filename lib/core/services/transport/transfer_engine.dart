import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/constants/transfer_constants.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/transfer_manifest.dart';
import 'package:safe_send/core/domain/transfer/transfer_session.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/services/signaling/signaling_channel.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';
import 'package:safe_send/core/services/transport/transfer_protocol.dart';
import 'package:safe_send/core/utils/app_logger.dart';
import 'package:uuid/uuid.dart';

/// Default receiver decision hook: auto-accept (used by tests/in-process).
Future<bool> _autoAccept(TransferManifest manifest) async => true;

/// The transport engine: moves files directly between two peers over an
/// encrypted [DataTransport], driving the single transfer state machine
/// (Constitution VIII). One instance per transfer (`@injectable`) — spent after
/// a terminal phase.
@injectable
class TransferEngine {
  TransferEngine(this._connector, this._config);

  final PeerConnector _connector;
  final AppConfig _config;
  static const _uuid = Uuid();

  final _snapshots = StreamController<TransferSnapshot>.broadcast();

  TransferRole _role = TransferRole.sender;
  TransferPhase _phase = TransferPhase.idle;
  TransferProgress _progress = const TransferProgress();
  List<FileTransferItem> _items = <FileTransferItem>[];
  AppFailure? _failure;

  DataTransport? _transport;
  StreamSubscription<Uint8List>? _controlSub;
  Timer? _stallTimer;
  File? _activePart;
  Directory? _quarantineDir;

  var _terminated = false;
  var _cancelRequested = false;
  var _remoteCancelled = false;
  var _completedBytes = 0;

  /// The single source-of-truth progress stream; closes after a terminal phase.
  Stream<TransferSnapshot> get snapshots => _snapshots.stream;

  /// The latest snapshot.
  TransferSnapshot get current => TransferSnapshot(
    phase: _phase,
    role: _role,
    progress: _progress,
    items: List<FileTransferItem>.unmodifiable(_items),
    failure: _failure,
  );

  // --------------------------------------------------------------- sender ---

  /// Begin sending [session] over [signaling]. Resolves when the session
  /// reaches a terminal phase.
  Future<Result<void>> startSend({
    required TransferSession session,
    required SignalingChannel signaling,
  }) async {
    _role = TransferRole.sender;
    _initSession(session);
    _setPhase(TransferPhase.connecting);

    final transport = await _establish(signaling);
    if (transport == null) return _result();
    return _runSend(transport, session);
  }

  /// Begin sending [session] over an ALREADY-OPEN [transport] produced by the
  /// pairing layer (#004). Adopts the transport and runs the send protocol from
  /// the handshaking phase onward — no second WebRTC handshake. Ownership of the
  /// transport transfers to this engine (it closes it on terminal/dispose).
  Future<Result<void>> startSendOnTransport({
    required DataTransport transport,
    required TransferSession session,
  }) async {
    _role = TransferRole.sender;
    _initSession(session);
    _setPhase(TransferPhase.connecting);
    _adoptTransport(transport);
    return _runSend(transport, session);
  }

  void _initSession(TransferSession session) {
    _items = session.initialItems();
    _progress = TransferProgress(overallTotalBytes: session.totalBytes);
  }

  Future<Result<void>> _runSend(
    DataTransport transport,
    TransferSession session,
  ) async {
    final acceptCompleter = Completer<bool>();
    _controlSub = transport.inbound.listen((raw) {
      final frame = _tryDecode(raw);
      switch (frame) {
        case AcceptFrame():
          if (!acceptCompleter.isCompleted) acceptCompleter.complete(true);
        case RejectFrame():
          if (!acceptCompleter.isCompleted) acceptCompleter.complete(false);
        case CancelFrame():
          _remoteCancelled = true;
        case _:
          break;
      }
    });

    _setPhase(TransferPhase.handshaking);
    transport.setBufferedAmountLowThreshold(TransferConstants.kLowWaterMark);
    if (!await _send(
      transport,
      TransferProtocol.encodeManifest(session.toManifest()),
    )) {
      return _result();
    }

    final bool accepted;
    try {
      accepted = await acceptCompleter.future.timeout(
        TransferConstants.kHandshakeTimeout,
      );
    } on TimeoutException {
      return _terminate(
        TransferPhase.failed,
        const AppFailure.connectionLost(),
      );
    }
    if (_terminated) return _result();
    if (!accepted) {
      return _terminate(
        TransferPhase.failed,
        const AppFailure.transferRejected(),
      );
    }

    _setPhase(TransferPhase.transferring);
    _startStallTimer();
    for (var i = 0; i < session.sources.length; i++) {
      if (await _abortedMidway()) return _result();
      final source = session.sources[i];
      _updateItem(i, status: FileItemStatus.transferring);
      if (!await _send(
        transport,
        TransferProtocol.encodeFileStart(
          index: i,
          name: source.name,
          size: source.size,
        ),
      )) {
        return _result();
      }

      final digestSink = _DigestSink();
      final hashInput = sha256.startChunkedConversion(digestSink);
      var sentForFile = 0;
      try {
        await for (final chunk in source.openRead()) {
          if (await _abortedMidway()) {
            hashInput.close();
            return _result();
          }
          await _awaitBackpressure(transport);
          if (_terminated) return _result();
          if (!await _send(transport, TransferProtocol.encodeChunk(chunk))) {
            hashInput.close();
            return _result();
          }
          hashInput.add(chunk);
          sentForFile += chunk.length;
          _reportProgress(i, sentForFile, source.size);
        }
      } on Object catch (error) {
        hashInput.close();
        // Log the error TYPE only — never the message (it may embed a path).
        AppLogger.error('source read failed (${error.runtimeType})');
        return _terminate(
          TransferPhase.failed,
          const AppFailure.fileReadFailed(),
        );
      }
      hashInput.close();
      final hex = digestSink.value!.toString();
      if (!await _send(
        transport,
        TransferProtocol.encodeFileComplete(index: i, sha256: hex),
      )) {
        return _result();
      }
      _completedBytes += source.size;
      _updateItem(
        i,
        status: FileItemStatus.completed,
        bytesTransferred: source.size,
        sha256: hex,
      );
    }

    if (!await _send(
      transport,
      TransferProtocol.encodeSessionComplete(session.id),
    )) {
      return _result();
    }
    return _terminate(TransferPhase.done);
  }

  // ------------------------------------------------------------- receiver ---

  /// Begin receiving over [signaling], saving accepted files under
  /// [destinationDir]. [onManifest] decides accept/reject (auto-accept default).
  Future<Result<void>> startReceive({
    required SignalingChannel signaling,
    required Directory destinationDir,
    Future<bool> Function(TransferManifest manifest) onManifest = _autoAccept,
  }) async {
    _role = TransferRole.receiver;
    _setPhase(TransferPhase.connecting);

    final transport = await _establish(signaling);
    if (transport == null) return _result();

    _setPhase(TransferPhase.handshaking);
    var currentIndex = -1;
    IOSink? sink;
    _DigestSink? digestSink;
    ByteConversionSink? hashInput;
    var receivedForFile = 0;
    var expectedSize = 0;

    try {
      await for (final raw in transport.inbound) {
        if (_cancelRequested) return _result();
        final ProtocolFrame frame;
        try {
          frame = TransferProtocol.decode(raw);
        } on ProtocolException catch (e) {
          return _terminate(
            TransferPhase.failed,
            AppFailure.unexpected(message: 'protocol:${e.reason}'),
          );
        }

        switch (frame) {
          case ManifestFrame(:final manifest):
            final err = manifest.validationError();
            if (err != null) {
              return _terminate(
                TransferPhase.failed,
                AppFailure.unexpected(message: 'manifest:$err'),
              );
            }
            _adoptManifest(manifest);
            final accepted = await Future(
              () => onManifest(manifest),
            ).catchError((Object _) => false);
            if (!accepted) {
              await _send(
                transport,
                TransferProtocol.encodeReject(manifest.sessionId),
              );
              return _terminate(
                TransferPhase.failed,
                const AppFailure.transferRejected(),
              );
            }
            if (!await _send(
              transport,
              TransferProtocol.encodeAccept(manifest.sessionId),
            )) {
              return _result();
            }
            _setPhase(TransferPhase.transferring);
            _startStallTimer();

          case FileStartFrame(:final index, :final size):
            currentIndex = index;
            receivedForFile = 0;
            expectedSize = size;
            digestSink = _DigestSink();
            hashInput = sha256.startChunkedConversion(digestSink);
            final part = await _newPartFile(destinationDir);
            _activePart = part;
            sink = part.openWrite();
            _updateItem(index, status: FileItemStatus.transferring);

          case ChunkFrame(:final bytes):
            if (sink == null || hashInput == null) {
              return _terminate(
                TransferPhase.failed,
                const AppFailure.unexpected(message: 'protocol:chunkNoStart'),
              );
            }
            try {
              sink.add(bytes);
            } on FileSystemException catch (e) {
              return _terminate(TransferPhase.failed, _mapWriteError(e));
            }
            hashInput.add(bytes);
            receivedForFile += bytes.length;
            _reportProgress(currentIndex, receivedForFile, expectedSize);

          case FileCompleteFrame(:final index, :final sha256):
            _updateItem(index, status: FileItemStatus.verifying);
            try {
              await sink?.flush();
              await sink?.close();
            } on FileSystemException catch (e) {
              return _terminate(TransferPhase.failed, _mapWriteError(e));
            }
            hashInput?.close();
            final hex = digestSink?.value?.toString();
            if (hex != sha256) {
              await _deleteActivePart();
              return _terminate(
                TransferPhase.failed,
                AppFailure.integrityCheckFailed(fileIndex: index),
              );
            }
            final dest = _resolveCollision(
              destinationDir,
              _items[index].name,
            );
            await _activePart!.rename(dest);
            _activePart = null;
            _completedBytes += expectedSize;
            _updateItem(
              index,
              status: FileItemStatus.completed,
              bytesTransferred: expectedSize,
              finalPath: dest,
              sha256: sha256,
            );
            sink = null;

          case SessionCompleteFrame():
            return _terminate(TransferPhase.done);

          case CancelFrame():
            _remoteCancelled = true;
            await _deleteActivePart();
            return _terminate(
              TransferPhase.cancelled,
              const AppFailure.transferCancelled(),
            );

          case AcceptFrame():
          case RejectFrame():
            break;
        }
      }
    } on Object catch (error) {
      AppLogger.error('receive failed (${error.runtimeType})');
    }
    // Stream ended without a terminal frame → the peer dropped.
    if (!_terminated) {
      return _terminate(
        TransferPhase.failed,
        const AppFailure.connectionLost(),
      );
    }
    return _result();
  }

  // ------------------------------------------------------------- control ---

  /// Cancel an in-progress transfer from this side. Idempotent.
  Future<void> cancel() async {
    if (_terminated) return;
    _cancelRequested = true;
    final transport = _transport;
    if (transport != null) {
      await _send(
        transport,
        TransferProtocol.encodeCancel(
          sessionId: _sessionId,
          origin: _role.name,
        ),
      );
    }
    await _deleteActivePart();
    await _terminate(
      TransferPhase.cancelled,
      const AppFailure.transferCancelled(),
    );
  }

  /// Tear down all resources. Called automatically on terminal phases.
  Future<void> dispose() => _disposeInternal();

  // --------------------------------------------------------------- helpers ---

  String _sessionId = '';

  Future<DataTransport?> _establish(SignalingChannel signaling) async {
    final result = await _connector.connect(
      role: _role,
      signaling: signaling,
      iceServers: _config.iceServers,
      timeout: TransferConstants.kConnectTimeout,
    );
    return result.fold(
      (transport) {
        _adoptTransport(transport);
        return transport;
      },
      (failure) {
        unawaited(_terminate(TransferPhase.failed, failure));
        return null;
      },
    );
  }

  /// Take ownership of [transport]: store it and tear down on its close.
  void _adoptTransport(DataTransport transport) {
    _transport = transport;
    unawaited(
      transport.closed.then((_) {
        if (!_terminated) {
          unawaited(
            _terminate(
              TransferPhase.failed,
              const AppFailure.connectionLost(),
            ),
          );
        }
      }),
    );
  }

  Future<bool> _send(DataTransport transport, Uint8List frame) async {
    try {
      await transport.send(frame);
      return true;
    } on Object catch (error) {
      AppLogger.error('data-channel send failed (${error.runtimeType})');
      if (!_terminated) {
        await _terminate(
          TransferPhase.failed,
          const AppFailure.dataChannelClosed(),
        );
      }
      return false;
    }
  }

  Future<void> _awaitBackpressure(DataTransport transport) async {
    while (transport.bufferedAmount > TransferConstants.kHighWaterMark) {
      if (_terminated || _cancelRequested || _remoteCancelled) return;
      try {
        await transport.onBufferedAmountLow.first.timeout(
          const Duration(milliseconds: 50),
          onTimeout: () {},
        );
      } on Object {
        return;
      }
    }
  }

  Future<bool> _abortedMidway() async {
    if (_cancelRequested) {
      await _terminate(
        TransferPhase.cancelled,
        const AppFailure.transferCancelled(),
      );
      return true;
    }
    if (_remoteCancelled) {
      await _deleteActivePart();
      await _terminate(
        TransferPhase.cancelled,
        const AppFailure.transferCancelled(),
      );
      return true;
    }
    return _terminated;
  }

  ProtocolFrame? _tryDecode(Uint8List raw) {
    try {
      return TransferProtocol.decode(raw);
    } on ProtocolException {
      return null;
    }
  }

  void _adoptManifest(TransferManifest manifest) {
    _sessionId = manifest.sessionId;
    _items = [
      for (final f in manifest.files)
        FileTransferItem(
          index: f.index,
          name: f.name,
          size: f.size,
          mimeType: f.mime,
        ),
    ];
    _progress = TransferProgress(overallTotalBytes: manifest.totalBytes);
  }

  void _reportProgress(int index, int fileBytes, int fileTotal) {
    _progress = TransferProgress(
      overallBytesTransferred: _completedBytes + fileBytes,
      overallTotalBytes: _progress.overallTotalBytes,
      currentFileIndex: index,
      currentFileBytesTransferred: fileBytes,
      currentFileTotalBytes: fileTotal,
    );
    if (index >= 0 && index < _items.length) {
      _items[index] = _items[index].copyWith(bytesTransferred: fileBytes);
    }
    _resetStallTimer();
    _emit();
  }

  void _updateItem(
    int index, {
    FileItemStatus? status,
    int? bytesTransferred,
    String? sha256,
    String? finalPath,
  }) {
    if (index < 0 || index >= _items.length) return;
    _items[index] = _items[index].copyWith(
      status: status ?? _items[index].status,
      bytesTransferred: bytesTransferred ?? _items[index].bytesTransferred,
      sha256: sha256 ?? _items[index].sha256,
      finalPath: finalPath ?? _items[index].finalPath,
    );
    _emit();
  }

  void _setPhase(TransferPhase phase) {
    _phase = phase;
    _emit();
  }

  void _emit() {
    if (!_snapshots.isClosed) _snapshots.add(current);
  }

  void _startStallTimer() => _resetStallTimer();

  void _resetStallTimer() {
    _stallTimer?.cancel();
    _stallTimer = Timer(TransferConstants.kStallTimeout, () {
      if (!_terminated) {
        unawaited(
          _terminate(TransferPhase.failed, const AppFailure.connectionLost()),
        );
      }
    });
  }

  Future<File> _newPartFile(Directory destinationDir) async {
    final quarantine = Directory(
      '${destinationDir.path}/${TransferConstants.kQuarantineDirName}',
    );
    await quarantine.create(recursive: true);
    _quarantineDir = quarantine;
    return File('${quarantine.path}/${_uuid.v4()}.part');
  }

  String _resolveCollision(Directory dir, String name) {
    final base = dir.path;
    if (!File('$base/$name').existsSync()) return '$base/$name';
    final dot = name.lastIndexOf('.');
    final stem = dot > 0 ? name.substring(0, dot) : name;
    final ext = dot > 0 ? name.substring(dot) : '';
    var n = 1;
    while (File('$base/$stem ($n)$ext').existsSync()) {
      n++;
    }
    return '$base/$stem ($n)$ext';
  }

  AppFailure _mapWriteError(FileSystemException e) {
    final code = e.osError?.errorCode;
    // ENOSPC (no space) is 28 on both Linux and Darwin.
    if (code == 28) return const AppFailure.storageFull();
    return const AppFailure.fileWriteFailed();
  }

  Future<void> _deleteActivePart() async {
    final part = _activePart;
    if (part == null) return;
    try {
      if (part.existsSync()) await part.delete();
    } on Object {
      // best effort
    }
    _activePart = null;
  }

  Future<void> _cleanupQuarantine() async {
    final dir = _quarantineDir;
    if (dir == null) return;
    try {
      if (dir.existsSync() && dir.listSync().isEmpty) await dir.delete();
    } on Object {
      // best effort
    }
  }

  Future<Result<void>> _terminate(
    TransferPhase phase, [
    AppFailure? failure,
  ]) async {
    if (_terminated) return _result();
    _terminated = true;
    _failure = failure;
    _phase = phase;
    _emit();
    await _disposeInternal();
    if (!_snapshots.isClosed) await _snapshots.close();
    return failure == null
        ? const Result.success(null)
        : Result.failure(failure);
  }

  Result<void> _result() =>
      _failure == null ? const Result.success(null) : Result.failure(_failure!);

  Future<void> _disposeInternal() async {
    _stallTimer?.cancel();
    await _controlSub?.cancel();
    await _deleteActivePart();
    await _cleanupQuarantine();
    await _transport?.close();
    _transport = null;
  }
}

/// Captures the final [Digest] from a chunked SHA-256 conversion.
class _DigestSink implements Sink<Digest> {
  Digest? value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
