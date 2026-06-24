import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';

/// Base cubit emitting the mandatory 4-state [AppState] union.
///
/// Feature cubits extend this and call the [emitLoading]/[emitLoaded]/
/// [emitError] helpers instead of constructing states inline.
abstract class AppCubit<T> extends Cubit<AppState<T>> {
  AppCubit() : super(AppInitial<T>());

  /// Transition to the loading state.
  void emitLoading() => emit(AppLoading<T>());

  /// Transition to the loaded state carrying [data].
  void emitLoaded(T data) => emit(AppLoaded<T>(data));

  /// Transition to the error state carrying [failure].
  void emitError(AppFailure failure) => emit(AppError<T>(failure));
}
