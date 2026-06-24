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
