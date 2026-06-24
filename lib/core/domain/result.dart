import 'package:safe_send/core/domain/failures/app_failure.dart';

/// A success-or-failure container returned by every fallible operation.
///
/// Repositories/data sources return [Result]; cubits resolve it via [fold] —
/// never try/catch in the cubit (Constitution V).
sealed class Result<T> {
  const Result();

  /// Build a success result.
  const factory Result.success(T value) = Success<T>;

  /// Build a failure result.
  const factory Result.failure(AppFailure failure) = Failure<T>;

  /// Collapse both branches to a single value.
  R fold<R>(R Function(T value) onSuccess, R Function(AppFailure f) onFailure) {
    final self = this;
    return switch (self) {
      Success<T>(:final value) => onSuccess(value),
      Failure<T>(:final failure) => onFailure(failure),
    };
  }
}

/// Successful [Result].
final class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;
}

/// Failed [Result].
final class Failure<T> extends Result<T> {
  const Failure(this.failure);

  final AppFailure failure;
}
