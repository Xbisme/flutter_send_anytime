// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navHistory => 'Lịch sử';

  @override
  String get navSettings => 'Cài đặt';

  @override
  String get homeSearchHint => 'Tìm file đã gửi hoặc nhận...';

  @override
  String get homeSent => 'Đã gửi';

  @override
  String get homeReceived => 'Đã nhận';

  @override
  String homeMonthlyTransfers(int count) {
    return '$count lượt truyền trong tháng này';
  }

  @override
  String get homeStatPhotos => 'Ảnh';

  @override
  String get homeStatVideos => 'Video';

  @override
  String get homeStatFiles => 'File';

  @override
  String get homeRecentImages => 'Ảnh gần đây';

  @override
  String get homeRecentVideos => 'Video gần đây';

  @override
  String get homeRecentFiles => 'File gần đây';

  @override
  String get homeRecentTransfers => 'Lượt truyền gần đây';

  @override
  String get homeSeeAll => 'Xem tất cả';

  @override
  String get homeNoImages => 'Chưa có ảnh nào.';

  @override
  String get homeNoVideos => 'Chưa có video nào.';

  @override
  String get homeNoFiles => 'Chưa có tệp nào.';

  @override
  String get homeSeeAllPhotos => 'Tất cả ảnh';

  @override
  String get homeSeeAllVideos => 'Tất cả video';

  @override
  String get homeSeeAllFiles => 'Tất cả tệp';

  @override
  String get homeFileUnavailable => 'Không tìm thấy tệp trên thiết bị.';

  @override
  String get homeQuickActions => 'Thao tác nhanh';

  @override
  String get homeActionSend => 'Gửi file';

  @override
  String get homeActionSendSub => 'Chọn & gửi đi';

  @override
  String get homeActionReceive => 'Nhận file';

  @override
  String get homeActionReceiveSub => 'Nhập mã 6 số';

  @override
  String get homeActionScanQr => 'Quét QR';

  @override
  String get homeActionScanQrSub => 'Kết nối nhanh';

  @override
  String get homeActionNearby => 'Thiết bị gần';

  @override
  String get homeActionNearbySub => 'Truyền tức thì';

  @override
  String get homeTipTitle => 'Mẹo nhỏ';

  @override
  String get homeTipBody => 'Giữ một file để gửi, đổi tên hoặc xoá nhanh.';

  @override
  String get homeTipCta => 'Tìm hiểu';

  @override
  String get actionSend => 'Gửi';

  @override
  String get actionReceive => 'Nhận';

  @override
  String get comingSoonTitle => 'Sắp ra mắt';

  @override
  String get sendComingSoonBody => 'Tính năng gửi file sẽ sớm có mặt.';

  @override
  String get receiveComingSoonBody => 'Tính năng nhận file sẽ sớm có mặt.';

  @override
  String get historyTitle => 'Lịch sử';

  @override
  String get historyEmptyTitle => 'Chưa có lượt truyền nào';

  @override
  String get historyEmptyBody => 'File bạn gửi và nhận sẽ hiển thị ở đây.';

  @override
  String get historyPeerSender => 'Người gửi';

  @override
  String get historyPeerReceiver => 'Người nhận';

  @override
  String get historyToday => 'Hôm nay';

  @override
  String get historyYesterday => 'Hôm qua';

  @override
  String historyFilesCount(int count) {
    return '$count tệp';
  }

  @override
  String get historyStatusPartial => 'Một phần';

  @override
  String get historyStatusFailed => 'Thất bại';

  @override
  String get historyStatusCancelled => 'Đã huỷ';

  @override
  String get historyNoResultsTitle => 'Không có kết quả';

  @override
  String get historyNoResultsBody => 'Thử đổi từ khoá hoặc bộ lọc.';

  @override
  String get historyDetailTitle => 'Chi tiết';

  @override
  String get historyBack => 'Quay lại';

  @override
  String get historyDirectionSent => 'Đã gửi';

  @override
  String get historyDirectionReceived => 'Đã nhận';

  @override
  String get historyFieldStatus => 'Trạng thái';

  @override
  String get historyFieldMethod => 'Phương thức ghép nối';

  @override
  String get historyFieldDate => 'Thời gian';

  @override
  String get historyFieldFiles => 'Tệp';

  @override
  String get historyStatusCompleted => 'Hoàn tất';

  @override
  String get historyMethodSixDigit => 'Mã 6 số';

  @override
  String get historyMethodQr => 'Mã QR';

  @override
  String get historyMethodShareLink => 'Link mời';

  @override
  String get historyMethodNearby => 'Gần đây';

  @override
  String get historySearchHint => 'Tìm theo người hoặc tên tệp';

  @override
  String get historyFilterAll => 'Tất cả';

  @override
  String get historyFilterDate => 'Ngày';

  @override
  String get historyFilterClear => 'Xoá lọc';

  @override
  String get historyActionResend => 'Gửi lại';

  @override
  String get historyActionOpen => 'Mở';

  @override
  String get historyActionShare => 'Chia sẻ';

  @override
  String get historyActionDelete => 'Xoá';

  @override
  String get historyClearAll => 'Xoá tất cả';

  @override
  String get historyCancel => 'Huỷ';

  @override
  String get historyDeleteConfirmTitle => 'Xoá mục này?';

  @override
  String get historyDeleteConfirmBody =>
      'Chỉ xoá khỏi lịch sử — tệp trên máy vẫn được giữ.';

  @override
  String get historyClearConfirmTitle => 'Xoá tất cả lịch sử?';

  @override
  String get historyClearConfirmBody =>
      'Mọi mục sẽ bị xoá — tệp trên máy vẫn được giữ.';

  @override
  String get historyFileUnavailable => 'Tệp không còn khả dụng';

  @override
  String get homeNoRecent => 'Chưa có lượt truyền nào gần đây.';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsProfileSub => 'hiển thị với thiết bị gần đây';

  @override
  String get settingsProfileEditTitle => 'Đổi tên thiết bị';

  @override
  String get settingsProfileNameHint => 'Tên thiết bị';

  @override
  String get settingsProfileNameError => 'Tên phải từ 1 đến 30 ký tự';

  @override
  String get settingsPermissionBlocked =>
      'Cần cấp quyền trong Cài đặt để dùng tính năng này';

  @override
  String get settingsSectionAppearance => 'Giao diện';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsThemeSystem => 'Theo hệ thống';

  @override
  String get settingsSectionLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageVi => 'Tiếng Việt';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageSystem => 'Theo hệ thống';

  @override
  String get settingsSectionAdvanced => 'Nâng cao';

  @override
  String get settingsEndpointHint => 'wss://máy-chủ-của-bạn';

  @override
  String get settingsEndpointInvalid => 'Địa chỉ máy chủ không hợp lệ';

  @override
  String get settingsEndpointClear => 'Khôi phục mặc định';

  @override
  String get settingsDiagnosticRun => 'Kiểm tra kết nối';

  @override
  String get settingsDiagnosticReachable => 'Kết nối được máy chủ';

  @override
  String get settingsDiagnosticUnreachable => 'Không kết nối được máy chủ';

  @override
  String get settingsSectionAbout => 'Giới thiệu';

  @override
  String get settingsHowItWorks => 'Cách hoạt động';

  @override
  String get settingsPrivacy => 'Chính sách bảo mật';

  @override
  String get settingsRate => 'Đánh giá ứng dụng';

  @override
  String get settingsHowItWorksBody =>
      'Safe Send gửi tệp trực tiếp giữa hai thiết bị qua kết nối WebRTC được mã hóa đầu-cuối. Máy chủ tín hiệu chỉ giúp hai máy tìm thấy nhau — nó không bao giờ nhận, lưu hay nhìn thấy nội dung tệp của bạn. Khi không thể kết nối trực tiếp, một máy chủ chuyển tiếp (TURN) có thể được dùng, nhưng dữ liệu vẫn được mã hóa và không bao giờ bị lưu lại.';

  @override
  String get settingsPrivacyBody =>
      'Safe Send không có tài khoản, không có máy chủ đám mây, và không thu thập nội dung tệp của bạn. Cài đặt và lịch sử truyền chỉ được lưu trên thiết bị này. Tên thiết bị bạn đặt chỉ hiển thị cho các thiết bị bạn kết nối trực tiếp.';

  @override
  String get settingsAutoReceive => 'Tự động nhận';

  @override
  String get settingsAutoReceiveSub => 'Từ thiết bị đã tin tưởng';

  @override
  String get settingsSaveToLibrary => 'Lưu vào Thư viện';

  @override
  String get settingsSaveToLibrarySub => 'Ảnh & video nhận được';

  @override
  String get settingsNotifications => 'Thông báo';

  @override
  String get settingsNotificationsSub => 'Khi có file mới';

  @override
  String get settingsDarkMode => 'Giao diện tối';

  @override
  String get settingsDarkModeSub => 'Theo hệ thống';

  @override
  String settingsVersion(String version) {
    return 'Safe Send v$version · WebRTC P2P';
  }

  @override
  String get commonBack => 'Quay lại';

  @override
  String get commonSave => 'Lưu';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get pairingErrorInvalidCode => 'Mã không đúng';

  @override
  String get pairingErrorRoomFull => 'Phòng đã đủ hai thiết bị';

  @override
  String get pairingErrorRoomExpired => 'Mã đã hết hạn';

  @override
  String get pairingErrorRateLimited => 'Thử quá nhiều lần, vui lòng đợi';

  @override
  String get pairingErrorUnreachable => 'Không kết nối được máy chủ';

  @override
  String get pairingErrorTimeout => 'Kết nối quá thời gian';

  @override
  String get pairingErrorConnectionLost => 'Mất kết nối với thiết bị kia';

  @override
  String get pairingErrorGeneric => 'Đã xảy ra lỗi, vui lòng thử lại';

  @override
  String get sendTitle => 'Gửi file';

  @override
  String sendSelectedSummary(int count, String size) {
    return '$count mục · $size';
  }

  @override
  String get sendAdd => 'Thêm';

  @override
  String get sendContinue => 'Tiếp tục';

  @override
  String get sendEmptyTitle => 'Chưa chọn file nào';

  @override
  String get sendEmptyBody => 'Nhấn Thêm để chọn file gửi đi';

  @override
  String get sendRemove => 'Bỏ chọn';

  @override
  String get connectTitle => 'Kết nối thiết bị';

  @override
  String get connectTabCode => 'Mã 6 số';

  @override
  String get connectTabQr => 'QR';

  @override
  String get connectTabNearby => 'Gần đây';

  @override
  String get connectShareInstruction => 'Chia sẻ mã này với người nhận';

  @override
  String connectExpiresIn(String time) {
    return 'Hết hạn sau $time';
  }

  @override
  String get connectWaiting => 'Đang chờ thiết bị kia kết nối…';

  @override
  String get connectShareLink => 'Chia sẻ link mời';

  @override
  String get connectRefreshCode => 'Lấy mã mới';

  @override
  String get connectComingSoonTab => 'Tính năng này sắp ra mắt';

  @override
  String get sendProgressBadge => 'ĐANG GỬI';

  @override
  String get sendPeerReceiver => 'Thiết bị nhận';

  @override
  String sendProgressTo(String peer) {
    return 'tới $peer';
  }

  @override
  String sendProgressFilePosition(int index, int total) {
    return 'file $index/$total';
  }

  @override
  String sendProgressRemaining(String time) {
    return 'còn $time';
  }

  @override
  String get sendCancel => 'Hủy';

  @override
  String get sendCancelConfirmTitle => 'Hủy lượt gửi?';

  @override
  String get sendCancelConfirmBody => 'Lượt truyền đang diễn ra sẽ bị dừng.';

  @override
  String get sendCancelConfirmKeep => 'Tiếp tục gửi';

  @override
  String get sendCompleteTitle => 'Hoàn tất!';

  @override
  String sendCompleteDetail(
    int count,
    String size,
    String peer,
    String duration,
  ) {
    return 'Đã gửi $count file · $size tới $peer trong $duration';
  }

  @override
  String get sendDone => 'Xong';

  @override
  String get sendAgain => 'Gửi tiếp';

  @override
  String get sendErrorTitle => 'Gửi thất bại';

  @override
  String get sendRetry => 'Thử lại';

  @override
  String get sendErrorRejected => 'Người nhận đã từ chối';

  @override
  String get sendErrorFileRead => 'Không đọc được file đã chọn';

  @override
  String get receiveEnterCodeTitle => 'Nhập mã';

  @override
  String get receiveEnterCodeInstruction => 'Nhập mã 6 số từ người gửi';

  @override
  String get receiveConnect => 'Kết nối';

  @override
  String get receiveConnecting => 'Đang kết nối…';

  @override
  String get receivePeerSender => 'Người gửi';

  @override
  String receivePromptTitle(String peer) {
    return '$peer muốn gửi cho bạn';
  }

  @override
  String receivePromptBody(int count, String size) {
    return '$count tệp · $size';
  }

  @override
  String get receiveAccept => 'Nhận';

  @override
  String get receiveReject => 'Từ chối';

  @override
  String get receiveProgressBadge => 'ĐANG NHẬN';

  @override
  String receiveProgressFrom(String peer) {
    return 'từ $peer';
  }

  @override
  String receiveProgressFilePosition(int index, int total) {
    return 'tệp $index/$total';
  }

  @override
  String receiveProgressRemaining(String time) {
    return 'còn $time';
  }

  @override
  String get receiveCancel => 'Huỷ';

  @override
  String get receiveCancelConfirmTitle => 'Huỷ lượt nhận?';

  @override
  String get receiveCancelConfirmBody =>
      'Lượt nhận đang diễn ra sẽ dừng. Các tệp đã nhận xong vẫn được giữ.';

  @override
  String get receiveCancelConfirmKeep => 'Tiếp tục nhận';

  @override
  String get receiveCompleteTitle => 'Đã nhận xong';

  @override
  String receiveCompleteDetail(
    int count,
    String size,
    String peer,
    String duration,
  ) {
    return 'Đã nhận $count tệp · $size từ $peer trong $duration';
  }

  @override
  String get receivePartialTitle => 'Nhận chưa đủ';

  @override
  String receivePartialDetail(int received, int total, String size) {
    return 'Đã nhận $received/$total tệp · $size';
  }

  @override
  String get receiveOpen => 'Mở';

  @override
  String get receiveShare => 'Chia sẻ';

  @override
  String get receiveDone => 'Xong';

  @override
  String get receiveErrorTitle => 'Nhận thất bại';

  @override
  String get receiveRetry => 'Thử lại';

  @override
  String get receiveErrorIntegrity => 'Tệp lỗi khi kiểm tra — nhận lại';

  @override
  String get receiveErrorWrite => 'Không lưu được tệp vào thiết bị';

  @override
  String get receiveErrorConnectionLost => 'Mất kết nối khi đang nhận';

  @override
  String get receiveOpenFailed => 'Không mở được tệp này';

  @override
  String get receiveShareFailed => 'Không chia sẻ được';

  @override
  String get commonOr => 'hoặc';

  @override
  String get receiveScanQr => 'Quét mã QR';

  @override
  String get connectQrInstruction => 'Để người nhận quét mã QR này';

  @override
  String connectQrCodeLabel(String code) {
    return 'Mã QR chứa mã kết nối $code';
  }

  @override
  String get scanTitle => 'Quét mã QR';

  @override
  String get scanInstruction => 'Hướng camera vào mã QR của người gửi';

  @override
  String get scanTorch => 'Đèn pin';

  @override
  String get scanPickImage => 'Chọn ảnh có mã QR';

  @override
  String get scanInvalidCode => 'Đây không phải mã Safe Send';

  @override
  String get scanNoCodeFound => 'Không tìm thấy mã QR trong ảnh';

  @override
  String get scanCameraBlockedTitle => 'Cần quyền camera';

  @override
  String get scanCameraBlockedBody =>
      'Cho phép Safe Send dùng camera để quét, hoặc chọn ảnh có sẵn mã QR.';

  @override
  String get scanOpenSettings => 'Mở Cài đặt';

  @override
  String get scanRequestPermission => 'Cho phép camera';

  @override
  String get connectShareLinkMessage =>
      'Mình muốn gửi bạn vài tệp qua Safe Send — chạm vào link để nhận:';

  @override
  String get shareLinkInvalid => 'Link mời không hợp lệ';

  @override
  String get shareLinkExpired => 'Link mời đã hết hạn';

  @override
  String get shareLinkOwn => 'Đây là link mời của chính bạn';

  @override
  String get shareLinkLeaveTransferTitle => 'Rời phiên truyền hiện tại?';

  @override
  String get shareLinkLeaveTransferBody =>
      'Bạn đang truyền tệp. Mở link mời mới sẽ dừng phiên hiện tại.';

  @override
  String get shareLinkLeaveTransferConfirm => 'Rời và mở link';

  @override
  String get shareLinkLeaveTransferCancel => 'Tiếp tục truyền';

  @override
  String get nearbySectionTitle => 'Thiết bị ở gần';

  @override
  String get nearbyDiscoverableTitle => 'Đang hiển thị với thiết bị gần';

  @override
  String get nearbyPrivacyNote =>
      'Tên thiết bị của bạn được phát tới các thiết bị gần.';

  @override
  String get nearbyEmptyTitle => 'Chưa thấy thiết bị nào';

  @override
  String get nearbyEmptyHint =>
      'Đảm bảo cả hai thiết bị ở cùng mạng Wi-Fi, hoặc dùng mã 6 số / QR.';

  @override
  String get nearbyPermissionRationale =>
      'Cho phép tìm thiết bị trên mạng cục bộ để kết nối với thiết bị ở gần.';

  @override
  String get nearbyPermissionBlocked =>
      'Quyền mạng cục bộ đang tắt. Mở Cài đặt để bật và tìm thiết bị gần.';

  @override
  String get nearbyOpenSettings => 'Mở Cài đặt';

  @override
  String get nearbyStaleToast => 'Thiết bị này không còn khả dụng';

  @override
  String get nearbyConnectAction => 'Nhận';

  @override
  String bgSendingTitle(int count) {
    return 'Đang gửi · $count tệp';
  }

  @override
  String bgReceivingTitle(int count) {
    return 'Đang nhận · $count tệp';
  }

  @override
  String bgToPeer(String peer) {
    return 'tới $peer';
  }

  @override
  String bgFromPeer(String peer) {
    return 'từ $peer';
  }

  @override
  String bgEta(String time) {
    return 'còn $time';
  }

  @override
  String get bgCancel => 'Huỷ';

  @override
  String get bgKeepOpenTitle => 'Tiếp tục truyền tệp';

  @override
  String get bgKeepOpenBody =>
      'Mở lại Safe Send để truyền tiếp — iOS tạm dừng khi app ở nền.';
}
