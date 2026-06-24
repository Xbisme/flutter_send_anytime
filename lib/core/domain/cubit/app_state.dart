import 'package:flutter/foundation.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';

/// The mandatory 4-state shape for every cubit (Constitution III):
/// `initial -> loading -> loaded(data) -> error(failure)`.
///
/// Hand-written generic sealed union: freezed does not model generic unions
/// without significant boilerplate, and the four states are fixed, so a sealed
/// class is the simplest immutable representation. Concrete (non-generic)
/// feature states may still use `@freezed`.
@immutable
sealed class AppState<T> {
  const AppState();
}

/// Nothing has happened yet.
final class AppInitial<T> extends AppState<T> {
  const AppInitial();
}

/// Work is in progress.
final class AppLoading<T> extends AppState<T> {
  const AppLoading();
}

/// Work completed successfully with [data].
final class AppLoaded<T> extends AppState<T> {
  const AppLoaded(this.data);

  final T data;
}

/// Work failed with [failure].
final class AppError<T> extends AppState<T> {
  const AppError(this.failure);

  final AppFailure failure;
}
