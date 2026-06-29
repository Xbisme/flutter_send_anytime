import 'dart:io';

import 'package:server/signaling_server.dart';
import 'package:server/turn_credential_service.dart';

/// Entry point for the Safe Send signaling relay.
///
/// Usage: `dart run bin/server.dart [--port 8080] [--ttl 300]`
/// TURN (optional, #014): set `TURN_URLS` (comma-separated `turn:`/`turns:`),
/// `TURN_SECRET` (coturn `static-auth-secret`), and optionally
/// `TURN_TTL_SECONDS` to issue ephemeral relay credentials on pairing. When
/// unset, the relay stays STUN-only and clients use their static ICE config.
/// Logs only the listening line — never codes, IPs, peers, SDP/ICE, or the
/// TURN secret/credentials (FR-011/022). The relay is stateless + self-hostable.
Future<void> main(List<String> args) async {
  final port = _intArg(args, '--port') ?? 8080;
  final ttlSeconds = _intArg(args, '--ttl');
  final ttl = ttlSeconds != null
      ? Duration(seconds: ttlSeconds)
      : SignalingProtocol.defaultTtl;

  final turn = TurnCredentialService.fromEnv(Platform.environment);
  final server = SignalingServer(ttl: ttl, turnCredentials: turn);
  final httpServer = await server.serve(address: '0.0.0.0', port: port);

  stdout.writeln(
    'Safe Send signaling relay listening on '
    'ws://${httpServer.address.host}:${httpServer.port} '
    '(code TTL ${ttl.inSeconds}s, TURN ${turn == null ? 'off' : 'on'})',
  );
}

int? _intArg(List<String> args, String name) {
  final i = args.indexOf(name);
  if (i == -1 || i + 1 >= args.length) return null;
  return int.tryParse(args[i + 1]);
}
