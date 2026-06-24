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
}
