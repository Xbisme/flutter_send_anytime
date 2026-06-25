import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/pairing/connect_link.dart';
import 'package:safe_send/core/services/permissions/camera_permission_service.dart';
import 'package:safe_send/features/pairing/presentation/scan/cubit/qr_scan_state.dart';

/// Drives the full-screen QR scanner (#007). Owns permission resolution and the
/// decode→parse→latch logic; the camera controller + lifecycle live in the page
/// so this stays testable without the plugin. On a valid scan it latches and
/// exposes [acceptedCode] for the page to pop with — it never navigates itself
/// (Constitution XI/XIII).
@injectable
class QrScanCubit extends AppCubit<QrScanView> {
  QrScanCubit(this._permission);

  final CameraPermissionService _permission;

  String? _acceptedCode;
  String? _lastInvalidRaw;

  /// The code decoded from the accepted QR, if any (set when [onDetected]
  /// returns [ScanOutcome.accepted]).
  String? get acceptedCode => _acceptedCode;

  QrScanView get _view => switch (state) {
    AppLoaded<QrScanView>(:final data) => data,
    _ => const QrScanView(permission: CameraPermissionStatus.denied),
  };

  /// Resolve the current camera permission (no prompt) on open.
  Future<void> init() async {
    emitLoading();
    emitLoaded(QrScanView(permission: await _permission.status()));
  }

  /// Show the system permission prompt (when still askable).
  Future<void> requestPermission() async {
    emitLoaded(_view.copyWith(permission: await _permission.request()));
  }

  /// Open the OS settings page for a blocked permission (FR-016).
  Future<void> openSettings() => _permission.openSettings();

  /// Toggle the torch (FR-017a). The page mirrors this onto its controller.
  void toggleTorch() => emitLoaded(_view.copyWith(torchOn: !_view.torchOn));

  /// Hand a decoded barcode value to the cubit. Returns:
  /// - [ScanOutcome.accepted] (and sets [acceptedCode]) for a valid Safe Send
  ///   code — exactly once, then latches (FR-014);
  /// - [ScanOutcome.invalid] for a foreign/unparseable QR, debounced so the same
  ///   raw value reports invalid only once (FR-012);
  /// - [ScanOutcome.ignored] when already handled / nothing to do.
  ScanOutcome onDetected(String? raw) {
    final view = _view;
    if (view.handled || raw == null || raw.isEmpty) return ScanOutcome.ignored;
    return ConnectLink.parse(raw).fold(
      (code) {
        _acceptedCode = code;
        emitLoaded(view.copyWith(handled: true));
        return ScanOutcome.accepted;
      },
      (_) {
        if (raw == _lastInvalidRaw) return ScanOutcome.ignored;
        _lastInvalidRaw = raw;
        return ScanOutcome.invalid;
      },
    );
  }
}
