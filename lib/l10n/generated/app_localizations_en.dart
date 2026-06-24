// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navHistory => 'History';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeSearchHint => 'Search sent or received files...';

  @override
  String get homeSent => 'Sent';

  @override
  String get homeReceived => 'Received';

  @override
  String homeMonthlyTransfers(int count) {
    return '$count transfers this month';
  }

  @override
  String get homeStatPhotos => 'Photos';

  @override
  String get homeStatVideos => 'Videos';

  @override
  String get homeStatFiles => 'Files';

  @override
  String get homeRecentImages => 'Recent photos';

  @override
  String get homeRecentVideos => 'Recent videos';

  @override
  String get homeRecentFiles => 'Recent files';

  @override
  String get homeRecentTransfers => 'Recent transfers';

  @override
  String get homeSeeAll => 'See all';

  @override
  String get homeQuickActions => 'Quick actions';

  @override
  String get homeActionSend => 'Send files';

  @override
  String get homeActionSendSub => 'Pick & send';

  @override
  String get homeActionReceive => 'Receive files';

  @override
  String get homeActionReceiveSub => 'Enter 6-digit code';

  @override
  String get homeActionScanQr => 'Scan QR';

  @override
  String get homeActionScanQrSub => 'Quick connect';

  @override
  String get homeActionNearby => 'Nearby devices';

  @override
  String get homeActionNearbySub => 'Instant transfer';

  @override
  String get homeTipTitle => 'Tip';

  @override
  String get homeTipBody =>
      'Long-press a file to send, rename, or delete it quickly.';

  @override
  String get homeTipCta => 'Learn more';

  @override
  String get actionSend => 'Send';

  @override
  String get actionReceive => 'Receive';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String get sendComingSoonBody => 'Sending files will be available soon.';

  @override
  String get receiveComingSoonBody => 'Receiving files will be available soon.';

  @override
  String get historyTitle => 'History';

  @override
  String get historyEmptyTitle => 'No transfers yet';

  @override
  String get historyEmptyBody =>
      'Your sent and received files will appear here.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsProfileSub => 'visible to nearby devices';

  @override
  String get settingsAutoReceive => 'Auto-receive';

  @override
  String get settingsAutoReceiveSub => 'From trusted devices';

  @override
  String get settingsSaveToLibrary => 'Save to library';

  @override
  String get settingsSaveToLibrarySub => 'Received photos & videos';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsSub => 'When a file arrives';

  @override
  String get settingsDarkMode => 'Dark mode';

  @override
  String get settingsDarkModeSub => 'Follow system';

  @override
  String settingsVersion(String version) {
    return 'Safe Send v$version · WebRTC P2P';
  }

  @override
  String get commonBack => 'Back';

  @override
  String get pairingErrorInvalidCode => 'Invalid code';

  @override
  String get pairingErrorRoomFull => 'That room is already full';

  @override
  String get pairingErrorRoomExpired => 'This code has expired';

  @override
  String get pairingErrorRateLimited => 'Too many attempts — please wait';

  @override
  String get pairingErrorUnreachable => 'Can\'t reach the server';

  @override
  String get pairingErrorTimeout => 'Connection timed out';

  @override
  String get pairingErrorConnectionLost =>
      'Lost connection to the other device';

  @override
  String get pairingErrorGeneric => 'Something went wrong, please try again';
}
