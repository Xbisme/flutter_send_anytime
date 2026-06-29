import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/services/media/media_controller.dart';
import 'package:safe_send/features/viewers/presentation/cubit/media_playback_view.dart';
import 'package:safe_send/features/viewers/presentation/cubit/media_player_cubit.dart';

/// In-memory [MediaController] — no platform plugin (Principle XII seam).
class _FakeController implements MediaController {
  _FakeController({this.failOnInit = false, this.audio = false});

  final bool failOnInit;
  final bool audio;
  final _ctrl = StreamController<MediaProgress>.broadcast();
  bool disposed = false;
  bool playing = false;

  @override
  Future<void> initialize() async {
    if (failOnInit) throw Exception('decode');
  }

  void emit(MediaProgress p) => _ctrl.add(p);

  @override
  Future<void> play() async {
    playing = true;
    emit(
      const MediaProgress(
        position: Duration(seconds: 1),
        duration: Duration(seconds: 10),
        isPlaying: true,
      ),
    );
  }

  @override
  Future<void> pause() async {
    playing = false;
    emit(
      const MediaProgress(
        position: Duration(seconds: 1),
        duration: Duration(seconds: 10),
        isPlaying: false,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async => emit(
    MediaProgress(
      position: position,
      duration: const Duration(seconds: 10),
      isPlaying: playing,
    ),
  );

  @override
  Future<void> dispose() async {
    disposed = true;
    await _ctrl.close();
  }

  @override
  Stream<MediaProgress> get progress => _ctrl.stream;

  @override
  bool get hasError => false;

  @override
  double get aspectRatio => audio ? 0 : 16 / 9;

  @override
  bool get isAudioOnly => aspectRatio <= 0;

  @override
  Widget videoView() => const SizedBox.shrink();
}

class _FakeFactory implements MediaControllerFactory {
  _FakeFactory(this.controller);
  final _FakeController controller;
  @override
  MediaController create(String path) => controller;
}

void main() {
  group('MediaPlayerCubit', () {
    blocTest<MediaPlayerCubit, AppState<MediaPlaybackView>>(
      'open → loading then loaded after play',
      build: () => MediaPlayerCubit(_FakeFactory(_FakeController())),
      act: (c) => c.open('video.mp4'),
      expect: () => [
        isA<AppLoading<MediaPlaybackView>>(),
        isA<AppLoaded<MediaPlaybackView>>().having(
          (s) => s.data.isPlaying,
          'isPlaying',
          true,
        ),
      ],
    );

    blocTest<MediaPlayerCubit, AppState<MediaPlaybackView>>(
      'audio file → isAudioOnly true',
      build: () => MediaPlayerCubit(_FakeFactory(_FakeController(audio: true))),
      act: (c) => c.open('song.mp3'),
      verify: (c) {
        final state = c.state;
        expect(state, isA<AppLoaded<MediaPlaybackView>>());
        expect((state as AppLoaded<MediaPlaybackView>).data.isAudioOnly, true);
      },
    );

    blocTest<MediaPlayerCubit, AppState<MediaPlaybackView>>(
      'init failure → error',
      build: () =>
          MediaPlayerCubit(_FakeFactory(_FakeController(failOnInit: true))),
      act: (c) => c.open('bad.mp4'),
      expect: () => [
        isA<AppLoading<MediaPlaybackView>>(),
        isA<AppError<MediaPlaybackView>>(),
      ],
    );

    test('close disposes the controller (FR-008)', () async {
      final controller = _FakeController();
      final cubit = MediaPlayerCubit(_FakeFactory(controller));
      await cubit.open('v.mp4');
      await cubit.close();
      expect(controller.disposed, true);
    });

    test('togglePlay pauses when playing', () async {
      final controller = _FakeController();
      final cubit = MediaPlayerCubit(_FakeFactory(controller));
      await cubit.open('v.mp4'); // now playing
      await cubit.togglePlay();
      expect(controller.playing, false);
      await cubit.close();
    });
  });
}
