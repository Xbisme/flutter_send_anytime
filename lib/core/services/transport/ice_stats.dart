/// A minimal, plugin-agnostic view of one WebRTC stats report — just the
/// fields we need to decide whether ICE selected a relayed (TURN) path. Kept
/// free of `flutter_webrtc` types so the [isRelaySelected] logic is unit-
/// testable without a live peer connection (#014, T017).
class IceStatReport {
  const IceStatReport({
    required this.id,
    required this.type,
    required this.values,
  });

  /// The report's stats id (used to link a candidate-pair to its candidates).
  final String id;

  /// The report `type` (e.g. `candidate-pair`, `local-candidate`).
  final String type;

  /// The report's flat key/value map.
  final Map<String, Object?> values;
}

/// Whether the connection's selected ICE candidate pair uses a **relay** (TURN)
/// candidate on either end.
///
/// Picks the succeeded, nominated/selected candidate pair (falling back to any
/// succeeded pair), then checks whether its local or remote candidate has
/// `candidateType == 'relay'`. Returns false when nothing matches — i.e. a
/// direct (host/srflx) path, which is the default and preferred case (FR-004).
bool isRelaySelected(List<IceStatReport> reports) {
  IceStatReport? pair;
  for (final r in reports) {
    if (r.type != 'candidate-pair') continue;
    final state = r.values['state'];
    final active =
        r.values['nominated'] == true || r.values['selected'] == true;
    if (state == 'succeeded' && active) {
      pair = r;
      break;
    }
  }
  // Fallback: some platforms don't flag nominated/selected — take any succeeded.
  if (pair == null) {
    for (final r in reports) {
      if (r.type == 'candidate-pair' && r.values['state'] == 'succeeded') {
        pair = r;
        break;
      }
    }
  }
  if (pair == null) return false;

  bool isRelayCandidate(Object? candidateId) {
    if (candidateId is! String) return false;
    for (final r in reports) {
      if (r.id == candidateId) return r.values['candidateType'] == 'relay';
    }
    return false;
  }

  return isRelayCandidate(pair.values['localCandidateId']) ||
      isRelayCandidate(pair.values['remoteCandidateId']);
}
