import 'package:injectable/injectable.dart';

/// Holds the device's current pairing hosting code so the deep-link coordinator
/// can detect a self-invite — the host tapping its own invite link (#008,
/// FR-015). Written by the pairing layer (host start / code rotation / dispose),
/// read by the coordinator. The code is the already-ephemeral 6-digit rendezvous
/// and MUST NOT be logged (Constitution I).
abstract interface class ActiveHostingRegistry {
  /// The current hosting code, or null when this device is not hosting.
  String? get activeHostingCode;

  /// Record the active hosting code (host start or code rotation).
  void setHosting(String code);

  /// Clear the active hosting code (session end / dispose).
  void clear();
}

@LazySingleton(as: ActiveHostingRegistry)
class ActiveHostingRegistryImpl implements ActiveHostingRegistry {
  String? _code;

  @override
  String? get activeHostingCode => _code;

  @override
  void setHosting(String code) => _code = code;

  @override
  void clear() => _code = null;
}
