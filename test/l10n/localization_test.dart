import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

void main() {
  group('Localization', () {
    test('supports Vietnamese and English', () {
      final codes = AppLocalizations.supportedLocales
          .map((l) => l.languageCode)
          .toSet();
      expect(codes, containsAll(<String>['vi', 'en']));
    });

    test('Vietnamese strings are the primary translations', () async {
      final vi = await AppLocalizations.delegate.load(const Locale('vi'));
      expect(vi.navHome, 'Trang chủ');
      expect(vi.actionSend, 'Gửi');
      expect(vi.actionReceive, 'Nhận');
    });

    test('English strings are provided', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(en.navHome, 'Home');
      expect(en.actionSend, 'Send');
    });

    test('ARB files have identical key sets (parity)', () {
      Set<String> keysOf(String path) {
        final json =
            jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
        return json.keys.where((k) => !k.startsWith('@')).toSet();
      }

      final vi = keysOf('lib/l10n/arb/app_vi.arb');
      final en = keysOf('lib/l10n/arb/app_en.arb');
      expect(vi.difference(en), isEmpty, reason: 'keys missing from en');
      expect(en.difference(vi), isEmpty, reason: 'keys missing from vi');
    });
  });
}
