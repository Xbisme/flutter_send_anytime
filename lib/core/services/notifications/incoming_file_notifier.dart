import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Local notifications for transfer events (#010 incoming-file + #011
/// keep-app-open reminder). The tap routes back into the app via the `onTap`
/// callback registered at init.
///
/// Copy is Vietnamese-primary (the product's primary language): a backgrounded
/// core service has no `BuildContext`/l10n, so it composes the text itself.
abstract interface class IncomingFileNotifier {
  /// Initialize the plugin (call once in bootstrap). `onTap` fires when the user
  /// taps the notification.
  Future<void> init({void Function()? onTap});

  /// Show "Safe Send · `senderName` đang gửi tệp cho bạn".
  Future<void> showIncoming({required String senderName});

  /// #011 (iOS only): schedule a reminder ~[afterSeconds]s out telling the user
  /// to reopen the app to keep an in-flight transfer going (iOS suspends a
  /// backgrounded P2P transfer). Scheduled via the OS so it still fires after
  /// the app is suspended. No-op on other platforms; cancel with
  /// [cancelKeepOpenReminder] when the app returns or the transfer ends. The
  /// [title]/[body] are localized by the caller (the feature has l10n).
  Future<void> scheduleKeepOpenReminder({
    required String title,
    required String body,
    int afterSeconds = 5,
  });

  /// Cancel a pending keep-open reminder.
  Future<void> cancelKeepOpenReminder();

  /// #011 (iOS): request notification permission via the OS prompt (uses
  /// flutter_local_notifications directly — `permission_handler` mis-reports
  /// iOS notification state as `permanentlyDenied` before the first prompt).
  /// Returns whether it is granted. No-op (true) on Android.
  Future<bool> requestNotificationPermission();
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
  static const _keepOpenChannelId = 'transfer_reminder';
  static const _keepOpenChannelName = 'Transfer reminder';
  static const _keepOpenId = 1;

  @override
  Future<void> init({void Function()? onTap}) async {
    _onTap = onTap;
    tzdata.initializeTimeZones();
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

  @override
  Future<void> scheduleKeepOpenReminder({
    required String title,
    required String body,
    int afterSeconds = 5,
  }) async {
    // iOS only: Android keeps the transfer alive via the foreground service.
    if (!_ready || !Platform.isIOS) return;
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(),
      android: AndroidNotificationDetails(
        _keepOpenChannelId,
        _keepOpenChannelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    final when = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: afterSeconds));
    await _plugin.zonedSchedule(
      id: _keepOpenId,
      scheduledDate: when,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: 'keep_open',
    );
  }

  @override
  Future<void> cancelKeepOpenReminder() async {
    if (!_ready) return;
    await _plugin.cancel(id: _keepOpenId);
  }

  @override
  Future<bool> requestNotificationPermission() async {
    if (!Platform.isIOS) return true;
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final granted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return granted ?? false;
  }
}
