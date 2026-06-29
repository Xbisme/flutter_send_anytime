import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/features/pairing/presentation/pairing_failure_l10n.dart';
import 'package:safe_send/features/receive/presentation/receive_failure_l10n.dart';
import 'package:safe_send/features/send/presentation/send_failure_l10n.dart';
import 'package:safe_send/l10n/generated/app_localizations_en.dart';
import 'package:safe_send/l10n/generated/app_localizations_vi.dart';

void main() {
  final en = AppLocalizationsEn();
  final vi = AppLocalizationsVi();
  const failure = AppFailure.relayUnavailable();

  test('relayUnavailable maps to the dedicated relay copy (all 3 mappers)', () {
    expect(failure.pairingMessage(en), en.pairingErrorRelayUnavailable);
    expect(failure.sendMessage(en), en.pairingErrorRelayUnavailable);
    expect(failure.receiveMessage(en), en.pairingErrorRelayUnavailable);
  });

  test('relayUnavailable copy is distinct from the generic fallback', () {
    expect(en.pairingErrorRelayUnavailable, isNot(en.pairingErrorGeneric));
    expect(vi.pairingErrorRelayUnavailable, isNot(vi.pairingErrorGeneric));
  });

  test('localized in both VI (primary) and EN', () {
    expect(vi.pairingErrorRelayUnavailable, isNotEmpty);
    expect(en.pairingErrorRelayUnavailable, isNotEmpty);
    expect(
      vi.pairingErrorRelayUnavailable,
      isNot(en.pairingErrorRelayUnavailable),
    );
  });
}
