import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/services/file/file_picker_service.dart';
import 'package:safe_send/features/send/domain/models/send_selection.dart';
import 'package:safe_send/features/send/domain/usecases/pick_files_usecase.dart';
import 'package:safe_send/features/send/presentation/cubit/send_selection_cubit.dart';

class _FakeSource implements FileSource {
  _FakeSource(this.name, this.size);
  @override
  final String name;
  @override
  final int size;
  @override
  String? get mimeType => null;
  @override
  Stream<List<int>> openRead() => const Stream.empty();
}

class _FakePicker implements FilePickerService {
  Result<List<FileSource>> result = const Result.success(<FileSource>[]);
  @override
  Future<Result<List<FileSource>>> pickFiles() async => result;
}

void main() {
  late _FakePicker picker;

  SendSelectionCubit build() => SendSelectionCubit(PickFilesUseCase(picker));

  setUp(() => picker = _FakePicker());

  test('starts in loaded-empty', () {
    final cubit = build();
    expect(cubit.state, isA<AppLoaded<SendSelection>>());
    expect(cubit.selection.isEmpty, isTrue);
  });

  blocTest<SendSelectionCubit, AppState<SendSelection>>(
    'addFiles appends and recomputes count + total',
    build: build,
    act: (cubit) {
      picker.result = Result.success([
        _FakeSource('a.pdf', 100),
        _FakeSource('b.jpg', 200),
      ]);
      return cubit.addFiles();
    },
    expect: () => [
      isA<AppLoaded<SendSelection>>()
          .having((s) => s.data.count, 'count', 2)
          .having((s) => s.data.totalBytes, 'total', 300),
    ],
  );

  blocTest<SendSelectionCubit, AppState<SendSelection>>(
    'removeAt drops the file and updates totals',
    build: build,
    seed: () => AppLoaded(
      SendSelection(
        files: [_FakeSource('a.pdf', 100), _FakeSource('b.jpg', 200)],
      ),
    ),
    act: (cubit) => cubit.removeAt(0),
    expect: () => [
      isA<AppLoaded<SendSelection>>()
          .having((s) => s.data.count, 'count', 1)
          .having((s) => s.data.totalBytes, 'total', 200),
    ],
  );

  blocTest<SendSelectionCubit, AppState<SendSelection>>(
    'a cancelled pick (empty result) leaves the selection unchanged',
    build: build,
    seed: () => AppLoaded(SendSelection(files: [_FakeSource('a.pdf', 100)])),
    act: (cubit) => cubit.addFiles(),
    expect: () => [
      isA<AppLoaded<SendSelection>>().having((s) => s.data.count, 'count', 1),
    ],
  );

  blocTest<SendSelectionCubit, AppState<SendSelection>>(
    'a picker error surfaces as AppError',
    build: build,
    act: (cubit) {
      picker.result = const Result.failure(AppFailure.unexpected());
      return cubit.addFiles();
    },
    expect: () => [isA<AppError<SendSelection>>()],
  );

  blocTest<SendSelectionCubit, AppState<SendSelection>>(
    'clear resets to empty',
    build: build,
    seed: () => AppLoaded(SendSelection(files: [_FakeSource('a.pdf', 100)])),
    act: (cubit) => cubit.clear(),
    expect: () => [
      isA<AppLoaded<SendSelection>>().having(
        (s) => s.data.isEmpty,
        'empty',
        true,
      ),
    ],
  );
}
