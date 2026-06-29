# SafeSendWidget — iOS Live Activity (Spec #011)

Widget Extension cho Live Activity (Lock Screen + Dynamic Island) của Background Transfer. **Đã dựng + wiring + compile xong** (xác minh bằng `xcodebuild`: BUILD SUCCEEDED). Chỉ còn việc cần thiết bị/Apple account: chọn **Team** signing rồi chạy lên iPhone thật.

## Đã hoàn tất (2026-06-27)

- ✅ **2 file Swift đúng chuẩn plugin `live_activities`**: `SafeSendWidgetLiveActivity.swift` + `SafeSendWidgetBundle.swift`. ActivityAttributes tên **chính xác** `LiveActivitiesAppAttributes`, đọc data từ App Group qua `UserDefaults(suiteName:)` + `prefixedKey`. Key khớp `BackgroundTransferState.toContentState()` (Dart).
- ✅ **Đã gỡ 2 target `SafeSendWidgetExtension` trùng** (Xcode tạo dư) — giờ còn đúng 1 target. Xác minh `xcodebuild -list`.
- ✅ **App Group tách dev/prod** qua biến `APP_GROUP_ID` (kiểu khai báo như các xcconfig flavor):
  - **dev** → `group.app.safesend.dev.liveactivities` · **prod** → `group.app.safesend.liveactivities`.
  - Runner: `APP_GROUP_ID` khai báo trong `ios/Flutter/<Mode>-<flavor>.xcconfig`. Widget (không có xcconfig): `APP_GROUP_ID` set trong build settings của 9 config.
  - Entitlements cả 2 target dùng `<string>$(APP_GROUP_ID)</string>` → tự resolve theo flavor (`CODE_SIGN_ENTITLEMENTS` đã wire cho cả 9 config mỗi target).
  - Widget Info.plist phơi `AppGroupId = $(APP_GROUP_ID)`; Swift đọc key đó. Dart đọc `AppConfig.liveActivityAppGroupId` (cũng theo flavor) → 3 phía khớp nhau.
  - Widget bundle id cũng tách: dev `app.safesend.dev.SafeSendWidget` / prod `app.safesend.SafeSendWidget`.
- ✅ **`pod install` chạy xong** — `live_activities` + `flutter_foreground_task` pods đã vào `Podfile.lock`.
- ✅ **Widget compile được** (`xcodebuild ... SafeSendWidgetExtension`: BUILD SUCCEEDED).
- ✅ `NSSupportsLiveActivities = YES` trong `Runner/Info.plist`; Android manifest có `<service dataSync>` + `FOREGROUND_SERVICE_DATA_SYNC`.

## Còn lại (cần thiết bị thật + Apple account)

1. Mở `Runner.xcworkspace` → chọn **Team** ở **Signing & Capabilities** cho **Runner** và **SafeSendWidgetExtension** (automatic signing sẽ tự đăng ký App Group với provisioning profile ở lần build đầu).
2. Chạy scheme **dev** lên **iPhone thật iOS 16.1+** (Dynamic Island cần iPhone 14 Pro+). Bắt đầu transfer → Home/khoá máy → Live Activity hiện ở Lock Screen; chạm-giữ pill Dynamic Island để xem bản mở rộng. (= phần two-device smoke T040.)

> Lưu ý đúng spec: iOS **không** giữ transfer dài chạy nền vô hạn (data-channel-only, không hack audio) → transfer ngắn xong trong cửa sổ grace; transfer dài bị iOS suspend → rơi vào nhánh clean-fail + giữ partial + retry (SC-001/SC-005; Android mới là đường chạy-nền-tới-xong).

## Hợp đồng dữ liệu (đừng đổi lệch)

Key trong `ContentState`/UserDefaults PHẢI khớp `BackgroundTransferState.toContentState()` (Dart) và
`specs/011-background-transfer/contracts/live_activity_state.md`:
`direction · title · peerLine · percent · speedLabel · bytesLabel · etaLabel · phase`.
**Không có nút** trên surface iOS (Cancel chỉ ở Android — FR-007/FR-017); chạm activity mở app về route progress.

## Nếu thêm pod/plugin sau này

CocoaPods 1.16.2 + xcodeproj 1.25.1 đã `pod install` được project này (định dạng synchronized-folder của Xcode 16) — nếu sau này `pod install` báo lỗi `PBXFileSystemSynchronizedRootGroup`, nâng gem: `sudo gem install xcodeproj` (≥1.27).
