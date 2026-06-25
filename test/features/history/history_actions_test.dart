import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/features/history/domain/usecases/clear_history_usecase.dart';
import 'package:safe_send/features/history/domain/usecases/delete_record_usecase.dart';
import 'package:safe_send/features/history/domain/usecases/resend_availability_usecase.dart';

class _MockRepo extends Mock implements TransferHistoryRepository {}

void main() {
  late Directory tmp;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('history_actions');
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  TransferRecord sent(List<RecordedFile> files) => TransferRecord(
    id: 's',
    direction: TransferDirection.sent,
    status: TransferRecordStatus.completed,
    pairingMethod: PairingMethod.sixDigitCode,
    fileCount: files.length,
    totalBytes: 0,
    createdAt: DateTime(2026, 6, 25),
    files: files,
  );

  RecordedFile fileAt(String path) {
    File(path).writeAsStringSync('x');
    return RecordedFile(name: path.split('/').last, size: 1, path: path);
  }

  group('ResendAvailabilityUseCase (all-or-nothing, FR-021)', () {
    const useCase = ResendAvailabilityUseCase();

    test('available when every source file still exists', () {
      final record = sent([
        fileAt('${tmp.path}/a.txt'),
        fileAt('${tmp.path}/b.txt'),
      ]);
      expect(useCase.isAvailable(record), isTrue);
      final sources = useCase.toSources(record);
      expect(sources, hasLength(2));
      expect(sources.every((s) => s is DiskFileSource), isTrue);
    });

    test('unavailable when any source file is missing', () {
      final record = sent([
        fileAt('${tmp.path}/a.txt'),
        const RecordedFile(
          name: 'gone.txt',
          size: 1,
          path: '/no/such/gone.txt',
        ),
      ]);
      expect(useCase.isAvailable(record), isFalse);
    });

    test('unavailable when a file has no recorded path', () {
      final record = sent([const RecordedFile(name: 'x', size: 1)]);
      expect(useCase.isAvailable(record), isFalse);
    });
  });

  group('delete / clear use cases forward to the repository', () {
    late _MockRepo repo;
    setUp(() => repo = _MockRepo());

    test('DeleteRecordUseCase calls deleteById', () async {
      when(
        () => repo.deleteById(any()),
      ).thenAnswer((_) async => const Result.success(null));
      await DeleteRecordUseCase(repo).call('abc');
      verify(() => repo.deleteById('abc')).called(1);
    });

    test('ClearHistoryUseCase calls clearAll', () async {
      when(
        () => repo.clearAll(),
      ).thenAnswer((_) async => const Result.success(null));
      await ClearHistoryUseCase(repo).call();
      verify(() => repo.clearAll()).called(1);
    });
  });
}
