/// This device's user-visible identity to peers (#010): a display [name] and a
/// derived single-character [initial] for the avatar (per Screen 08 — a
/// gradient letter avatar, no uploaded photo).
class DeviceProfile {
  const DeviceProfile(this.name);

  /// The display name shown to nearby/receiving peers.
  final String name;

  /// First code point of the trimmed name, uppercased, for the avatar. Falls
  /// back to `S` (Safe Send) when the name has no leading character.
  String get initial {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'S';
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }
}
