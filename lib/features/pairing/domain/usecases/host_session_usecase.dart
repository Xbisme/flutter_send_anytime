import 'package:injectable/injectable.dart';
import 'package:safe_send/core/domain/pairing/pairing_code.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/features/pairing/domain/pairing_repository.dart';

/// Sender path: start a pairing session and obtain a 6-digit code.
@injectable
class HostSessionUseCase {
  const HostSessionUseCase(this._repository);

  final PairingRepository _repository;

  /// Generate a code and begin waiting for a peer.
  Future<Result<PairingCode>> call() => _repository.host();
}
