import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/history/history_filter.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_history_repository.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/features/history/presentation/history_page.dart';
import 'package:safe_send/features/history/presentation/widgets/history_day_header.dart';
import 'package:safe_send/features/history/presentation/widgets/history_record_row.dart';

import '../../helpers/pump_app.dart';

class _FakeRepo implements TransferHistoryRepository {
  List<TransferRecord> records = const [];

  @override
  Stream<List<TransferRecord>> watch(HistoryFilter filter) =>
      Stream.value(records);

  @override
  Stream<List<TransferRecord>> watchRecent(int limit) => Stream.value(records);

  @override
  Future<Result<void>> record(TransferRecord record) async =>
      const Result.success(null);

  @override
  Future<Result<TransferRecord?>> getById(String id) async =>
      const Result.success(null);

  @override
  Future<Result<void>> deleteById(String id) async =>
      const Result.success(null);

  @override
  Future<Result<void>> clearAll() async => const Result.success(null);
}

TransferRecord _record(
  String id,
  TransferDirection direction,
  DateTime at,
) => TransferRecord(
  id: id,
  direction: direction,
  status: TransferRecordStatus.completed,
  pairingMethod: PairingMethod.sixDigitCode,
  fileCount: 2,
  totalBytes: 2048,
  createdAt: at,
);

void main() {
  late _FakeRepo repo;

  setUp(() async {
    await configureDependencies(const AppConfig(flavor: AppFlavor.dev));
    repo = _FakeRepo();
    getIt
      ..unregister<TransferHistoryRepository>()
      ..registerFactory<TransferHistoryRepository>(() => repo);
  });
  tearDown(() async => getIt.reset());

  testWidgets('renders day-grouped, direction-distinguished rows', (
    tester,
  ) async {
    repo.records = [
      _record('a', TransferDirection.sent, DateTime(2026, 6, 25, 16)),
      _record('b', TransferDirection.received, DateTime(2026, 6, 24, 9)),
    ];
    await tester.pumpApp(const HistoryPage(), locale: const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.byType(HistoryRecordRow), findsNWidgets(2));
    expect(find.byType(HistoryDayHeader), findsNWidgets(2));
    // Generic direction labels for empty peerLabel.
    expect(find.text('Recipient'), findsOneWidget); // sent
    expect(find.text('Sender'), findsOneWidget); // received
  });

  testWidgets('shows the never-had-history empty state when no records', (
    tester,
  ) async {
    repo.records = const [];
    await tester.pumpApp(const HistoryPage(), locale: const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('No transfers yet'), findsOneWidget);
    expect(find.byType(HistoryRecordRow), findsNothing);
  });
}
