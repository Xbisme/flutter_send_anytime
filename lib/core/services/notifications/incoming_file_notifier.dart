import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

/// Shows an immediate local notification when a file transfer arrives while the
/// app is backgrounded (#010, FR-009). Immediate `show` only — no scheduling, so
/// no `timezone` init is needed. The tap routes back into the receive flow via
/// the `onTap` callback registered at init.
///
/// Copy is Vietnamese-primary (the product's primary language): a backgrounded
/// core service has no `BuildContext`/l10n, so it composes the text itself.
abstract interface class IncomingFileNotifier {
  /// Initialize the plugin (call once in bootstrap). `onTap` fires when the user
  /// taps the notification.
  Future<void> init({void Function()? onTap});

  /// Show "Safe Send · `senderName` đang gửi tệp cho bạn".
  Future<void> showIncoming({required String senderName});
}

/// `flutter_local_notifications`-backed implementation.
@LazySingleton(as: IncomingFileNotifier)
class FlnIncomingFileNotifier implements IncomingFileNotifier {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  void Function()? _onTap;
  bool _ready = false;

  static const _channelId = 'incoming_files';
  static const _channelName = 'Incoming files';

  @override
  Future<void> init({void Function()? onTap}) async {
    _onTap = onTap;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        // Permission is requested explicitly via NotificationPermissionService.
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (_) => _onTap?.call(),
    );
    _ready = true;
  }

  @override
  Future<void> showIncoming({required String senderName}) async {
    if (!_ready) return;
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      id: 0,
      title: 'Safe Send',
      body: '$senderName đang gửi tệp cho bạn',
      notificationDetails: details,
      payload: 'incoming',
    );
  }
}
