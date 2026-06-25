import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Bottom nav label for the Home tab
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get navHome;

  /// Bottom nav label for the History tab
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get navHistory;

  /// Bottom nav label for the Settings tab
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get navSettings;

  /// Placeholder text in the Home search field
  ///
  /// In vi, this message translates to:
  /// **'Tìm file đã gửi hoặc nhận...'**
  String get homeSearchHint;

  /// Hero card label for total bytes sent
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi'**
  String get homeSent;

  /// Hero card label for total bytes received
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận'**
  String get homeReceived;

  /// Hero card monthly transfer count
  ///
  /// In vi, this message translates to:
  /// **'{count} lượt truyền trong tháng này'**
  String homeMonthlyTransfers(int count);

  /// Stat tile label for photos
  ///
  /// In vi, this message translates to:
  /// **'Ảnh'**
  String get homeStatPhotos;

  /// Stat tile label for videos
  ///
  /// In vi, this message translates to:
  /// **'Video'**
  String get homeStatVideos;

  /// Stat tile label for files
  ///
  /// In vi, this message translates to:
  /// **'File'**
  String get homeStatFiles;

  /// Section title: recent images
  ///
  /// In vi, this message translates to:
  /// **'Ảnh gần đây'**
  String get homeRecentImages;

  /// Section title: recent videos
  ///
  /// In vi, this message translates to:
  /// **'Video gần đây'**
  String get homeRecentVideos;

  /// Section title: recent files
  ///
  /// In vi, this message translates to:
  /// **'File gần đây'**
  String get homeRecentFiles;

  /// Section title: recent transfers
  ///
  /// In vi, this message translates to:
  /// **'Lượt truyền gần đây'**
  String get homeRecentTransfers;

  /// See-all affordance for Home sections
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get homeSeeAll;

  /// Section title: quick actions
  ///
  /// In vi, this message translates to:
  /// **'Thao tác nhanh'**
  String get homeQuickActions;

  /// Quick action: send files
  ///
  /// In vi, this message translates to:
  /// **'Gửi file'**
  String get homeActionSend;

  /// Quick action subtitle: send
  ///
  /// In vi, this message translates to:
  /// **'Chọn & gửi đi'**
  String get homeActionSendSub;

  /// Quick action: receive files
  ///
  /// In vi, this message translates to:
  /// **'Nhận file'**
  String get homeActionReceive;

  /// Quick action subtitle: receive
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã 6 số'**
  String get homeActionReceiveSub;

  /// Quick action: scan QR
  ///
  /// In vi, this message translates to:
  /// **'Quét QR'**
  String get homeActionScanQr;

  /// Quick action subtitle: scan QR
  ///
  /// In vi, this message translates to:
  /// **'Kết nối nhanh'**
  String get homeActionScanQrSub;

  /// Quick action: nearby devices
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị gần'**
  String get homeActionNearby;

  /// Quick action subtitle: nearby
  ///
  /// In vi, this message translates to:
  /// **'Truyền tức thì'**
  String get homeActionNearbySub;

  /// Tip card title
  ///
  /// In vi, this message translates to:
  /// **'Mẹo nhỏ'**
  String get homeTipTitle;

  /// Tip card body
  ///
  /// In vi, this message translates to:
  /// **'Giữ một file để gửi, đổi tên hoặc xoá nhanh.'**
  String get homeTipBody;

  /// Tip card call to action
  ///
  /// In vi, this message translates to:
  /// **'Tìm hiểu'**
  String get homeTipCta;

  /// Primary action: Send
  ///
  /// In vi, this message translates to:
  /// **'Gửi'**
  String get actionSend;

  /// Primary action: Receive
  ///
  /// In vi, this message translates to:
  /// **'Nhận'**
  String get actionReceive;

  /// Coming-soon placeholder title
  ///
  /// In vi, this message translates to:
  /// **'Sắp ra mắt'**
  String get comingSoonTitle;

  /// Send flow placeholder body
  ///
  /// In vi, this message translates to:
  /// **'Tính năng gửi file sẽ sớm có mặt.'**
  String get sendComingSoonBody;

  /// Receive flow placeholder body
  ///
  /// In vi, this message translates to:
  /// **'Tính năng nhận file sẽ sớm có mặt.'**
  String get receiveComingSoonBody;

  /// History tab title
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get historyTitle;

  /// History empty state title
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lượt truyền nào'**
  String get historyEmptyTitle;

  /// History empty state body
  ///
  /// In vi, this message translates to:
  /// **'File bạn gửi và nhận sẽ hiển thị ở đây.'**
  String get historyEmptyBody;

  /// Generic label for the sender of a received transfer (until #010)
  ///
  /// In vi, this message translates to:
  /// **'Người gửi'**
  String get historyPeerSender;

  /// Generic label for the recipient of a sent transfer (until #010)
  ///
  /// In vi, this message translates to:
  /// **'Người nhận'**
  String get historyPeerReceiver;

  /// History day-section header for today
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get historyToday;

  /// History day-section header for yesterday
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get historyYesterday;

  /// Number of files in a transfer record
  ///
  /// In vi, this message translates to:
  /// **'{count} tệp'**
  String historyFilesCount(int count);

  /// History meta: a partial transfer outcome
  ///
  /// In vi, this message translates to:
  /// **'Một phần'**
  String get historyStatusPartial;

  /// History meta: a failed transfer outcome
  ///
  /// In vi, this message translates to:
  /// **'Thất bại'**
  String get historyStatusFailed;

  /// History meta: a cancelled transfer outcome
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ'**
  String get historyStatusCancelled;

  /// History no-results (active filter) title
  ///
  /// In vi, this message translates to:
  /// **'Không có kết quả'**
  String get historyNoResultsTitle;

  /// History no-results (active filter) body
  ///
  /// In vi, this message translates to:
  /// **'Thử đổi từ khoá hoặc bộ lọc.'**
  String get historyNoResultsBody;

  /// History detail page title
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết'**
  String get historyDetailTitle;

  /// Back button label on the History detail page
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get historyBack;

  /// Detail header for a sent transfer
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi'**
  String get historyDirectionSent;

  /// Detail header for a received transfer
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận'**
  String get historyDirectionReceived;

  /// Detail field label: status
  ///
  /// In vi, this message translates to:
  /// **'Trạng thái'**
  String get historyFieldStatus;

  /// Detail field label: pairing method
  ///
  /// In vi, this message translates to:
  /// **'Phương thức ghép nối'**
  String get historyFieldMethod;

  /// Detail field label: date/time
  ///
  /// In vi, this message translates to:
  /// **'Thời gian'**
  String get historyFieldDate;

  /// Detail section label: files
  ///
  /// In vi, this message translates to:
  /// **'Tệp'**
  String get historyFieldFiles;

  /// Status label: completed
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get historyStatusCompleted;

  /// Pairing method: 6-digit code
  ///
  /// In vi, this message translates to:
  /// **'Mã 6 số'**
  String get historyMethodSixDigit;

  /// Pairing method: QR
  ///
  /// In vi, this message translates to:
  /// **'Mã QR'**
  String get historyMethodQr;

  /// Pairing method: share link
  ///
  /// In vi, this message translates to:
  /// **'Link mời'**
  String get historyMethodShareLink;

  /// Pairing method: nearby radar
  ///
  /// In vi, this message translates to:
  /// **'Gần đây'**
  String get historyMethodNearby;

  /// History search field placeholder
  ///
  /// In vi, this message translates to:
  /// **'Tìm theo người hoặc tên tệp'**
  String get historySearchHint;

  /// Direction filter: all
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get historyFilterAll;

  /// Date filter button label
  ///
  /// In vi, this message translates to:
  /// **'Ngày'**
  String get historyFilterDate;

  /// Clear all filters button label
  ///
  /// In vi, this message translates to:
  /// **'Xoá lọc'**
  String get historyFilterClear;

  /// Re-send a previous transfer
  ///
  /// In vi, this message translates to:
  /// **'Gửi lại'**
  String get historyActionResend;

  /// Open a received file
  ///
  /// In vi, this message translates to:
  /// **'Mở'**
  String get historyActionOpen;

  /// Share received files
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get historyActionShare;

  /// Delete a history record
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get historyActionDelete;

  /// Clear all history
  ///
  /// In vi, this message translates to:
  /// **'Xoá tất cả'**
  String get historyClearAll;

  /// Cancel a confirmation dialog
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get historyCancel;

  /// Delete-record confirm title
  ///
  /// In vi, this message translates to:
  /// **'Xoá mục này?'**
  String get historyDeleteConfirmTitle;

  /// Delete-record confirm body
  ///
  /// In vi, this message translates to:
  /// **'Chỉ xoá khỏi lịch sử — tệp trên máy vẫn được giữ.'**
  String get historyDeleteConfirmBody;

  /// Clear-all confirm title
  ///
  /// In vi, this message translates to:
  /// **'Xoá tất cả lịch sử?'**
  String get historyClearConfirmTitle;

  /// Clear-all confirm body
  ///
  /// In vi, this message translates to:
  /// **'Mọi mục sẽ bị xoá — tệp trên máy vẫn được giữ.'**
  String get historyClearConfirmBody;

  /// Toast when a recorded file is missing
  ///
  /// In vi, this message translates to:
  /// **'Tệp không còn khả dụng'**
  String get historyFileUnavailable;

  /// Home recent-transfers empty state
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lượt truyền nào gần đây.'**
  String get homeNoRecent;

  /// Settings tab title
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// Device profile subtitle
  ///
  /// In vi, this message translates to:
  /// **'hiển thị với thiết bị gần đây'**
  String get settingsProfileSub;

  /// Setting: auto-receive
  ///
  /// In vi, this message translates to:
  /// **'Tự động nhận'**
  String get settingsAutoReceive;

  /// Setting subtitle: auto-receive
  ///
  /// In vi, this message translates to:
  /// **'Từ thiết bị đã tin tưởng'**
  String get settingsAutoReceiveSub;

  /// Setting: save to library
  ///
  /// In vi, this message translates to:
  /// **'Lưu vào Thư viện'**
  String get settingsSaveToLibrary;

  /// Setting subtitle: save to library
  ///
  /// In vi, this message translates to:
  /// **'Ảnh & video nhận được'**
  String get settingsSaveToLibrarySub;

  /// Setting: notifications
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get settingsNotifications;

  /// Setting subtitle: notifications
  ///
  /// In vi, this message translates to:
  /// **'Khi có file mới'**
  String get settingsNotificationsSub;

  /// Setting: dark mode
  ///
  /// In vi, this message translates to:
  /// **'Giao diện tối'**
  String get settingsDarkMode;

  /// Setting subtitle: dark mode
  ///
  /// In vi, this message translates to:
  /// **'Theo hệ thống'**
  String get settingsDarkModeSub;

  /// Settings footer version line
  ///
  /// In vi, this message translates to:
  /// **'Safe Send v{version} · WebRTC P2P'**
  String settingsVersion(String version);

  /// Back affordance label
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get commonBack;

  /// Pairing error: invalid/unknown code
  ///
  /// In vi, this message translates to:
  /// **'Mã không đúng'**
  String get pairingErrorInvalidCode;

  /// Pairing error: room already full
  ///
  /// In vi, this message translates to:
  /// **'Phòng đã đủ hai thiết bị'**
  String get pairingErrorRoomFull;

  /// Pairing error: code expired
  ///
  /// In vi, this message translates to:
  /// **'Mã đã hết hạn'**
  String get pairingErrorRoomExpired;

  /// Pairing error: rate limited
  ///
  /// In vi, this message translates to:
  /// **'Thử quá nhiều lần, vui lòng đợi'**
  String get pairingErrorRateLimited;

  /// Pairing error: signaling unreachable
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được máy chủ'**
  String get pairingErrorUnreachable;

  /// Pairing error: signaling timeout
  ///
  /// In vi, this message translates to:
  /// **'Kết nối quá thời gian'**
  String get pairingErrorTimeout;

  /// Pairing error: peer connection lost
  ///
  /// In vi, this message translates to:
  /// **'Mất kết nối với thiết bị kia'**
  String get pairingErrorConnectionLost;

  /// Pairing error: generic fallback
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra lỗi, vui lòng thử lại'**
  String get pairingErrorGeneric;

  /// Send file-selection screen title
  ///
  /// In vi, this message translates to:
  /// **'Gửi file'**
  String get sendTitle;

  /// Selection header: item count + total size
  ///
  /// In vi, this message translates to:
  /// **'{count} mục · {size}'**
  String sendSelectedSummary(int count, String size);

  /// Add more files button
  ///
  /// In vi, this message translates to:
  /// **'Thêm'**
  String get sendAdd;

  /// Continue to pairing button
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục'**
  String get sendContinue;

  /// Empty selection title
  ///
  /// In vi, this message translates to:
  /// **'Chưa chọn file nào'**
  String get sendEmptyTitle;

  /// Empty selection body
  ///
  /// In vi, this message translates to:
  /// **'Nhấn Thêm để chọn file gửi đi'**
  String get sendEmptyBody;

  /// Remove a file from selection (semantic label)
  ///
  /// In vi, this message translates to:
  /// **'Bỏ chọn'**
  String get sendRemove;

  /// Connect/pairing hub title
  ///
  /// In vi, this message translates to:
  /// **'Kết nối thiết bị'**
  String get connectTitle;

  /// Connect tab: 6-digit code
  ///
  /// In vi, this message translates to:
  /// **'Mã 6 số'**
  String get connectTabCode;

  /// Connect tab: QR
  ///
  /// In vi, this message translates to:
  /// **'QR'**
  String get connectTabQr;

  /// Connect tab: nearby
  ///
  /// In vi, this message translates to:
  /// **'Gần đây'**
  String get connectTabNearby;

  /// Instruction above the code
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ mã này với người nhận'**
  String get connectShareInstruction;

  /// Code expiry countdown
  ///
  /// In vi, this message translates to:
  /// **'Hết hạn sau {time}'**
  String connectExpiresIn(String time);

  /// Waiting-for-peer status
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ thiết bị kia kết nối…'**
  String get connectWaiting;

  /// Share invite link action (stub)
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ link mời'**
  String get connectShareLink;

  /// Get a fresh code action
  ///
  /// In vi, this message translates to:
  /// **'Lấy mã mới'**
  String get connectRefreshCode;

  /// Disabled tab placeholder
  ///
  /// In vi, this message translates to:
  /// **'Tính năng này sắp ra mắt'**
  String get connectComingSoonTab;

  /// Sending status badge
  ///
  /// In vi, this message translates to:
  /// **'ĐANG GỬI'**
  String get sendProgressBadge;

  /// Generic destination-peer label (until #010)
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị nhận'**
  String get sendPeerReceiver;

  /// Destination line on progress
  ///
  /// In vi, this message translates to:
  /// **'tới {peer}'**
  String sendProgressTo(String peer);

  /// Current file position in the batch
  ///
  /// In vi, this message translates to:
  /// **'file {index}/{total}'**
  String sendProgressFilePosition(int index, int total);

  /// Time remaining
  ///
  /// In vi, this message translates to:
  /// **'còn {time}'**
  String sendProgressRemaining(String time);

  /// Cancel transfer button
  ///
  /// In vi, this message translates to:
  /// **'Hủy'**
  String get sendCancel;

  /// Cancel confirmation title
  ///
  /// In vi, this message translates to:
  /// **'Hủy lượt gửi?'**
  String get sendCancelConfirmTitle;

  /// Cancel confirmation body
  ///
  /// In vi, this message translates to:
  /// **'Lượt truyền đang diễn ra sẽ bị dừng.'**
  String get sendCancelConfirmBody;

  /// Dismiss cancel dialog (keep sending)
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục gửi'**
  String get sendCancelConfirmKeep;

  /// Completion title
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất!'**
  String get sendCompleteTitle;

  /// Completion summary line
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi {count} file · {size} tới {peer} trong {duration}'**
  String sendCompleteDetail(
    int count,
    String size,
    String peer,
    String duration,
  );

  /// Finish (return home) button
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get sendDone;

  /// Start a new send button
  ///
  /// In vi, this message translates to:
  /// **'Gửi tiếp'**
  String get sendAgain;

  /// Send failure title
  ///
  /// In vi, this message translates to:
  /// **'Gửi thất bại'**
  String get sendErrorTitle;

  /// Retry the send
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get sendRetry;

  /// Receiver declined the transfer
  ///
  /// In vi, this message translates to:
  /// **'Người nhận đã từ chối'**
  String get sendErrorRejected;

  /// A selected file could not be read
  ///
  /// In vi, this message translates to:
  /// **'Không đọc được file đã chọn'**
  String get sendErrorFileRead;

  /// Receiver code-entry title
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã'**
  String get receiveEnterCodeTitle;

  /// Receiver code-entry instruction
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã 6 số từ người gửi'**
  String get receiveEnterCodeInstruction;

  /// Receiver connect button
  ///
  /// In vi, this message translates to:
  /// **'Kết nối'**
  String get receiveConnect;

  /// Receiver connecting state
  ///
  /// In vi, this message translates to:
  /// **'Đang kết nối…'**
  String get receiveConnecting;

  /// Generic sender label until #010
  ///
  /// In vi, this message translates to:
  /// **'Người gửi'**
  String get receivePeerSender;

  /// Incoming transfer prompt title
  ///
  /// In vi, this message translates to:
  /// **'{peer} muốn gửi cho bạn'**
  String receivePromptTitle(String peer);

  /// Incoming transfer prompt body
  ///
  /// In vi, this message translates to:
  /// **'{count} tệp · {size}'**
  String receivePromptBody(int count, String size);

  /// Accept incoming transfer
  ///
  /// In vi, this message translates to:
  /// **'Nhận'**
  String get receiveAccept;

  /// Reject incoming transfer
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get receiveReject;

  /// Receive progress badge
  ///
  /// In vi, this message translates to:
  /// **'ĐANG NHẬN'**
  String get receiveProgressBadge;

  /// Receiving from peer
  ///
  /// In vi, this message translates to:
  /// **'từ {peer}'**
  String receiveProgressFrom(String peer);

  /// Current file position
  ///
  /// In vi, this message translates to:
  /// **'tệp {index}/{total}'**
  String receiveProgressFilePosition(int index, int total);

  /// ETA remaining
  ///
  /// In vi, this message translates to:
  /// **'còn {time}'**
  String receiveProgressRemaining(String time);

  /// Cancel receive button
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get receiveCancel;

  /// Cancel-receive confirm title
  ///
  /// In vi, this message translates to:
  /// **'Huỷ lượt nhận?'**
  String get receiveCancelConfirmTitle;

  /// Cancel-receive confirm body
  ///
  /// In vi, this message translates to:
  /// **'Lượt nhận đang diễn ra sẽ dừng. Các tệp đã nhận xong vẫn được giữ.'**
  String get receiveCancelConfirmBody;

  /// Keep receiving
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục nhận'**
  String get receiveCancelConfirmKeep;

  /// Receive complete title
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận xong'**
  String get receiveCompleteTitle;

  /// Receive complete summary
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận {count} tệp · {size} từ {peer} trong {duration}'**
  String receiveCompleteDetail(
    int count,
    String size,
    String peer,
    String duration,
  );

  /// Partial receive title
  ///
  /// In vi, this message translates to:
  /// **'Nhận chưa đủ'**
  String get receivePartialTitle;

  /// Partial receive summary
  ///
  /// In vi, this message translates to:
  /// **'Đã nhận {received}/{total} tệp · {size}'**
  String receivePartialDetail(int received, int total, String size);

  /// Open a received file
  ///
  /// In vi, this message translates to:
  /// **'Mở'**
  String get receiveOpen;

  /// Share received files
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get receiveShare;

  /// Finish receive (return home)
  ///
  /// In vi, this message translates to:
  /// **'Xong'**
  String get receiveDone;

  /// Receive failure title
  ///
  /// In vi, this message translates to:
  /// **'Nhận thất bại'**
  String get receiveErrorTitle;

  /// Retry receive
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get receiveRetry;

  /// Integrity check failed
  ///
  /// In vi, this message translates to:
  /// **'Tệp lỗi khi kiểm tra — nhận lại'**
  String get receiveErrorIntegrity;

  /// File write failed
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được tệp vào thiết bị'**
  String get receiveErrorWrite;

  /// Connection lost while receiving
  ///
  /// In vi, this message translates to:
  /// **'Mất kết nối khi đang nhận'**
  String get receiveErrorConnectionLost;

  /// Open file failed toast
  ///
  /// In vi, this message translates to:
  /// **'Không mở được tệp này'**
  String get receiveOpenFailed;

  /// Share failed toast
  ///
  /// In vi, this message translates to:
  /// **'Không chia sẻ được'**
  String get receiveShareFailed;

  /// Divider between two alternative actions
  ///
  /// In vi, this message translates to:
  /// **'hoặc'**
  String get commonOr;

  /// Button on the receive screen that opens the QR scanner (#007)
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR'**
  String get receiveScanQr;

  /// Instruction above the QR on the sender Connect QR tab
  ///
  /// In vi, this message translates to:
  /// **'Để người nhận quét mã QR này'**
  String get connectQrInstruction;

  /// Accessibility label for the rendered pairing QR
  ///
  /// In vi, this message translates to:
  /// **'Mã QR chứa mã kết nối {code}'**
  String connectQrCodeLabel(String code);

  /// Title of the full-screen QR scanner
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR'**
  String get scanTitle;

  /// Instruction on the QR scanner
  ///
  /// In vi, this message translates to:
  /// **'Hướng camera vào mã QR của người gửi'**
  String get scanInstruction;

  /// Torch/flashlight toggle label on the scanner
  ///
  /// In vi, this message translates to:
  /// **'Đèn pin'**
  String get scanTorch;

  /// Action to pick a QR image from the photo library
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh có mã QR'**
  String get scanPickImage;

  /// Toast when a scanned QR is not a valid Safe Send code
  ///
  /// In vi, this message translates to:
  /// **'Đây không phải mã Safe Send'**
  String get scanInvalidCode;

  /// Toast when a picked image has no valid QR
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy mã QR trong ảnh'**
  String get scanNoCodeFound;

  /// Title shown when camera permission is blocked
  ///
  /// In vi, this message translates to:
  /// **'Cần quyền camera'**
  String get scanCameraBlockedTitle;

  /// Body shown when camera permission is blocked
  ///
  /// In vi, this message translates to:
  /// **'Cho phép Safe Send dùng camera để quét, hoặc chọn ảnh có sẵn mã QR.'**
  String get scanCameraBlockedBody;

  /// Open the OS app settings to grant camera
  ///
  /// In vi, this message translates to:
  /// **'Mở Cài đặt'**
  String get scanOpenSettings;

  /// Request camera permission button
  ///
  /// In vi, this message translates to:
  /// **'Cho phép camera'**
  String get scanRequestPermission;

  /// Invite text shared alongside the share-link (#008)
  ///
  /// In vi, this message translates to:
  /// **'Mình muốn gửi bạn vài tệp qua Safe Send — chạm vào link để nhận:'**
  String get connectShareLinkMessage;

  /// Toast when an opened invite link is malformed or not a Safe Send link
  ///
  /// In vi, this message translates to:
  /// **'Link mời không hợp lệ'**
  String get shareLinkInvalid;

  /// Toast when an opened invite link's code has expired
  ///
  /// In vi, this message translates to:
  /// **'Link mời đã hết hạn'**
  String get shareLinkExpired;

  /// Toast when the host taps their own invite link
  ///
  /// In vi, this message translates to:
  /// **'Đây là link mời của chính bạn'**
  String get shareLinkOwn;

  /// Confirm dialog title when an invite link arrives during a transfer
  ///
  /// In vi, this message translates to:
  /// **'Rời phiên truyền hiện tại?'**
  String get shareLinkLeaveTransferTitle;

  /// Confirm dialog body when an invite link arrives during a transfer
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang truyền tệp. Mở link mời mới sẽ dừng phiên hiện tại.'**
  String get shareLinkLeaveTransferBody;

  /// Confirm-and-leave action in the interrupt dialog
  ///
  /// In vi, this message translates to:
  /// **'Rời và mở link'**
  String get shareLinkLeaveTransferConfirm;

  /// Cancel (keep transferring) action in the interrupt dialog
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục truyền'**
  String get shareLinkLeaveTransferCancel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
