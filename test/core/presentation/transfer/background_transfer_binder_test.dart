import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safe_send/core/constants/app_routes.dart';
import 'package:safe_send/core/di/injection.dart';
import 'package:safe_send/core/domain/transfer/transfer_view.dart';
import 'package:safe_send/core/domain/transfer_enums.dart';
import 'package:safe_send/core/presentation/transfer/background_transfer_binder.dart';
import 'package:safe_send/core/services/background/active_transfer_handle.dart';
import 'package:safe_send/core/services/background/background_execution_service.dart';
import 'package:safe_send/core/services/background/background_surface_controller.dart';
import 'package:safe_send/core/services/background/background_transfer_coordinator.dart';
import 'package:safe_send/core/services/notifications/incoming_file_notifier.dart';
import 'package:safe_send/l10n/generated/app_localizations.dart';

class _NoopController implements BackgroundSurfaceController {
  @override
  Future<bool> get isSupported async => false;
  @override
  Future<void> start(_) async {}
  @override
  Future<void> update(_) async {}
  @override
  Future<void> end() async {}
  @override
  Stream<BackgroundServiceAction> get actions => const Stream.empty();
}

class _NoopReminder implements IncomingFileNotifier {
  @override
  Future<void> init({void Function()? onTap}) async {}
  @override
  Future<void> showIncoming({required String senderName}) async {}
  @override
  Future<void> scheduleKeepOpenReminder({
    required String title,
    required String body,
    int afterSeconds = 5,
  }) async {}
  @override
  Future<void> cancelKeepOpenReminder() async {}
  @override
  Future<bool> requestNotificationPermission() async => true;
}

class _NoopBgTask implements BackgroundExecutionService {
  @override
  Future<void> begin() async {}
  @override
  Future<void> end() async {}
}

/// Records the seam calls without running the real surface logic.
class _SpyCoordinator extends BackgroundTransferCoordinator {
  _SpyCoordinator() : super(_NoopController(), _NoopReminder(), _NoopBgTask());

  int attachCount = 0;
  int detachCount = 0;
  ActiveTransferHandle? lastHandle;

  @override
  void attach(ActiveTransferHandle handle) {
    attachCount++;
    lastHandle = handle;
  }

  @override
  void detach() => detachCount++;
}

void main() {
  late _SpyCoordinator spy;

  setUp(() {
    spy = _SpyCoordinator();
    getIt.registerSingleton<BackgroundTransferCoordinator>(spy);
  });

  tearDown(() async {
    await getIt.unregister<BackgroundTransferCoordinator>();
  });

  Widget wrap(Widget child) => MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('vi'),
    home: child,
  );

  Future<void> pumpBinder(
    WidgetTester tester, {
    required TransferDirection direction,
    required String route,
    required Stream<TransferView> views,
    required VoidCallback onCancel,
  }) => tester.pumpWidget(
    wrap(
      BackgroundTransferBinder(
        views: views,
        onCancel: onCancel,
        direction: direction,
        progressRoute: route,
        peerName: 'peer',
        child: const SizedBox(),
      ),
    ),
  );

  testWidgets('send seam: attaches on mount, detaches on dispose (T014)', (
    tester,
  ) async {
    final views = StreamController<TransferView>.broadcast();
    var cancelled = false;
    await pumpBinder(
      tester,
      direction: TransferDirection.sent,
      route: AppRoutes.sendProgress,
      views: views.stream,
      onCancel: () => cancelled = true,
    );

    expect(spy.attachCount, 1);
    expect(spy.lastHandle!.direction, TransferDirection.sent);
    expect(spy.lastHandle!.progressRoute, AppRoutes.sendProgress);
    // onCancel routes to the supplied callback (same as the in-app Cancel).
    spy.lastHandle!.onCancel();
    expect(cancelled, isTrue);

    await tester.pumpWidget(wrap(const SizedBox()));
    expect(spy.detachCount, 1);
    await views.close();
  });

  testWidgets('receive seam: attaches on mount, detaches on dispose (T015)', (
    tester,
  ) async {
    final views = StreamController<TransferView>.broadcast();
    await pumpBinder(
      tester,
      direction: TransferDirection.received,
      route: AppRoutes.receiveProgress,
      views: views.stream,
      onCancel: () {},
    );

    expect(spy.attachCount, 1);
    expect(spy.lastHandle!.direction, TransferDirection.received);
    expect(spy.lastHandle!.progressRoute, AppRoutes.receiveProgress);

    await tester.pumpWidget(wrap(const SizedBox()));
    expect(spy.detachCount, 1);
    await views.close();
  });
}
