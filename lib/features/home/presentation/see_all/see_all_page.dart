import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/presentation/feedback/app_empty_view.dart';
import 'package:safe_send/core/presentation/scaffolding/flow_app_bar.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/file_category.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';
import 'package:safe_send/features/home/presentation/cubit/see_all_cubit.dart';
import 'package:safe_send/features/home/presentation/widgets/home_sections.dart';
import 'package:safe_send/features/home/presentation/widgets/media_grid_item.dart';

/// Full-screen "Xem tất cả" list of every transferred item in one category
/// (#012, US3). Lazy grid/list over the full set; reuses the Home cells.
class SeeAllPage extends StatelessWidget {
  const SeeAllPage({required this.category, super.key});

  final MediaCategory category;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<SeeAllCubit>();
        unawaited(cubit.load(category));
        return cubit;
      },
      child: _SeeAllView(category: category),
    );
  }
}

class _SeeAllView extends StatelessWidget {
  const _SeeAllView({required this.category});

  final MediaCategory category;

  String _title(BuildContext context) {
    final l10n = context.l10n;
    return switch (category) {
      MediaCategory.photos => l10n.homeSeeAllPhotos,
      MediaCategory.videos => l10n.homeSeeAllVideos,
      MediaCategory.files => l10n.homeSeeAllFiles,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FlowAppBar(
              title: _title(context),
              onLeading: () => context.pop(),
              leadingSemanticLabel: MaterialLocalizations.of(
                context,
              ).backButtonTooltip,
            ),
            Expanded(
              child: BlocBuilder<SeeAllCubit, AppState<List<MediaItem>>>(
                builder: (context, state) {
                  return switch (state) {
                    AppLoaded<List<MediaItem>>(:final data) => _Grid(
                      category: category,
                      items: data,
                    ),
                    AppError<List<MediaItem>>() => _Empty(category: category),
                    _ => const Center(child: CircularProgressIndicator()),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.category, required this.items});

  final MediaCategory category;
  final List<MediaItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _Empty(category: category);
    const padding = EdgeInsets.fromLTRB(
      AppSpacing.x5 - 2,
      AppSpacing.x2,
      AppSpacing.x5 - 2,
      AppSpacing.x6,
    );

    switch (category) {
      case MediaCategory.photos:
        return GridView.builder(
          padding: padding,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.x2,
            crossAxisSpacing: AppSpacing.x2,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => MediaPhotoCell(item: items[i]),
        );
      case MediaCategory.videos:
        return GridView.builder(
          padding: padding,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.x3 - 1,
            crossAxisSpacing: AppSpacing.x3 - 1,
            childAspectRatio: 1.55,
          ),
          itemCount: items.length,
          itemBuilder: (_, i) => MediaVideoCell(item: items[i]),
        );
      case MediaCategory.files:
        return ListView.separated(
          padding: padding,
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x2 + 2),
          itemBuilder: (_, i) => MediaFileRow(item: items[i]),
        );
    }
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.category});

  final MediaCategory category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = switch (category) {
      MediaCategory.photos => l10n.homeNoImages,
      MediaCategory.videos => l10n.homeNoVideos,
      MediaCategory.files => l10n.homeNoFiles,
    };
    return AppEmptyView(icon: categoryIcon(category), title: body);
  }
}
