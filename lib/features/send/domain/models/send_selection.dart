import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';

part 'send_selection.freezed.dart';

/// The set of files the user has assembled to send (#004). Immutable; the
/// `loaded` payload of `SendSelectionCubit`. Each entry is a streamable
/// [FileSource] (name/size/mime live on it); duplicates by name are allowed
/// (the engine resolves collisions on the receiving side).
@freezed
abstract class SendSelection with _$SendSelection {
  const factory SendSelection({
    @Default(<FileSource>[]) List<FileSource> files,
  }) = _SendSelection;

  const SendSelection._();

  /// An empty selection (the starting state).
  factory SendSelection.empty() => const SendSelection();

  /// Number of selected files.
  int get count => files.length;

  /// Combined size across all files in bytes.
  int get totalBytes => files.fold(0, (sum, f) => sum + f.size);

  /// Whether nothing is selected (gates the "Tiếp tục" CTA).
  bool get isEmpty => files.isEmpty;

  /// The sources handed to pairing then the transfer engine.
  List<FileSource> toSources() => files;

  /// A new selection with [more] appended.
  SendSelection adding(List<FileSource> more) =>
      SendSelection(files: [...files, ...more]);

  /// A new selection with the file at [index] removed (no-op if out of range).
  SendSelection removingAt(int index) {
    if (index < 0 || index >= files.length) return this;
    return SendSelection(files: [...files]..removeAt(index));
  }
}
