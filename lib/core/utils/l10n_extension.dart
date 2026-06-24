import 'package:flutter/widgets.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

/// `context.l10n` accessor for localized strings.
extension L10nX on BuildContext {
  /// The active [AppLocalizations].
  AppLocalizations get l10n => AppLocalizations.of(this);
}
