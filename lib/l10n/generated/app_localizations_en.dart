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

  @override
  String get sendTitle => 'Send files';

  @override
  String sendSelectedSummary(int count, String size) {
    return '$count items · $size';
  }

  @override
  String get sendAdd => 'Add';

  @override
  String get sendContinue => 'Continue';

  @override
  String get sendEmptyTitle => 'No files selected';

  @override
  String get sendEmptyBody => 'Tap Add to choose files to send';

  @override
  String get sendRemove => 'Remove';

  @override
  String get connectTitle => 'Connect devices';

  @override
  String get connectTabCode => '6-digit';

  @override
  String get connectTabQr => 'QR';

  @override
  String get connectTabNearby => 'Nearby';

  @override
  String get connectShareInstruction => 'Share this code with the receiver';

  @override
  String connectExpiresIn(String time) {
    return 'Expires in $time';
  }

  @override
  String get connectWaiting => 'Waiting for the other device…';

  @override
  String get connectShareLink => 'Share invite link';

  @override
  String get connectRefreshCode => 'Get a new code';

  @override
  String get connectComingSoonTab => 'This option is coming soon';

  @override
  String get sendProgressBadge => 'SENDING';

  @override
  String get sendPeerReceiver => 'the receiver';

  @override
  String sendProgressTo(String peer) {
    return 'to $peer';
  }

  @override
  String sendProgressFilePosition(int index, int total) {
    return 'file $index/$total';
  }

  @override
  String sendProgressRemaining(String time) {
    return '$time left';
  }

  @override
  String get sendCancel => 'Cancel';

  @override
  String get sendCancelConfirmTitle => 'Cancel this send?';

  @override
  String get sendCancelConfirmBody => 'The transfer in progress will stop.';

  @override
  String get sendCancelConfirmKeep => 'Keep sending';

  @override
  String get sendCompleteTitle => 'Done!';

  @override
  String sendCompleteDetail(
    int count,
    String size,
    String peer,
    String duration,
  ) {
    return 'Sent $count files · $size to $peer in $duration';
  }

  @override
  String get sendDone => 'Done';

  @override
  String get sendAgain => 'Send more';

  @override
  String get sendErrorTitle => 'Send failed';

  @override
  String get sendRetry => 'Try again';

  @override
  String get sendErrorRejected => 'The receiver declined';

  @override
  String get sendErrorFileRead => 'Couldn\'t read the selected file';

  @override
  String get receiveEnterCodeTitle => 'Enter the code';

  @override
  String get receiveEnterCodeInstruction =>
      'Enter the 6-digit code from the sender';

  @override
  String get receiveConnect => 'Connect';

  @override
  String get receiveConnecting => 'Connecting…';

  @override
  String get receivePeerSender => 'the sender';

  @override
  String receivePromptTitle(String peer) {
    return '$peer wants to send you files';
  }

  @override
  String receivePromptBody(int count, String size) {
    return '$count files · $size';
  }

  @override
  String get receiveAccept => 'Accept';

  @override
  String get receiveReject => 'Decline';

  @override
  String get receiveProgressBadge => 'RECEIVING';

  @override
  String receiveProgressFrom(String peer) {
    return 'from $peer';
  }

  @override
  String receiveProgressFilePosition(int index, int total) {
    return 'file $index/$total';
  }

  @override
  String receiveProgressRemaining(String time) {
    return '$time left';
  }

  @override
  String get receiveCancel => 'Cancel';

  @override
  String get receiveCancelConfirmTitle => 'Cancel this transfer?';

  @override
  String get receiveCancelConfirmBody =>
      'The transfer in progress will stop. Files already received are kept.';

  @override
  String get receiveCancelConfirmKeep => 'Keep receiving';

  @override
  String get receiveCompleteTitle => 'Received!';

  @override
  String receiveCompleteDetail(
    int count,
    String size,
    String peer,
    String duration,
  ) {
    return 'Received $count files · $size from $peer in $duration';
  }

  @override
  String get receivePartialTitle => 'Partly received';

  @override
  String receivePartialDetail(int received, int total, String size) {
    return 'Received $received/$total files · $size';
  }

  @override
  String get receiveOpen => 'Open';

  @override
  String get receiveShare => 'Share';

  @override
  String get receiveDone => 'Done';

  @override
  String get receiveErrorTitle => 'Receive failed';

  @override
  String get receiveRetry => 'Try again';

  @override
  String get receiveErrorIntegrity =>
      'A file failed its integrity check — receive again';

  @override
  String get receiveErrorWrite => 'Couldn\'t save the file to your device';

  @override
  String get receiveErrorConnectionLost => 'Lost connection while receiving';

  @override
  String get receiveOpenFailed => 'Couldn\'t open this file';

  @override
  String get receiveShareFailed => 'Couldn\'t share';
}
