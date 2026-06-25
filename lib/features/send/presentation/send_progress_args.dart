import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/services/transport/data_transport.dart';

/// Navigation payload for the send progress route (#004): the files to send and
/// the open transport handed off from pairing.
class SendProgressArgs {
  const SendProgressArgs({required this.sources, required this.transport});

  final List<FileSource> sources;
  final DataTransport transport;
}
