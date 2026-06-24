import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_failure.freezed.dart';

/// Enumerates known, recoverable failure modes across the app.
///
/// The full peer-to-peer set (signaling/transfer/file failures) is added by
/// later specs; #001 only needs the foundation variants.
@freezed
sealed class AppFailure with _$AppFailure {
  /// An unexpected/unclassified error.
  const factory AppFailure.unexpected({String? message, Object? error}) =
      AppFailureUnexpected;

  /// A feature that is intentionally not implemented yet (placeholder flows).
  const factory AppFailure.notImplemented() = AppFailureNotImplemented;
}
