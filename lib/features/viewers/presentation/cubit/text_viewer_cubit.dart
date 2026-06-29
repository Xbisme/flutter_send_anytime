import 'dart:convert';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:safe_send/core/constants/viewer_formats.dart';
import 'package:safe_send/core/domain/cubit/app_cubit.dart';
import 'package:safe_send/core/domain/failures/app_failure.dart';
import 'package:safe_send/features/viewers/presentation/cubit/text_document.dart';

/// Loads a text/code file for the text viewer (#013, US3). Reads at most
/// [kTextViewerCapBytes] (FR-010a/FR-018) — never the whole of a large file —
/// and flags truncation; a read failure surfaces as a recoverable error.
@injectable
class TextViewerCubit extends AppCubit<TextDocument> {
  TextViewerCubit();

  /// Read [path] (capped) and emit the document.
  Future<void> open(String path) async {
    emitLoading();
    try {
      final file = File(path);
      final length = await file.length();
      final truncated = length > kTextViewerCapBytes;
      final bytes = <int>[];
      await for (final chunk in file.openRead(0, kTextViewerCapBytes)) {
        bytes.addAll(chunk);
        if (bytes.length >= kTextViewerCapBytes) break;
      }
      emitLoaded(
        TextDocument(
          text: utf8.decode(bytes, allowMalformed: true),
          truncated: truncated,
        ),
      );
    } on Object {
      emitError(const AppFailure.fileReadFailed());
    }
  }
}
