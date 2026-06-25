import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/data/database/app_database.dart';
import 'package:safe_send/core/data/transfer_history_repository_impl.dart';
import 'package:safe_send/core/domain/history/history_filter.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';

void main() {
  late AppDatabase db;
  late TransferHistoryRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TransferHistoryRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  TransferRecord sample({
    String id = 'a',
    TransferDirection direction = TransferDirection.received,
    TransferRecordStatus status = TransferRecordStatus.completed,
  }) {
    return TransferRecord(
      id: id,
      direction: direction,
      status: status,
      pairingMethod: PairingMethod.sixDigitCode,
      peerLabel: 'Người gửi',
      fileCount: 2,
      totalBytes: 300,
      createdAt: DateTime(2026, 6, 25, 9, 30),
      files: const [
        RecordedFile(
          name: 'a.pdf',
          size: 100,
          mimeType: 'application/pdf',
          path: '/q/a.pdf',
        ),
        RecordedFile(name: 'b.jpg', size: 200, included: false),
      ],
    );
  }

  test('record then watch maps rows back to the domain entity', () async {
    final write = await repo.record(sample());
    expect(write, isA<Success<void>>());

    final records = await repo.watch(HistoryFilter.none).first;
    expect(records, hasLength(1));
    final r = records.single;
    expect(r.id, 'a');
    expect(r.direction, TransferDirection.received);
    expect(r.status, TransferRecordStatus.completed);
    expect(r.pairingMethod, PairingMethod.sixDigitCode);
    expect(r.fileCount, 2);
    expect(r.totalBytes, 300);
    expect(r.files.map((f) => f.name), ['a.pdf', 'b.jpg']);
    expect(r.files[0].path, '/q/a.pdf');
    expect(r.files[1].included, isFalse);
    expect(r.includedFiles.map((f) => f.name), ['a.pdf']);
  });

  test('getById returns the mapped record or null', () async {
    await repo.record(sample());
    final found = await repo.getById('a');
    expect(found.fold((r) => r?.id, (_) => 'err'), 'a');
    final missing = await repo.getById('zzz');
    expect(missing.fold((r) => r, (_) => sample()), isNull);
  });

  test('deleteById removes only that record', () async {
    await repo.record(sample());
    await repo.record(sample(id: 'b'));
    await repo.deleteById('a');
    final records = await repo.watch(HistoryFilter.none).first;
    expect(records.map((r) => r.id), ['b']);
  });

  test('clearAll empties history', () async {
    await repo.record(sample());
    await repo.record(sample(id: 'b'));
    await repo.clearAll();
    expect(await repo.watch(HistoryFilter.none).first, isEmpty);
  });

  test('record failure surfaces a Result.failure (duplicate id)', () async {
    await repo.record(sample(id: 'dup'));
    final second = await repo.record(sample(id: 'dup'));
    expect(second, isA<Failure<void>>());
  });
}
