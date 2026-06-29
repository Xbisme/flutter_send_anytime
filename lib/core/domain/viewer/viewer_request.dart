import 'package:flutter/foundation.dart';
import 'package:safe_send/core/utils/file_viewer.dart';

/// The go_router `extra` for `AppRoutes.fileViewer` (#013). Core-typed so the
/// three entry-point features and the viewers feature never import each other
/// (Constitution XI). Carries a **received** file already verified to exist on
/// disk; [kind] is always a viewable kind (never [ViewerKind.unsupported]).
@immutable
class ViewerRequest {
  const ViewerRequest({
    required this.path,
    required this.name,
    required this.kind,
    this.mimeType,
  });

  /// On-disk path of the received file.
  final String path;

  /// Display name (viewer title bar).
  final String name;

  /// Resolved viewer kind (image / video / audio / pdf / text).
  final ViewerKind kind;

  /// MIME type when known (from the history record); null otherwise.
  final String? mimeType;
}
