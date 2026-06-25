import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/services/permissions/camera_permission_service.dart';

part 'qr_scan_state.freezed.dart';

/// What happened when a barcode was handed to the cubit (#007).
enum ScanOutcome {
  /// A valid Safe Send code was decoded — the caller should pop with it.
  accepted,

  /// A barcode was decoded but it is not a Safe Send code (FR-012).
  invalid,

  /// Nothing actionable — already handled, or a repeat of the last invalid scan.
  ignored,
}

/// The loaded view-model for the QR scanner (#007). Held in the 4-state
/// `AppCubit`; `loading` covers permission resolution / image analysis,
/// `error` is reserved for an unrecoverable scanner failure.
@freezed
abstract class QrScanView with _$QrScanView {
  const factory QrScanView({
    required CameraPermissionStatus permission,

    /// Torch on/off (only meaningful when [permission] is granted).
    @Default(false) bool torchOn,

    /// Latched true once a valid code is accepted, to enforce a single join
    /// (FR-014).
    @Default(false) bool handled,
  }) = _QrScanView;
}
