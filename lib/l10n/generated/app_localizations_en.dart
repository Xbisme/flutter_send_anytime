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
  String get historyPeerSender => 'Sender';

  @override
  String get historyPeerReceiver => 'Recipient';

  @override
  String get historyToday => 'Today';

  @override
  String get historyYesterday => 'Yesterday';

  @override
  String historyFilesCount(int count) {
    return '$count files';
  }

  @override
  String get historyStatusPartial => 'Partial';

  @override
  String get historyStatusFailed => 'Failed';

  @override
  String get historyStatusCancelled => 'Cancelled';

  @override
  String get historyNoResultsTitle => 'No results';

  @override
  String get historyNoResultsBody => 'Try a different search or filter.';

  @override
  String get historyDetailTitle => 'Details';

  @override
  String get historyBack => 'Back';

  @override
  String get historyDirectionSent => 'Sent';

  @override
  String get historyDirectionReceived => 'Received';

  @override
  String get historyFieldStatus => 'Status';

  @override
  String get historyFieldMethod => 'Pairing method';

  @override
  String get historyFieldDate => 'Date';

  @override
  String get historyFieldFiles => 'Files';

  @override
  String get historyStatusCompleted => 'Completed';

  @override
  String get historyMethodSixDigit => '6-digit code';

  @override
  String get historyMethodQr => 'QR code';

  @override
  String get historyMethodShareLink => 'Share link';

  @override
  String get historyMethodNearby => 'Nearby';

  @override
  String get historySearchHint => 'Search by peer or file name';

  @override
  String get historyFilterAll => 'All';

  @override
  String get historyFilterDate => 'Date';

  @override
  String get historyFilterClear => 'Clear';

  @override
  String get historyActionResend => 'Re-send';

  @override
  String get historyActionOpen => 'Open';

  @override
  String get historyActionShare => 'Share';

  @override
  String get historyActionDelete => 'Delete';

  @override
  String get historyClearAll => 'Clear all';

  @override
  String get historyCancel => 'Cancel';

  @override
  String get historyDeleteConfirmTitle => 'Delete this record?';

  @override
  String get historyDeleteConfirmBody =>
      'Removes it from history only — the files on your device are kept.';

  @override
  String get historyClearConfirmTitle => 'Clear all history?';

  @override
  String get historyClearConfirmBody =>
      'Every record is removed — the files on your device are kept.';

  @override
  String get historyFileUnavailable => 'File is no longer available';

  @override
  String get homeNoRecent => 'No recent transfers yet.';

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

  @override
  String get commonOr => 'or';

  @override
  String get receiveScanQr => 'Scan QR code';

  @override
  String get connectQrInstruction => 'Have the receiver scan this QR code';

  @override
  String connectQrCodeLabel(String code) {
    return 'QR code containing connection code $code';
  }

  @override
  String get scanTitle => 'Scan QR code';

  @override
  String get scanInstruction => 'Point the camera at the sender\'s QR code';

  @override
  String get scanTorch => 'Torch';

  @override
  String get scanPickImage => 'Choose a photo with a QR code';

  @override
  String get scanInvalidCode => 'That\'s not a Safe Send code';

  @override
  String get scanNoCodeFound => 'No QR code found in the image';

  @override
  String get scanCameraBlockedTitle => 'Camera permission needed';

  @override
  String get scanCameraBlockedBody =>
      'Allow Safe Send to use the camera, or choose a photo that has the QR code.';

  @override
  String get scanOpenSettings => 'Open Settings';

  @override
  String get scanRequestPermission => 'Allow camera';

  @override
  String get connectShareLinkMessage =>
      'I\'d like to send you some files via Safe Send — tap the link to receive:';

  @override
  String get shareLinkInvalid => 'Invalid invite link';

  @override
  String get shareLinkExpired => 'This invite link has expired';

  @override
  String get shareLinkOwn => 'This is your own invite link';

  @override
  String get shareLinkLeaveTransferTitle => 'Leave the current transfer?';

  @override
  String get shareLinkLeaveTransferBody =>
      'A transfer is in progress. Opening a new invite link will stop it.';

  @override
  String get shareLinkLeaveTransferConfirm => 'Leave and open link';

  @override
  String get shareLinkLeaveTransferCancel => 'Keep transferring';
}
