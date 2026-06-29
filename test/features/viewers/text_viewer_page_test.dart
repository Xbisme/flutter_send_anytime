import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/constants/viewer_formats.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/viewer/viewer_request.dart';
import 'package:safe_send/core/utils/file_viewer.dart';
import 'package:safe_send/features/viewers/presentation/cubit/text_viewer_cubit.dart';
import 'package:safe_send/features/viewers/presentation/pages/text_viewer_page.dart';

import '../../helpers/pump_app.dart';

void main() {
  late Directory dir;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('text_page');
    getIt.registerFactory<TextViewerCubit>(TextViewerCubit.new);
  });
  tearDown(() async {
    await getIt.reset();
    dir.deleteSync(recursive: true);
  });

  ViewerRequest req(String path, String name) =>
      ViewerRequest(path: path, name: name, kind: ViewerKind.text);

  // The page reads the file with real async I/O (which only progresses under
  // runAsync). Poll-until-present so it is robust to read latency under load.
  Future<void> pumpUntil(
    WidgetTester tester,
    Widget page,
    Finder target,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpApp(page);
      for (var i = 0; i < 100; i++) {
        await tester.pump();
        if (target.evaluate().isNotEmpty) return;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
  }

  testWidgets('renders selectable text content', (tester) async {
    final f = File('${dir.path}/a.txt')..writeAsStringSync('hello viewer');
    final target = find.text('hello viewer');
    await pumpUntil(
      tester,
      TextViewerPage(request: req(f.path, 'a.txt')),
      target,
    );

    expect(find.byType(SelectableText), findsOneWidget);
    expect(target, findsOneWidget);
  });

  testWidgets('large file shows the truncated notice', (tester) async {
    final f = File('${dir.path}/big.txt')
      ..writeAsStringSync('a' * (kTextViewerCapBytes + 16));
    final target = find.textContaining('Đã hiển thị một phần');
    await pumpUntil(
      tester,
      TextViewerPage(request: req(f.path, 'big.txt')),
      target,
    );

    expect(target, findsOneWidget);
  });
}
