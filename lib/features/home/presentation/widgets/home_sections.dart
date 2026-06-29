import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/domain/pairing/receive_entry_request.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/presentation/tiles/quick_action_card.dart';
import 'package:safe_send/core/presentation/tiles/stat_tile.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/file_category.dart';
import 'package:safe_send/core/utils/formatters.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/home/domain/models/home_dashboard.dart';
import 'package:safe_send/features/home/presentation/widgets/media_grid_item.dart';

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x3 + 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (onSeeAll != null)
            Semantics(
              button: true,
              child: InkWell(
                onTap: onSeeAll,
                child: Text(
                  context.l10n.homeSeeAll,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: c.accent),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionEmpty extends StatelessWidget {
  const _SectionEmpty(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: c.textMuted),
      ),
    );
  }
}

/// Hero summary card with sent/received totals + progress.
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({required this.summary, super.key});
  final TransferSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const onGrad = AppColors.onAccentDark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: const BoxDecoration(
        gradient: AppColors.gradientBrand,
        borderRadius: AppRadii.heroRadius,
        boxShadow: AppShadow.accentGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HeroStat(
                icon: LucideIcons.arrowUpRight,
                label: l10n.homeSent,
                value: Formatters.bytes(summary.sentBytes),
              ),
              _HeroStat(
                icon: LucideIcons.arrowDownLeft,
                label: l10n.homeReceived,
                value: Formatters.bytes(summary.receivedBytes),
                alignEnd: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          ClipRRect(
            borderRadius: AppRadii.pillRadius,
            child: LinearProgressIndicator(
              value: summary.progressFraction,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.4),
              valueColor: const AlwaysStoppedAnimation(onGrad),
            ),
          ),
          const SizedBox(height: AppSpacing.x2 + 1),
          Text(
            l10n.homeMonthlyTransfers(summary.monthlyTransferCount),
            style: const TextStyle(
              color: onGrad,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.icon,
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.onAccentDark;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (!alignEnd) ...[Icon(icon, size: 15, color: color)],
            if (!alignEnd) const SizedBox(width: AppSpacing.x1 + 3),
            Text(
              label,
              style: const TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            if (alignEnd) const SizedBox(width: AppSpacing.x1 + 3),
            if (alignEnd) Icon(icon, size: 15, color: color),
          ],
        ),
        const SizedBox(height: 3),
        Text(value, style: AppTypography.mono(size: 26, color: color)),
      ],
    );
  }
}

/// Three stat tiles row.
class HomeStatsRow extends StatelessWidget {
  const HomeStatsRow({required this.stats, super.key});
  final List<StatTileModel> stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final s in stats) ...[
          Expanded(
            child: StatTile(
              icon: categoryIcon(s.category),
              count: Formatters.count(s.count),
              label: categoryLabel(context, s.category),
              tint: categoryTint(s.category),
            ),
          ),
          if (s != stats.last) const SizedBox(width: AppSpacing.x3 - 1),
        ],
      ],
    );
  }
}

/// Lucide icon for a media category (shared by stats + empty fallbacks).
IconData categoryIcon(MediaCategory category) => switch (category) {
  MediaCategory.photos => LucideIcons.image,
  MediaCategory.videos => LucideIcons.video,
  MediaCategory.files => LucideIcons.file,
};

/// Design-token tint for a media category (Constitution VI — no hardcoded hex
/// at call sites).
Color categoryTint(MediaCategory category) => switch (category) {
  MediaCategory.photos => AppColors.info,
  MediaCategory.videos => AppColors.teal500,
  MediaCategory.files => AppColors.warning,
};

/// Localized label for a media category.
String categoryLabel(BuildContext context, MediaCategory category) {
  final l10n = context.l10n;
  return switch (category) {
    MediaCategory.photos => l10n.homeStatPhotos,
    MediaCategory.videos => l10n.homeStatVideos,
    MediaCategory.files => l10n.homeStatFiles,
  };
}

/// Recent images grid (3 columns), real data + thumbnails (#012).
class HomeRecentImages extends StatelessWidget {
  const HomeRecentImages({required this.images, this.onSeeAll, super.key});
  final List<MediaItem> images;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          context.l10n.homeRecentImages,
          onSeeAll: images.isEmpty ? null : onSeeAll,
        ),
        if (images.isEmpty)
          _SectionEmpty(context.l10n.homeNoImages)
        else
          GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: AppSpacing.x2,
            crossAxisSpacing: AppSpacing.x2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [for (final im in images) MediaPhotoCell(item: im)],
          ),
      ],
    );
  }
}

/// Recent videos grid (2 columns), real data (#012).
class HomeRecentVideos extends StatelessWidget {
  const HomeRecentVideos({required this.videos, this.onSeeAll, super.key});
  final List<MediaItem> videos;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          context.l10n.homeRecentVideos,
          onSeeAll: videos.isEmpty ? null : onSeeAll,
        ),
        if (videos.isEmpty)
          _SectionEmpty(context.l10n.homeNoVideos)
        else
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.x3 - 1,
            crossAxisSpacing: AppSpacing.x3 - 1,
            childAspectRatio: 1.55,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [for (final v in videos) MediaVideoCell(item: v)],
          ),
      ],
    );
  }
}

/// Recent files list, real data (#012).
class HomeRecentFiles extends StatelessWidget {
  const HomeRecentFiles({required this.files, this.onSeeAll, super.key});
  final List<MediaItem> files;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          context.l10n.homeRecentFiles,
          onSeeAll: files.isEmpty ? null : onSeeAll,
        ),
        if (files.isEmpty)
          _SectionEmpty(context.l10n.homeNoFiles)
        else
          for (final f in files) ...[
            MediaFileRow(item: f),
            if (f != files.last) const SizedBox(height: AppSpacing.x2 + 2),
          ],
      ],
    );
  }
}

/// Recent transfers cards.
class HomeRecentTransfers extends StatelessWidget {
  const HomeRecentTransfers({required this.transfers, super.key});
  final List<TransferGroupModel> transfers;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(context.l10n.homeRecentTransfers),
        if (transfers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x2),
            child: Text(
              context.l10n.homeNoRecent,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: c.textMuted),
            ),
          ),
        for (final t in transfers) ...[
          GestureDetector(
            onTap: t.record == null
                ? null
                : () => context.push(AppRoutes.historyDetail, extra: t.record),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.x4 - 2),
              decoration: BoxDecoration(
                color: c.surfaceCard,
                borderRadius: AppRadii.cardRadius,
                boxShadow: isDark ? AppShadow.softDark : AppShadow.softLight,
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.direction == TransferDirection.sent
                          ? c.accentSubtle
                          : AppColors.info.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      t.direction == TransferDirection.sent
                          ? LucideIcons.arrowUpRight
                          : LucideIcons.arrowDownLeft,
                      size: 17,
                      color: t.direction == TransferDirection.sent
                          ? c.accent
                          : AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x3 - 1),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          t.meta,
                          style: AppTypography.mono(
                            size: 11,
                            color: c.textMuted,
                            weight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    t.time,
                    style: AppTypography.mono(
                      size: 11,
                      color: c.textMuted,
                      weight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (t != transfers.last) const SizedBox(height: AppSpacing.x3),
        ],
      ],
    );
  }
}

/// Quick-actions 2x2 grid. Send/Receive entry points (FR-007/010/011).
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.x3 + 1),
          child: Text(
            l10n.homeQuickActions,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        GridView(
          // A fixed per-card height (width-independent) so the cards never
          // overflow as the screen width — and therefore an aspect-ratio'd
          // height — changes across devices.
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.x3,
            crossAxisSpacing: AppSpacing.x3,
            mainAxisExtent: 114,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            QuickActionCard(
              icon: LucideIcons.qrCode,
              label: l10n.homeActionScanQr,
              subtitle: l10n.homeActionScanQrSub,
              gradient: AppColors.gradientInfo,
              // Lands the receiver straight on the QR scanner (#007, FR-019).
              onTap: () => context.push(
                AppRoutes.receive,
                extra: const ReceiveEntryRequest(openScanner: true),
              ),
            ),
            QuickActionCard(
              icon: LucideIcons.radar,
              label: l10n.homeActionNearby,
              subtitle: l10n.homeActionNearbySub,
              gradient: AppColors.gradientTeal,
              // Lands the receiver straight on the "Gần đây" radar tab (#009).
              onTap: () => context.push(
                AppRoutes.receive,
                extra: const ReceiveEntryRequest(openNearby: true),
              ),
            ),
            QuickActionCard(
              icon: LucideIcons.send,
              label: l10n.homeActionSend,
              subtitle: l10n.homeActionSendSub,
              gradient: AppColors.gradientBrand,
              onTap: () => context.push(AppRoutes.send),
            ),
            QuickActionCard(
              icon: LucideIcons.download,
              label: l10n.homeActionReceive,
              subtitle: l10n.homeActionReceiveSub,
              gradient: AppColors.gradientBrandVivid,
              onTap: () => context.push(AppRoutes.receive),
            ),
          ],
        ),
      ],
    );
  }
}

/// Dismissible-style tip card (static in #001).
class HomeTipCard extends StatelessWidget {
  const HomeTipCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4 - 1),
      decoration: BoxDecoration(
        color: c.accentSubtle,
        borderRadius: AppRadii.cardRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.surfaceCard,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(LucideIcons.lightbulb, size: 18, color: c.accent),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.homeTipTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.homeTipBody,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
