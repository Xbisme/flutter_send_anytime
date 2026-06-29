import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/features/viewers/presentation/pages/image_viewer_view.dart';
import 'package:safe_send/features/viewers/presentation/widgets/viewer_top_bar.dart';

import '../../helpers/pump_app.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('image_viewer'));
  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('renders a zoomable surface + top bar with the file name', (
    tester,
  ) async {
    final path = '${dir.path}/photo.jpg';
    File(path).writeAsBytesSync([0, 1, 2, 3]);

    await tester.pumpApp(const _Host(path: 'x', name: 'photo.jpg'));
    await tester.pump();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byType(ViewerTopBar), findsOneWidget);
    expect(find.text('photo.jpg'), findsOneWidget);
  });
}

class _Host extends StatelessWidget {
  const _Host({required this.path, required this.name});
  final String path;
  final String name;
  @override
  Widget build(BuildContext context) => ImageViewerView(path: path, name: name);
}
