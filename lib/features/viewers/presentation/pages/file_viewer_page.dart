import 'package:flutter/material.dart';
import 'package:safe_send/core/domain/viewer/viewer_request.dart';
import 'package:safe_send/core/utils/file_viewer.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/viewers/presentation/pages/image_viewer_view.dart';
import 'package:safe_send/features/viewers/presentation/pages/media_player_page.dart';
import 'package:safe_send/features/viewers/presentation/pages/pdf_viewer_page.dart';
import 'package:safe_send/features/viewers/presentation/pages/text_viewer_page.dart';
import 'package:safe_send/features/viewers/presentation/widgets/viewer_error_view.dart';
import 'package:safe_send/features/viewers/presentation/widgets/viewer_top_bar.dart';

/// Full-screen in-app viewer dispatcher (#013). Bound to `AppRoutes.fileViewer`
/// on the root navigator; reads the [ViewerRequest] extra and renders the right
/// viewer by [ViewerKind]. Launch-source agnostic (FR-003).
class FileViewerPage extends StatelessWidget {
  const FileViewerPage({required this.request, super.key});

  final ViewerRequest request;

  @override
  Widget build(BuildContext context) {
    return switch (request.kind) {
      ViewerKind.image => ImageViewerView(
        path: request.path,
        name: request.name,
      ),
      ViewerKind.video || ViewerKind.audio => MediaPlayerPage(request: request),
      ViewerKind.pdf => PdfViewerPage(request: request),
      ViewerKind.text => TextViewerPage(request: request),
      // Defensive: the coordinator never routes an unsupported kind here.
      ViewerKind.unsupported => Scaffold(
        body: Column(
          children: [
            ViewerTopBar(title: request.name, sharePath: request.path),
            Expanded(
              child: ViewerErrorView(
                message: context.l10n.viewerErrorGeneric,
                path: request.path,
              ),
            ),
          ],
        ),
      ),
    };
  }
}
