import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/presentation/inputs/search_pill.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';
import 'package:safe_send/features/home/presentation/cubit/home_cubit.dart';
import 'package:safe_send/features/home/presentation/widgets/home_sections.dart';

/// Home tab: branded header + (mock) dashboard sections + Send/Receive entries.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<HomeCubit>();
        unawaited(cubit.load());
        return cubit;
      },
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: BlocBuilder<HomeCubit, AppState<HomeDashboard>>(
          builder: (context, state) {
            return switch (state) {
              AppLoaded<HomeDashboard>(:final data) => _Loaded(data: data),
              AppError<HomeDashboard>() => const _Loaded(
                data: null,
                errored: true,
              ),
              _ => const Center(child: CircularProgressIndicator()),
            };
          },
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({required this.data, this.errored = false});

  final HomeDashboard? data;
  final bool errored;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = data;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5 - 2,
        AppSpacing.x2,
        AppSpacing.x5 - 2,
        AppSpacing.x6,
      ),
      children: [
        const _HomeHeader(),
        const SizedBox(height: AppSpacing.x5 + 2),
        SearchPill(hintText: l10n.homeSearchHint),
        const SizedBox(height: AppSpacing.x5 + 2),
        if (d != null) ...[
          HomeHeroCard(summary: d.summary),
          const SizedBox(height: AppSpacing.x5 + 2),
          HomeStatsRow(stats: d.stats),
          const SizedBox(height: AppSpacing.x5 + 2),
          HomeRecentImages(images: d.recentImages),
          const SizedBox(height: AppSpacing.x5 + 2),
          HomeRecentVideos(videos: d.recentVideos),
          const SizedBox(height: AppSpacing.x5 + 2),
          HomeRecentFiles(files: d.recentFiles),
          const SizedBox(height: AppSpacing.x5 + 2),
          HomeRecentTransfers(transfers: d.recentTransfers),
          const SizedBox(height: AppSpacing.x5 + 2),
        ],
        const HomeQuickActions(),
        const SizedBox(height: AppSpacing.x5 + 2),
        const HomeTipCard(),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        SvgPicture.asset('assets/brand/logomark.svg', width: 30, height: 30),
        const SizedBox(width: AppSpacing.x2 + 1),
        Text('Safe Send', style: Theme.of(context).textTheme.titleLarge),
        const Spacer(),
        Semantics(
          button: true,
          label: context.l10n.navSettings,
          child: InkResponse(
            radius: 28,
            onTap: () => context.go(AppRoutes.settings),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.surfaceSunken,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.settings,
                size: 19,
                color: c.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
