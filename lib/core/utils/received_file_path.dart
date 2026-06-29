import 'dart:io';

/// Heals stored received-file paths against the **current** app documents
/// directory. Received files live in `<AppDocuments>/SafeSend/…` (#005) and the
/// history store (#006) keeps their absolute path. On iOS the data-container
/// UUID changes on every reinstall/rebuild — the bytes are migrated to a new
/// `…/Application/<NEW-UUID>/Documents/SafeSend/…` path, so the stored absolute
/// path goes stale even though the file still exists. The prefix before
/// `/SafeSend/` is the only volatile part; the tail is stable, so we re-root it
/// on the current documents base. Read-only + idempotent — no schema/migration.
abstract final class ReceivedFilePath {
  /// Current app documents directory path, cached at bootstrap (sync access for
  /// widget builds). Null until set.
  static String? documentsBase;

  static const _marker = '/SafeSend/';

  /// Return a path that exists on disk: [stored] if still valid, otherwise the
  /// same `SafeSend/…` tail re-rooted on [documentsBase]; falls back to
  /// [stored] when neither resolves (caller treats it as unavailable).
  static String resolve(String stored) {
    if (stored.isEmpty) return stored;
    if (File(stored).existsSync()) return stored;

    final base = documentsBase;
    final idx = stored.indexOf(_marker);
    if (base != null && idx >= 0) {
      // tail = 'SafeSend/…' (drop the leading separator of the marker).
      final tail = stored.substring(idx + 1);
      final candidate = '$base${Platform.pathSeparator}$tail';
      if (File(candidate).existsSync()) return candidate;
    }
    return stored;
  }
}
