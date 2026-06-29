import 'dart:io';

import 'package:flutter/material.dart';
import 'package:safe_send/core/utils/l10n_extension.dart';
import 'package:safe_send/features/viewers/presentation/widgets/viewer_error_view.dart';
import 'package:safe_send/features/viewers/presentation/widgets/viewer_top_bar.dart';

/// Full-screen image viewer (#013, FR-005): pinch-zoom + pan over a
/// screen-bounded decode (OOM guard, FR-018). GIFs animate natively; an
/// undecodable image (e.g. an unsupported HEIC on older Android) degrades to
/// the shared error state + open/share (FR-015).
class ImageViewerView extends StatelessWidget {
  const ImageViewerView({required this.path, required this.name, super.key});

  final String path;
  final String name;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Cap the decoded bitmap at ~2x logical screen width so a very large image
    // cannot blow the memory budget while still allowing zoom detail.
    final cacheWidth = (media.size.width * media.devicePixelRatio * 2).round();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 6,
              child: Center(
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  cacheWidth: cacheWidth,
                  errorBuilder: (_, _, _) => ViewerErrorView(
                    message: context.l10n.viewerImageError,
                    path: path,
                    dark: true,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ViewerTopBar(title: name, sharePath: path, dark: true),
          ),
        ],
      ),
    );
  }
}
