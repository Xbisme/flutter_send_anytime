import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/viewer/viewer_request.dart';
import 'package:safe_send/core/presentation/feedback/app_toast.dart';
import 'package:safe_send/core/services/file/received_files_service.dart';
import 'package:safe_send/core/utils/file_viewer.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/core/utils/received_file_path.dart';

/// Core-pure launch seam for the in-app viewers (#013). Imports core only —
/// never a feature page (the router binds `AppRoutes.fileViewer` →
/// `FileViewerPage`), so the three entry-point features and `features/viewers`
/// never import each other (Constitution XI). The decision table here is the
/// single source of viewer-vs-fallback behaviour (FR-001/004/014/016).
abstract final class FileOpenCoordinator {
  /// Guards against a double-tap pushing two viewers (FR-016).
  static bool _opening = false;

  /// Build a [ViewerRequest] iff [path] is a **received** file that exists on
  /// disk and resolves to a viewable kind; otherwise `null`. Synchronous —
  /// callers may use it to pick a fallback destination (e.g. Home → detail).
  static ViewerRequest? viewableRequestFor({
    required String name,
    required String? path,
    required String? mimeType,
    required bool isReceived,
  }) {
    if (!isReceived || path == null || path.isEmpty) return null;
    // Heal a stale iOS container path before checking existence (see
    // ReceivedFilePath) so a rebuild doesn't make old files "unavailable".
    final resolved = ReceivedFilePath.resolve(path);
    if (!File(resolved).existsSync()) return null;
    final kind = ViewerResolver.of(name, mimeType: mimeType);
    if (!ViewerResolver.isViewable(kind)) return null;
    return ViewerRequest(
      path: resolved,
      name: name,
      kind: kind,
      mimeType: mimeType,
    );
  }

  /// Open a tapped file from History detail / Receive-complete. Received +
  /// viewable → push the in-app viewer; unsupported (or sent) → OS open/share
  /// fallback; missing/unreadable → a "file unavailable" toast.
  static Future<void> openTransferredFile(
    BuildContext context, {
    required String name,
    required String? path,
    required String? mimeType,
    required bool isReceived,
  }) async {
    if (_opening) return;
    final request = viewableRequestFor(
      name: name,
      path: path,
      mimeType: mimeType,
      isReceived: isReceived,
    );

    if (request != null) {
      _opening = true;
      try {
        await context.push<void>(AppRoutes.fileViewer, extra: request);
      } finally {
        _opening = false;
      }
      return;
    }

    // Sent, unsupported, or missing → not an in-app viewer.
    if (!isReceived) {
      await _osOpen(context, path);
      return;
    }
    final resolved = path == null || path.isEmpty
        ? null
        : ReceivedFilePath.resolve(path);
    if (resolved == null || !File(resolved).existsSync()) {
      if (context.mounted) {
        AppToast.show(
          context,
          context.l10n.viewerFileUnavailable,
          type: AppToastType.error,
        );
      }
      return;
    }
    // Exists but unsupported type → OS open/share (FR-004).
    await _osOpen(context, resolved);
  }

  static Future<void> _osOpen(BuildContext context, String? path) async {
    if (path == null || path.isEmpty) return;
    final result = await getIt<ReceivedFilesService>().open(path);
    if (!context.mounted) return;
    result.fold((_) {}, (_) {
      AppToast.show(
        context,
        context.l10n.viewerFileUnavailable,
        type: AppToastType.error,
      );
    });
  }
}
