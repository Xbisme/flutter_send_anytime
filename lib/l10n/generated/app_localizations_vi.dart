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
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsProfileSub => 'hiển thị với thiết bị gần đây';

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
}
