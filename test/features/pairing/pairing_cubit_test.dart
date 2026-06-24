import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/core/domain/pairing/pairing_code.dart';
import 'package:safe_send/core/domain/pairing/pairing_state.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/features/pairing/domain/pairing_repository.dart';
import 'package:safe_send/features/pairing/domain/usecases/host_session_usecase.dart';
import 'package:safe_send/features/pairing/domain/usecases/join_session_usecase.dart';
import 'package:safe_send/features/pairing/presentation/cubit/pairing_cubit.dart';

class FakePairingRepository implements PairingRepository {
  final _controller = StreamController<PairingState>.broadcast();

  Result<PairingCode> hostResult = Result.success(
    PairingCode.fromTtl(value: '012345', ttl: const Duration(minutes: 5)),
  );
  Result<void> joinResult = const Result.success(null);

  @override
  Stream<PairingState> get state => _controller.stream;

  @override
  Future<Result<PairingCode>> host() async => hostResult;

  @override
  Future<Result<void>> join(String code) async => joinResult;

  @override
  Future<void> dispose() async {
    if (!_controller.isClosed) await _controller.close();
  }

  void emit(PairingState s) => _controller.add(s);
}

void main() {
  late FakePairingRepository repo;

  PairingCubit build() => PairingCubit(
    HostSessionUseCase(repo),
    JoinSessionUseCase(repo),
    repo,
  );

  setUp(() => repo = FakePairingRepository());

  blocTest<PairingCubit, AppState<PairingState>>(
    'host: loading then loaded(hosting → peerPresent → connected)',
    build: build,
    act: (cubit) async {
      await cubit.host();
      repo
        ..emit(
          PairingState.hosting(
            PairingCode.fromTtl(
              value: '012345',
              ttl: const Duration(minutes: 5),
            ),
          ),
        )
        ..emit(const PairingState.peerPresent())
        ..emit(const PairingState.connected());
      await pumpEventQueue();
    },
    expect: () => [
      isA<AppLoading<PairingState>>(),
      isA<AppLoaded<PairingState>>().having(
        (s) => s.data,
        'data',
        isA<PairingHosting>(),
      ),
      isA<AppLoaded<PairingState>>().having(
        (s) => s.data,
        'data',
        isA<PairingPeerPresent>(),
      ),
      isA<AppLoaded<PairingState>>().having(
        (s) => s.data,
        'data',
        isA<PairingConnected>(),
      ),
    ],
  );

  blocTest<PairingCubit, AppState<PairingState>>(
    'join: a failed lifecycle state surfaces as AppError',
    build: build,
    act: (cubit) async {
      await cubit.joinWithCode('012345');
      repo.emit(const PairingState.failed(AppFailure.roomFull()));
      await pumpEventQueue();
    },
    expect: () => [
      isA<AppLoading<PairingState>>(),
      isA<AppError<PairingState>>().having(
        (s) => s.failure,
        'failure',
        isA<AppFailureRoomFull>(),
      ),
    ],
  );

  blocTest<PairingCubit, AppState<PairingState>>(
    'join: a use-case failure surfaces as AppError',
    build: build,
    act: (cubit) async {
      repo.joinResult = const Result.failure(AppFailure.invalidCode());
      await cubit.joinWithCode('999999');
    },
    expect: () => [
      isA<AppLoading<PairingState>>(),
      isA<AppError<PairingState>>().having(
        (s) => s.failure,
        'failure',
        isA<AppFailureInvalidCode>(),
      ),
    ],
  );
}
