# Contract: Localization Keys

**Feature**: 001-project-foundation · ARB (`gen-l10n`), `app_vi.arb` (primary) + `app_en.arb`. Every user-facing string keyed; VI fallback for unsupported locales (R-08). All keys need `@description`.

| Key | EN | VI |
|---|---|---|
| `navHome` | Home | Trang chủ |
| `navHistory` | History | Lịch sử |
| `navSettings` | Settings | Cài đặt |
| `homeSearchHint` | Search sent or received files… | Tìm file đã gửi hoặc nhận… |
| `homeSent` | Sent | Đã gửi |
| `homeReceived` | Received | Đã nhận |
| `homeMonthlyTransfers` | {count} transfers this month | {count} lượt truyền trong tháng này |
| `homeStatPhotos` | Photos | Ảnh |
| `homeStatVideos` | Videos | Video |
| `homeStatFiles` | Files | File |
| `homeRecentImages` | Recent photos | Ảnh gần đây |
| `homeRecentVideos` | Recent videos | Video gần đây |
| `homeRecentFiles` | Recent files | File gần đây |
| `homeRecentTransfers` | Recent transfers | Lượt truyền gần đây |
| `homeSeeAll` | See all | Xem tất cả |
| `homeQuickActions` | Quick actions | Thao tác nhanh |
| `homeActionSend` | Send files | Gửi file |
| `homeActionSendSub` | Pick & send | Chọn & gửi đi |
| `homeActionReceive` | Receive files | Nhận file |
| `homeActionReceiveSub` | Enter 6-digit code | Nhập mã 6 số |
| `homeActionScanQr` | Scan QR | Quét QR |
| `homeActionScanQrSub` | Quick connect | Kết nối nhanh |
| `homeActionNearby` | Nearby devices | Thiết bị gần |
| `homeActionNearbySub` | Instant transfer | Truyền tức thì |
| `homeTipTitle` | Tip | Mẹo nhỏ |
| `homeTipBody` | Long-press a file to send, rename, or delete it quickly. | Giữ một file để gửi, đổi tên hoặc xoá nhanh. |
| `homeTipCta` | Learn more | Tìm hiểu |
| `actionSend` | Send | Gửi |
| `actionReceive` | Receive | Nhận |
| `comingSoonTitle` | Coming soon | Sắp ra mắt |
| `sendComingSoonBody` | Sending files will be available soon. | Tính năng gửi file sẽ sớm có mặt. |
| `receiveComingSoonBody` | Receiving files will be available soon. | Tính năng nhận file sẽ sớm có mặt. |
| `historyTitle` | History | Lịch sử |
| `historyEmptyTitle` | No transfers yet | Chưa có lượt truyền nào |
| `historyEmptyBody` | Your sent and received files will appear here. | File bạn gửi và nhận sẽ hiển thị ở đây. |
| `settingsTitle` | Settings | Cài đặt |
| `settingsProfileSub` | visible to nearby devices | hiển thị với thiết bị gần đây |
| `settingsAutoReceive` | Auto-receive | Tự động nhận |
| `settingsAutoReceiveSub` | From trusted devices | Từ thiết bị đã tin tưởng |
| `settingsSaveToLibrary` | Save to library | Lưu vào Thư viện |
| `settingsSaveToLibrarySub` | Received photos & videos | Ảnh & video nhận được |
| `settingsNotifications` | Notifications | Thông báo |
| `settingsNotificationsSub` | When a file arrives | Khi có file mới |
| `settingsDarkMode` | Dark mode | Giao diện tối |
| `settingsDarkModeSub` | Follow system | Theo hệ thống |
| `settingsVersion` | Safe Send v{version} · WebRTC P2P | Safe Send v{version} · WebRTC P2P |
| `commonBack` | Back | Quay lại |

> Note: `settingsVersion` / `homeMonthlyTransfers` use `intl` placeholders. Counts/sizes shown elsewhere are formatted via locale-aware `intl` formatters (FR-025). This list is the minimum; implementation may add keys but every new string MUST be in both ARBs (SC-004).
