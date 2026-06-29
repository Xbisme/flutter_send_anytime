import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/viewer/viewer_request.dart';
import 'package:safe_send/core/services/media/media_controller.dart';
import 'package:safe_send/core/utils/file_viewer.dart';
import 'package:safe_send/features/viewers/presentation/cubit/media_player_cubit.dart';
import 'package:safe_send/features/viewers/presentation/pages/media_player_page.dart';

import '../../helpers/pump_app.dart';

class _FakeController implements MediaController {
  _FakeController({required this.audio});
  final bool audio;
  final _ctrl = StreamController<MediaProgress>.broadcast();

  @override
  Future<void> initialize() async {}
  @override
  Future<void> play() async => _ctrl.add(
    const MediaProgress(
      position: Duration(seconds: 2),
      duration: Duration(seconds: 8),
      isPlaying: true,
    ),
  );
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> dispose() async => _ctrl.close();
  @override
  Stream<MediaProgress> get progress => _ctrl.stream;
  @override
  bool get hasError => false;
  @override
  double get aspectRatio => audio ? 0 : 16 / 9;
  @override
  bool get isAudioOnly => aspectRatio <= 0;
  @override
  Widget videoView() => const ColoredBox(color: Colors.green);
}

class _FakeFactory implements MediaControllerFactory {
  _FakeFactory({required this.audio});
  final bool audio;
  @override
  MediaController create(String path) => _FakeController(audio: audio);
}

void main() {
  void register({required bool audio}) {
    getIt
      ..registerFactory<MediaControllerFactory>(
        () => _FakeFactory(audio: audio),
      )
      ..registerFactory<MediaPlayerCubit>(() => MediaPlayerCubit(getIt()));
  }

  tearDown(() async => getIt.reset());

  ViewerRequest req(ViewerKind kind) =>
      ViewerRequest(path: '/x', name: 'clip', kind: kind);

  testWidgets('video → controls + time labels render', (tester) async {
    register(audio: false);
    await tester.pumpApp(MediaPlayerPage(request: req(ViewerKind.video)));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.pause), findsOneWidget); // playing
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('0:02'), findsOneWidget); // elapsed (mono clock)
    expect(find.text('0:08'), findsOneWidget); // total
  });

  testWidgets('audio → audio-only layout (no video box)', (tester) async {
    register(audio: true);
    await tester.pumpApp(MediaPlayerPage(request: req(ViewerKind.audio)));
    await tester.pumpAndSettle();

    expect(find.byIcon(LucideIcons.music), findsOneWidget);
  });
}
