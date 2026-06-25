import 'package:safe_send/core/domain/history/transfer_history_enums.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';

/// Navigation payload for the receive progress route (#005): the open transport
/// handed off from pairing, plus how the pair was made (#007) for history.
class ReceiveProgressArgs {
  const ReceiveProgressArgs({
    required this.transport,
    this.method = PairingMethod.sixDigitCode,
  });

  final DataTransport transport;
  final PairingMethod method;
}
