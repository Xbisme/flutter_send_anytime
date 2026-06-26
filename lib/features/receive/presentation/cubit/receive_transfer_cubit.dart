import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState, WidgetsBinding;
import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/usecases/record_transfer_usecase.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/settings/settings_repository.dart';
import 'package:safe_send/core/domain/transfer/file_transfer_item.dart';
import 'package:safe_send/core/domain/transfer/incoming_offer.dart';
import 'package:safe_send/core/domain/transfer/transfer_state.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/presentation/transfer/transfer_progress_projector.dart';
import 'package:safe_send/core/services/media/gallery_saver_service.dart';
import 'package:safe_send/core/services/notifications/incoming_file_notifier.dart';
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
  ReceiveTransferCubit(
    this._startReceive,
    this._recordTransfer,
    this._settings,
    this._gallerySaver,
    this._notifier,
  );

  final StartReceiveUseCase _startReceive;
  final RecordTransferUseCase _recordTransfer;
  final SettingsRepository _settings;
  final GallerySaverService _gallerySaver;
  final IncomingFileNotifier _notifier;
  final TransferProgressProjector _projector = TransferProgressProjector();
  static const _uuid = Uuid();

  StreamSubscription<TransferSnapshot>? _sub;
  Completer<bool>? _decision;
  IncomingOffer? _offer;
  int? _lastEta;
  PairingMethod _method = PairingMethod.sixDigitCode;
  String _peerLabel = '';
  bool _rejectedByUser = false;
  bool _accepted = false;
  bool _recorded = false;
  bool _savedToLibrary = false;

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
        // Prefer the sender's real device name from the manifest (#010); fall
        // back to the generic localized label when absent (older senders).
        final fromManifest = manifest.senderName?.trim() ?? '';
        _peerLabel = fromManifest.isNotEmpty ? fromManifest : senderLabel;
        _offer = IncomingOffer.fromManifest(manifest, senderLabel: _peerLabel);
        _decision = Completer<bool>();

        final settings = _settings.current;
        // Only read the lifecycle when a preference actually depends on it (the
        // binding is always initialized in the running app; this keeps pure unit
        // tests that don't pump a binding working).
        if (settings.notifications || settings.autoReceive) {
          final lifecycle = WidgetsBinding.instance.lifecycleState;
          final foreground =
              lifecycle == null || lifecycle == AppLifecycleState.resumed;

          // FR-009: notify when a transfer arrives while backgrounded.
          if (settings.notifications && !foreground) {
            unawaited(_notifier.showIncoming(senderName: _peerLabel));
          }

          // FR-007: foreground skip-tap — auto-accept only while the app is
          // foregrounded on the receive screen; otherwise show the prompt.
          if (settings.autoReceive && foreground) {
            _accepted = true;
            _offer = null;
            _decision!.complete(true);
            return _decision!.future;
          }
        }

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
    if (isTerminalPhase(snapshot.phase)) {
      _maybeRecord(view);
      _maybeSaveToLibrary(view);
    }
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
      peerLabel: _peerLabel,
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

  /// Copy completed image/video files into the OS photo library when the user
  /// enabled it (FR-008). Additive over the existing app-sandbox save; best
  /// effort — a save failure only logs and never blocks the flow.
  void _maybeSaveToLibrary(TransferView view) {
    if (!_accepted || _savedToLibrary || !_settings.current.saveToLibrary) {
      return;
    }
    _savedToLibrary = true;
    for (final item in view.items) {
      final path = item.finalPath;
      if (path == null || item.status != FileItemStatus.completed) continue;
      final kind = _mediaKind(item.name, item.mimeType);
      if (kind == null) continue;
      unawaited(
        _gallerySaver
            .saveMedia(path, isVideo: kind == _MediaKind.video)
            .then(
              (r) => r.fold(
                (_) {},
                (_) => AppLogger.warning('gallery.save failed'),
              ),
            ),
      );
    }
  }

  /// Classify a received file as image/video for the library save, by mime then
  /// extension; null = not media (untouched).
  _MediaKind? _mediaKind(String name, String? mime) {
    final m = mime?.toLowerCase() ?? '';
    if (m.startsWith('image/')) return _MediaKind.image;
    if (m.startsWith('video/')) return _MediaKind.video;
    final dot = name.lastIndexOf('.');
    final ext = dot >= 0 ? name.substring(dot + 1).toLowerCase() : '';
    const images = {'jpg', 'jpeg', 'png', 'gif', 'heic', 'webp', 'bmp'};
    const videos = {'mp4', 'mov', 'm4v', 'avi', 'mkv', '3gp'};
    if (images.contains(ext)) return _MediaKind.image;
    if (videos.contains(ext)) return _MediaKind.video;
    return null;
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    await _startReceive.dispose();
    return super.close();
  }
}

enum _MediaKind { image, video }
