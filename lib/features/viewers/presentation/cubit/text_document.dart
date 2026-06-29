import 'package:flutter/foundation.dart';

/// The text shown by the text viewer (#013, US3). [truncated] is true when the
/// source file exceeded the read cap and only its leading portion is shown
/// (FR-010a).
@immutable
class TextDocument {
  const TextDocument({required this.text, required this.truncated});

  final String text;
  final bool truncated;
}
