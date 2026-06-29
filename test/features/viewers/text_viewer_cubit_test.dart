import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/constants/viewer_formats.dart';
import 'package:safe_send/core/domain/cubit/app_state.dart';
import 'package:safe_send/features/viewers/presentation/cubit/text_document.dart';
import 'package:safe_send/features/viewers/presentation/cubit/text_viewer_cubit.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('text_viewer'));
  tearDown(() => dir.deleteSync(recursive: true));

  AppLoaded<TextDocument> loaded(TextViewerCubit c) =>
      c.state as AppLoaded<TextDocument>;

  test('small file → loaded, not truncated', () async {
    final f = File('${dir.path}/a.txt')..writeAsStringSync('hello world');
    final cubit = TextViewerCubit();
    await cubit.open(f.path);
    expect(loaded(cubit).data.text, 'hello world');
    expect(loaded(cubit).data.truncated, false);
    await cubit.close();
  });

  test('file over the cap → truncated with leading portion only', () async {
    final big = 'a' * (kTextViewerCapBytes + 1024);
    final f = File('${dir.path}/big.txt')..writeAsStringSync(big);
    final cubit = TextViewerCubit();
    await cubit.open(f.path);
    expect(loaded(cubit).data.truncated, true);
    expect(
      loaded(cubit).data.text.length,
      lessThanOrEqualTo(kTextViewerCapBytes),
    );
    await cubit.close();
  });

  test('unreadable path → error', () async {
    final cubit = TextViewerCubit();
    await cubit.open('${dir.path}/missing.txt');
    expect(cubit.state, isA<AppError<TextDocument>>());
    await cubit.close();
  });
}
