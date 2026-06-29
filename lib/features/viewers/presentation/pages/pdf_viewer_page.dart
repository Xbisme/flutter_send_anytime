import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:safe_send/core/domain/viewer/viewer_request.dart';
import 'package:safe_send/core/theme/app_colors.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/viewers/presentation/widgets/viewer_error_view.dart';
import 'package:safe_send/features/viewers/presentation/widgets/viewer_top_bar.dart';

/// Paged PDF document viewer (#013, US3/FR-009). Renders on-device via PDFium
/// (pdfrx) with page scroll + pinch-zoom; pages render on demand (streamed,
/// bounded memory — FR-018). A malformed PDF degrades to the shared error
/// state + open/share (FR-015).
class PdfViewerPage extends StatelessWidget {
  const PdfViewerPage({required this.request, super.key});

  final ViewerRequest request;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bgBase,
      body: Column(
        children: [
          ViewerTopBar(title: request.name, sharePath: request.path),
          Expanded(
            child: PdfViewer.file(
              request.path,
              params: PdfViewerParams(
                errorBannerBuilder: (context, error, stackTrace, documentRef) =>
                    ViewerErrorView(
                      message: context.l10n.viewerDocumentError,
                      path: request.path,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
