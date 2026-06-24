import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/feedback/app_toast.dart';
import 'package:safe_send/core/presentation/inputs/code_box.dart';
import 'package:safe_send/core/presentation/scaffolding/flow_app_bar.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/theme/app_typography.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/pairing/presentation/cubit/pairing_cubit.dart';
import 'package:safe_send/features/pairing/presentation/pairing_failure_l10n.dart';

/// Dev-flavor-only diagnostic surface for the signaling/pairing engine (#003,
/// FR-021a). Lets a tester host or join a 6-digit code and watch the connection
/// lifecycle for the deferred two-physical-device smoke. Never mounted in prod
/// (the router gates this route on `AppConfig.flavor.isDev`).
class PairingDebugPage extends StatelessWidget {
  const PairingDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PairingCubit>(
      create: (_) => getIt<PairingCubit>(),
      child: const _PairingDebugView(),
    );
  }
}

class _PairingDebugView extends StatefulWidget {
  const _PairingDebugView();

  @override
  State<_PairingDebugView> createState() => _PairingDebugViewState();
}

class _PairingDebugViewState extends State<_PairingDebugView> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            FlowAppBar(
              title: 'Pairing debug (dev)',
              onLeading: () => context.pop(),
            ),
            Expanded(
              child: BlocConsumer<PairingCubit, AppState<PairingState>>(
                listener: (context, state) {
                  if (state is AppError<PairingState>) {
                    AppToast.show(
                      context,
                      state.failure.pairingMessage(context.l10n),
                      type: AppToastType.error,
                    );
                  }
                },
                builder: (context, state) {
                  final cubit = context.read<PairingCubit>();
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StatusCard(state: state),
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: 'Host (get code)',
                          onPressed: cubit.host,
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: AppTypography.mono(
                            size: 20,
                            color: colors.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Enter 6-digit code',
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SecondaryButton(
                          label: 'Join',
                          onPressed: () =>
                              cubit.joinWithCode(_codeController.text),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

  final AppState<PairingState> state;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceCard,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status',
            style: bodyStyle?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
          _body(context, colors, bodyStyle),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, AppColors colors, TextStyle? bodyStyle) {
    return switch (state) {
      AppInitial<PairingState>() => Text(
        'Idle',
        style: bodyStyle?.copyWith(color: colors.textPrimary),
      ),
      AppLoading<PairingState>() => Text(
        'Working…',
        style: bodyStyle?.copyWith(color: colors.textPrimary),
      ),
      AppError<PairingState>(:final failure) => Text(
        failure.pairingMessage(context.l10n),
        style: bodyStyle?.copyWith(color: AppColors.danger),
      ),
      AppLoaded<PairingState>(:final data) => _loaded(colors, data, bodyStyle),
    };
  }

  Widget _loaded(AppColors colors, PairingState data, TextStyle? bodyStyle) {
    return switch (data) {
      PairingHosting(:final code) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final digit in code.value.split(''))
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: CodeBox(value: digit),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'expires in ${code.remaining.inSeconds}s — waiting for peer…',
            style: bodyStyle?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
      PairingConnected() => Text(
        'Connected ✓ (data channel open)',
        style: bodyStyle?.copyWith(color: colors.accent),
      ),
      _ => Text(
        data.runtimeType.toString(),
        style: bodyStyle?.copyWith(color: colors.textPrimary),
      ),
    };
  }
}
