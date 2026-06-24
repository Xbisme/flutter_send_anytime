import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/features/pairing/domain/pairing_repository.dart';

/// Receiver path: join a pairing session with a 6-digit code.
@injectable
class JoinSessionUseCase {
  const JoinSessionUseCase(this._repository);

  final PairingRepository _repository;

  /// Join the room bound to [code] and connect.
  Future<Result<void>> call(String code) => _repository.join(code);
}
