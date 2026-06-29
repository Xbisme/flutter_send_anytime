import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/domain/history/transfer_record.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/utils/file_category.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';
import 'package:safe_send/features/home/domain/usecases/watch_media_items_usecase.dart';
import 'package:safe_send/features/home/presentation/cubit/see_all_cubit.dart';

class _MockWatchMedia extends Mock implements WatchMediaItemsUseCase {}

TransferRecord get _record => TransferRecord(
  id: 'r',
  direction: TransferDirection.received,
  status: TransferRecordStatus.completed,
  pairingMethod: PairingMethod.sixDigitCode,
  fileCount: 1,
  totalBytes: 1,
  createdAt: DateTime(2026, 6, 20),
);

MediaItem _item(String name) => MediaItem(
  category: MediaCategory.photos,
  name: name,
  sizeLabel: '1 B',
  record: _record,
);

void main() {
  late _MockWatchMedia watch;

  setUp(() {
    watch = _MockWatchMedia();
    registerFallbackValue(MediaCategory.photos);
  });

  SeeAllCubit build() => SeeAllCubit(watch);

  group('SeeAllCubit', () {
    blocTest<SeeAllCubit, AppState<List<MediaItem>>>(
      'emits [loading, loaded] with the category items',
      build: () {
        when(() => watch(any())).thenAnswer(
          (_) => Stream.value([_item('a.jpg'), _item('b.jpg')]),
        );
        return build();
      },
      act: (cubit) => cubit.load(MediaCategory.photos),
      expect: () => [
        isA<AppLoading<List<MediaItem>>>(),
        isA<AppLoaded<List<MediaItem>>>().having(
          (s) => s.data.length,
          'count',
          2,
        ),
      ],
    );

    blocTest<SeeAllCubit, AppState<List<MediaItem>>>(
      'emits loaded empty list when the category has no items',
      build: () {
        when(
          () => watch(any()),
        ).thenAnswer((_) => Stream.value(const <MediaItem>[]));
        return build();
      },
      act: (cubit) => cubit.load(MediaCategory.videos),
      expect: () => [
        isA<AppLoading<List<MediaItem>>>(),
        isA<AppLoaded<List<MediaItem>>>().having(
          (s) => s.data,
          'items',
          isEmpty,
        ),
      ],
    );

    blocTest<SeeAllCubit, AppState<List<MediaItem>>>(
      'emits error when the stream errors',
      build: () {
        when(
          () => watch(any()),
        ).thenAnswer((_) => Stream.error(Exception('x')));
        return build();
      },
      act: (cubit) => cubit.load(MediaCategory.files),
      expect: () => [
        isA<AppLoading<List<MediaItem>>>(),
        isA<AppError<List<MediaItem>>>(),
      ],
    );

    test('live update: each snapshot re-emits loaded', () async {
      final controller = StreamController<List<MediaItem>>();
      when(() => watch(any())).thenAnswer((_) => controller.stream);
      final cubit = build();
      await cubit.load(MediaCategory.photos);
      controller
        ..add([_item('a.jpg')])
        ..add([_item('a.jpg'), _item('b.jpg')]);
      await Future<void>.delayed(Duration.zero);
      expect(
        (cubit.state as AppLoaded<List<MediaItem>>).data.length,
        2,
      );
      await controller.close();
      await cubit.close();
    });
  });
}
