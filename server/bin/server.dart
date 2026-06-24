import 'dart:io';

import 'package:server/signaling_server.dart';

/// Entry point for the Safe Send signaling relay.
///
/// Usage: `dart run bin/server.dart [--port 8080] [--ttl 300]`
/// Logs only the listening line — never codes, IPs, peers, or SDP/ICE
/// (FR-022). The relay is stateless and self-hostable (FR-016).
Future<void> main(List<String> args) async {
  final port = _intArg(args, '--port') ?? 8080;
  final ttlSeconds = _intArg(args, '--ttl');
  final ttl = ttlSeconds != null
      ? Duration(seconds: ttlSeconds)
      : SignalingProtocol.defaultTtl;

  final server = SignalingServer(ttl: ttl);
  final httpServer = await server.serve(address: '0.0.0.0', port: port);

  stdout.writeln(
    'Safe Send signaling relay listening on '
    'ws://${httpServer.address.host}:${httpServer.port} '
    '(code TTL ${ttl.inSeconds}s)',
  );
}

int? _intArg(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i == -1 || i + 1 >= args.length) return null;
  return int.tryParse(args[i + 1]);
}
