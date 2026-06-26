import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

/// Remembers the last invite link this install acted on, so a re-delivered
/// launch URL is not processed twice (#008).
///
/// iOS can report the original launch link again on a later cold start; without
/// this guard the app would re-run the auto-join with a now-expired code and
/// nag with an "expired" toast on every relaunch.
///
/// Privacy (Constitution I): only a one-way SHA-256 digest is persisted — never
/// the link or the rendezvous code — and it lives in app-private storage.
class HandledLinkStore {
  File? _file;

  Future<File> _resolve() async {
    final dir = await getApplicationSupportDirectory();
    return _file ??= File('${dir.path}/safesend_last_link');
  }

  /// Returns true if [uri] has not been handled before (recording it as handled
  /// for future runs); false if it matches the last handled link — the caller
  /// should then skip it.
  Future<bool> claim(Uri uri) async {
    final digest = sha256.convert(utf8.encode(uri.toString())).toString();
    final file = await _resolve();
    try {
      if (file.existsSync() && await file.readAsString() == digest) {
        return false;
      }
    } on Object {
      // Unreadable store — treat the link as new.
    }
    try {
      await file.writeAsString(digest, flush: true);
    } on Object {
      // Best-effort persistence; a failed write just risks one re-handle.
    }
    return true;
  }
}
