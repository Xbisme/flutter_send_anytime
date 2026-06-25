import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/presentation/feedback/app_empty_view.dart';
import 'package:safe_send/core/theme/app_dimens.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/history/domain/usecases/clear_history_usecase.dart';
import 'package:safe_send/features/history/presentation/cubit/history_cubit.dart';
import 'package:safe_send/features/history/presentation/cubit/history_view.dart';
import 'package:safe_send/features/history/presentation/history_confirm.dart';
import 'package:safe_send/features/history/presentation/widgets/history_day_header.dart';
import 'package:safe_send/features/history/presentation/widgets/history_filter_bar.dart';
import 'package:safe_send/features/history/presentation/widgets/history_record_row.dart';

/// History tab (#006). A day-grouped, newest-first list of finished transfers
/// with search/filter and an empty state. Per-record actions are layered on in
/// US5.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<HistoryCubit>()..load(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView();

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  final _searchController = TextEditingController();
  TransferDirection? _direction;
  bool _hasDateFilter = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  HistoryCubit get _cubit => context.read<HistoryCubit>();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (range == null) return;
    final to = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
    );
    setState(() => _hasDateFilter = true);
    _cubit.setDateRange(range.start, to);
  }

  void _clearDate() {
    setState(() => _hasDateFilter = false);
    _cubit.setDateRange(null, null);
  }

  Future<void> _clearAll(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await historyConfirm(
      context,
      title: l10n.historyClearConfirmTitle,
      body: l10n.historyClearConfirmBody,
      confirmLabel: l10n.historyClearAll,
    );
    if (!confirmed) return;
    await getIt<ClearHistoryUseCase>().call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x5,
                AppSpacing.x2,
                AppSpacing.x5,
                AppSpacing.x3,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.historyTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  BlocBuilder<HistoryCubit, AppState<HistoryView>>(
                    builder: (context, state) {
                      final hasRecords =
                          state is AppLoaded<HistoryView> &&
                          state.data.sections.isNotEmpty;
                      if (!hasRecords) return const SizedBox.shrink();
                      return IconButton(
                        icon: const Icon(LucideIcons.trash2),
                        tooltip: l10n.historyClearAll,
                        onPressed: () => _clearAll(context),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
              child: HistoryFilterBar(
                controller: _searchController,
                direction: _direction,
                hasDateFilter: _hasDateFilter,
                onQueryChanged: _cubit.setQuery,
                onDirectionChanged: (d) {
                  setState(() => _direction = d);
                  _cubit.setDirection(d);
                },
                onPickDate: _pickDate,
                onClearDate: _clearDate,
              ),
            ),
            const SizedBox(height: AppSpacing.x3),
            Expanded(
              child: BlocBuilder<HistoryCubit, AppState<HistoryView>>(
                builder: (context, state) => switch (state) {
                  AppLoaded<HistoryView>(:final data) when data.isEmpty =>
                    _EmptyState(filterActive: data.filterActive),
                  AppLoaded<HistoryView>(:final data) => _HistoryList(data),
                  AppError<HistoryView>() => const _EmptyState(
                    filterActive: false,
                  ),
                  _ => const Center(child: CircularProgressIndicator()),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList(this.view);

  final HistoryView view;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        0,
        AppSpacing.x5,
        AppSpacing.x6,
      ),
      itemCount: view.sections.length,
      itemBuilder: (context, sectionIndex) {
        final section = view.sections[sectionIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HistoryDayHeader(day: section.day),
            for (final record in section.records) ...[
              HistoryRecordRow(
                record: record,
                onTap: () =>
                    context.push(AppRoutes.historyDetail, extra: record),
              ),
              const SizedBox(height: AppSpacing.x2),
            ],
          ],
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filterActive});

  final bool filterActive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppEmptyView(
      icon: filterActive ? LucideIcons.searchX : LucideIcons.history,
      title: filterActive ? l10n.historyNoResultsTitle : l10n.historyEmptyTitle,
      body: filterActive ? l10n.historyNoResultsBody : l10n.historyEmptyBody,
    );
  }
}
