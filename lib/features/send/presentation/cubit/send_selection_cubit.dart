import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/features/send/domain/models/send_selection.dart';
import 'package:safe_send/features/send/domain/usecases/pick_files_usecase.dart';

/// Owns the file selection for the Send flow (#004). Starts in a loaded-empty
/// state so the (empty) tray renders immediately; `addFiles`/`removeAt`/`clear`
/// mutate it. A picker error surfaces as the error state.
@injectable
class SendSelectionCubit extends AppCubit<SendSelection> {
  SendSelectionCubit(this._pickFiles) {
    emitLoaded(SendSelection.empty());
  }

  final PickFilesUseCase _pickFiles;

  /// The current selection (empty before anything is loaded).
  SendSelection get selection {
    final s = state;
    return s is AppLoaded<SendSelection> ? s.data : SendSelection.empty();
  }

  /// Open the picker and append the chosen files to the selection.
  Future<void> addFiles() async {
    final current = selection;
    final result = await _pickFiles();
    result.fold(
      (picked) => emitLoaded(current.adding(picked)),
      emitError,
    );
  }

  /// Remove the file at [index] from the selection.
  void removeAt(int index) => emitLoaded(selection.removingAt(index));

  /// Reset to an empty selection (used by "Gửi tiếp").
  void clear() => emitLoaded(SendSelection.empty());
}
