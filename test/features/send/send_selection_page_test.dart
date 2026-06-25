import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/config/app_config.dart';
import 'package:safe_send/core/config/app_flavor.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/result.dart';
import 'package:safe_send/core/domain/transfer/file_source.dart';
import 'package:safe_send/core/presentation/buttons/app_buttons.dart';
import 'package:safe_send/core/presentation/files/file_widgets.dart';
import 'package:safe_send/core/services/file/file_picker_service.dart';
import 'package:safe_send/features/send/presentation/pages/send_selection_page.dart';

import '../../helpers/pump_app.dart';

class _FakeSource implements FileSource {
  _FakeSource(this.name, this.size);
  @override
  final String name;
  @override
  final int size;
  @override
  String? get mimeType => null;
  @override
  Stream<List<int>> openRead() => const Stream.empty();
}

class _FakePicker implements FilePickerService {
  List<FileSource> files = <FileSource>[];
  @override
  Future<Result<List<FileSource>>> pickFiles() async => Result.success(files);
}

void main() {
  late _FakePicker picker;

  setUp(() async {
    await configureDependencies(const AppConfig(flavor: AppFlavor.dev));
    picker = _FakePicker();
    getIt
      ..unregister<FilePickerService>()
      ..registerFactory<FilePickerService>(() => picker);
  });
  tearDown(() async => getIt.reset());

  testWidgets('empty selection shows empty state and a disabled Continue', (
    tester,
  ) async {
    await tester.pumpApp(const SendSelectionPage(), locale: const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('No files selected'), findsOneWidget);
    final cta = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Continue'),
    );
    expect(cta.onPressed, isNull);
  });

  testWidgets('adding files shows the tray with per-file rows + total', (
    tester,
  ) async {
    picker.files = [_FakeSource('a.pdf', 1024), _FakeSource('b.jpg', 2048)];
    await tester.pumpApp(const SendSelectionPage(), locale: const Locale('en'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(SecondaryButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.byType(FileRow), findsNWidgets(2));
    final cta = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Continue'),
    );
    expect(cta.onPressed, isNotNull);
  });
}
