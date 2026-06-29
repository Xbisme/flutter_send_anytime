import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/viewer/viewer_request.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/viewers/presentation/cubit/media_playback_view.dart';
import 'package:safe_send/features/viewers/presentation/cubit/media_player_cubit.dart';
import 'package:safe_send/features/viewers/presentation/widgets/viewer_error_view.dart';
import 'package:safe_send/features/viewers/presentation/widgets/viewer_top_bar.dart';

/// Shared full-screen video/audio player (#013, US2/FR-006). Video shows the
/// frame; audio shows the audio-only layout (FR-007). The cubit disposes the
/// controller on close (FR-008).
class MediaPlayerPage extends StatelessWidget {
  const MediaPlayerPage({required this.request, super.key});

  final ViewerRequest request;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<MediaPlayerCubit>(
      create: (_) {
        final cubit = getIt<MediaPlayerCubit>();
        unawaited(cubit.open(request.path));
        return cubit;
      },
      child: _MediaPlayerScaffold(request: request),
    );
  }
}

class _MediaPlayerScaffold extends StatelessWidget {
  const _MediaPlayerScaffold({required this.request});

  final ViewerRequest request;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            // Only rebuild the surface when the *shape* changes (loading →
            // loaded/error, or aspect/audio-only) — NOT on every position tick,
            // so the video Texture is not re-mounted ~4×/s (jank, FR-018).
            child: BlocBuilder<MediaPlayerCubit, AppState<MediaPlaybackView>>(
              buildWhen: (prev, curr) => _shapeKey(prev) != _shapeKey(curr),
              builder: (context, state) => switch (state) {
                AppError<MediaPlaybackView>() => ViewerErrorView(
                  message: context.l10n.viewerMediaError,
                  path: request.path,
                  dark: true,
                ),
                AppLoaded<MediaPlaybackView>(:final data) => _PlayerBody(
                  view: data,
                ),
                _ => const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ViewerTopBar(
              title: request.name,
              sharePath: request.path,
              dark: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// A stable key for [BlocBuilder.buildWhen]: changes only when the player's
/// visual shape changes (phase, audio-only, aspect ratio) — never on a position
/// tick — so the surface rebuilds rarely and the controls own their own ticks.
String _shapeKey(AppState<MediaPlaybackView> state) => switch (state) {
  AppError<MediaPlaybackView>() => 'error',
  AppLoaded<MediaPlaybackView>(:final data) =>
    'loaded:${data.isAudioOnly}:${data.aspectRatio}',
  _ => 'loading',
};

class _PlayerBody extends StatelessWidget {
  const _PlayerBody({required this.view});

  final MediaPlaybackView view;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<MediaPlayerCubit>().controller;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Built once per shape change (see buildWhen) — the Texture is not
        // re-created on every position tick.
        Expanded(
          child: Center(
            child: view.isAudioOnly || controller == null
                ? _AudioArtwork(name: context.l10n.viewerAudioOnly)
                : AspectRatio(
                    aspectRatio: view.aspectRatio,
                    child: controller.videoView(),
                  ),
          ),
        ),
        // Controls track every tick in their own builder (cheap: icon/slider/
        // labels), without rebuilding the surface above.
        BlocBuilder<MediaPlayerCubit, AppState<MediaPlaybackView>>(
          builder: (context, state) => _TransportControls(
            view: state is AppLoaded<MediaPlaybackView> ? state.data : view,
          ),
        ),
      ],
    );
  }
}

class _AudioArtwork extends StatelessWidget {
  const _AudioArtwork({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.music, size: 64, color: Colors.white70),
        const SizedBox(height: AppSpacing.x3),
        Text(name, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _TransportControls extends StatelessWidget {
  const _TransportControls({required this.view});

  final MediaPlaybackView view;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MediaPlayerCubit>();
    final l10n = context.l10n;
    final total = view.duration;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x2,
        AppSpacing.x4,
        AppSpacing.x6,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Semantics(
                button: true,
                label: view.isPlaying ? l10n.viewerPause : l10n.viewerPlay,
                child: IconButton(
                  iconSize: 34,
                  color: Colors.white,
                  icon: Icon(
                    view.isPlaying ? LucideIcons.pause : LucideIcons.play,
                  ),
                  onPressed: cubit.togglePlay,
                ),
              ),
              Expanded(
                child: Semantics(
                  label: l10n.viewerSeek,
                  child: Slider(
                    value: view.progressFraction,
                    onChanged: total.inMilliseconds <= 0
                        ? null
                        : (f) => cubit.seek(
                            Duration(
                              milliseconds: (f * total.inMilliseconds).round(),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                view.elapsedLabel,
                style: AppTypography.mono(
                  size: 12,
                  color: Colors.white70,
                  weight: FontWeight.w400,
                ),
              ),
              Text(
                view.totalLabel,
                style: AppTypography.mono(
                  size: 12,
                  color: Colors.white70,
                  weight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
