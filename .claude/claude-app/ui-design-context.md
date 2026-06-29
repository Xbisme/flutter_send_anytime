# Safe Send — UI Design Context

> **Vai trò file này**: single source of truth cho **giao diện** — screens, design tokens, components, navigation IA. Mọi spec có phần UI/UX phải bám file này. Khi implement một màn, đọc file này + pull bản design gốc từ claude_design MCP (xem "Design Source" bên dưới) để lấy chi tiết pixel.
>
> Last updated: 2026-06-27 (Imported from claude_design project "SafeSend"; +OS Surfaces — Background Transfer §Spec #011 from `Transfer Activity.dc.html`)

## Design Source

- **claude_design MCP project**: `SafeSend` — projectId `a8e27438-935f-4a14-a772-5b1ed908746c` (owner DTECH).
- **Connector**: `https://api.anthropic.com/v1/design/mcp`. Nếu chưa authorize → user chạy `/design-login` (cần scope `user:design:read/write`). Đọc bằng tool `DesignSync` (`get_project` / `list_files` / `get_file`).
- **Key files trong project**:
  - `Safe Send Screens.dc.html` — board tổng hợp 8 màn × Light/Dark (entry point để xem toàn bộ).
  - `Phone.dc.html` — component render từng màn (chứa toàn bộ markup + mock data từng screen). **Đây là spec layout chi tiết nhất.**
  - `Dialogs & Toasts.dc.html` — dialogs + toast states.
  - `Transfer Activity.dc.html` — biến thể trạng thái truyền (Android + lower states).
  - `_ds/safe-send-design-system-…/tokens/{colors,typography,spacing}.css` — design tokens (nguồn cho bảng token bên dưới).
  - `assets/logomark.svg`, `assets/logo-wordmark.svg` — brand marks (tải về `assets/brand/` khi #001 dựng project).
- **Platform khung hình**: iOS (notch, status bar 9:41), 340pt nội dung. Layout responsive cho cả Android.

> ⚠️ **Lưu ý token vs màn thực tế**: file `spacing.css` khai báo `--radius-*: 0` (ý đồ "sharp"), nhưng **các màn render thực tế dùng bo góc mềm** (card 16–22px, pill 999px, avatar tròn). **Màn render (`Phone.dc.html`) là authoritative** cho bán kính bo góc — token radius=0 là stale, bỏ qua.

---

## Navigation IA (QUAN TRỌNG — khác bản nháp roadmap đầu)

**Bottom NavigationBar = 3 tab**: **Trang chủ (Home)** · **Lịch sử (History)** · **Cài đặt (Settings)**.

- **Gửi (Send)** và **Nhận (Receive)** **KHÔNG phải tab** — chúng là **hành động chính khởi phát từ Home** (card/quick-action), mở ra flow riêng (push, không có bottom nav).
- **Settings là một tab** (không chỉ là icon trên AppBar).
- Các màn trong flow (Send → Connect → Progress → Complete; Receive → Progress → Complete) là **full-screen pushed routes, ẩn bottom nav**.

```
NavigationBar
├── Trang chủ (home)      ← entry; chứa nút Gửi + Nhận + danh sách gần đây
│     ├── push → Gửi (send) → Kết nối (connect) → Đang truyền (progress) → Hoàn tất (complete)
│     └── push → Nhận (receive) → Đang truyền (progress) → Hoàn tất (complete)
├── Lịch sử (history)
└── Cài đặt (settings)
```

`showNav = home | history | settings`. Mọi màn khác ẩn nav.

---

## Design Tokens

### Color — fixed palette, Light mặc định, Dark flip semantics

**Brand green (accent chính)**: `--green-500 #00C853` (core) · ramp 50 `#E6FBEF` → 900 `#0A4322`.
**Secondary teal/cyan** (gradient + accent phụ): `--teal-500 #00C2A8`, `--teal-400 #16D8C0`.
**Neutral** (charcoal ám xanh): `0 #FFFFFF · 50 #F4F7F5 · 100 #E8EEEA · 200 #D6E0DA · 300 #B6C4BC · 400 #8A9A92 · 500 #5B6B64 · 600 #3E4B45 · 700 #283330 · 800 #18211D · 900 #0E1512 · 950 #070B09`.
**Status**: info `#2D9CF0` · success `#00C853` · warning `#F5A623` · danger `#FF4D4D`.
**Gradients**:
- `--gradient-brand`: `linear-gradient(135deg,#00E676,#00C2A8)` — CTA chính, nút Gửi, avatar truyền.
- `--gradient-brand-vivid`: `linear-gradient(135deg,#1ED66E,#00B4D8)` — avatar/người dùng, "Nhận".
- `--gradient-radar`: `radial-gradient(circle at 50% 50%, rgba(0,200,83,.28), transparent 70%)` — nền màn Kết nối.
- phụ: `--grad-info` (xanh dương), `--grad-teal`, `--grad-amber` cho tiles/quick-actions.

**Semantic aliases** (dùng các tên này trong code, đừng hardcode hex):

| Token | Light | Dark |
|---|---|---|
| `bg-base` | neutral-0 | neutral-950 |
| `bg-subtle` (nền màn) | neutral-50 | neutral-900 |
| `surface-card` | neutral-0 | neutral-800 |
| `surface-sunken` | neutral-100 | neutral-900 |
| `border-subtle / default / strong` | n-100 / 200 / 300 | n-800 / 700 / 600 |
| `text-primary / secondary / muted` | n-900 / 500 / 400 | n-50 / 400 / 500 |
| `text-on-accent` | neutral-950 | neutral-950 |
| `accent / hover / press` | green-500 / 600 / 700 | green-400 / 300 / 500 |
| `accent-subtle` | green-50 | rgba(0,200,83,.14) |
| `accent-border` | green-200 | rgba(0,200,83,.35) |
| `overlay` | rgba(7,11,9,.45) | rgba(0,0,0,.6) |

### Typography

- **Display + Body**: **Sora** (400/500/600/700/800) — geometric, hiện đại, hơi techy.
- **Mono**: **JetBrains Mono** (400/500/700) — mã 6 số, dung lượng/tốc độ/ETA, mọi giá trị kỹ thuật, timestamp.
- Scale (16px base): xs 12 · sm 14 · base 16 · md 18 · lg 22 · xl 28 · 2xl 36 · 3xl 48 · 4xl 60.
- Weights: regular 400 · medium 500 · semibold 600 · bold 700 · extra 800.
- Tracking: tight `-0.02em` (tiêu đề lớn) · code `0.12em` · wide `0.04em`.
- Số liệu (GB, %, tốc độ, mã) **luôn dùng `font-mono` + `tabular-nums`**.

### Spacing / Radius / Shadow / Motion

- **Spacing** 4px base: 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64 · 80.
- **Radius thực tế** (theo màn render): card 16–18px · card lớn/hero 20–22px · phone frame ngoài 36–46px · ô mã/file-chip 11–14px · pill/nút 999px · avatar/icon-tròn 50%.
- **Shadow**: soft `0 6px 20px rgba(7,11,9,.07)` (card light) · accent glow `0 8px 22px rgba(0,200,83,.32–.42)` (CTA + avatar brand). Dark: soft `0 6px 20px rgba(0,0,0,.4)`.
- **Tap target** tối thiểu 44px.
- **Motion**: ease-out `cubic-bezier(.16,1,.3,1)`, dur fast 120 / base 200 / slow 360ms. Keyframes đặc thù: `ssRadar` (sóng radar phóng to mờ dần 2.4s, 2 vòng lệch 1.2s), `ssSpin` (spinner truyền 0.8s linear). **Reduce-Motion**: tắt radar + spinner, giữ trạng thái tĩnh.

---

## Shared Components (rút ra từ các màn — dựng thành design tokens app-wide ở #001)

- **AppBar màn flow**: nút tròn 40px (`surface-sunken`) chứa `arrow-left`/`x` + tiêu đề 19px bold. Màn tab dùng tiêu đề 23px extrabold (`tracking-tight`).
- **PrimaryButton (CTA)**: pill cao 52px, `gradient-brand`, chữ `text-on-accent` (#053019), bold 16px, +icon, accent glow shadow. (vd "Tiếp tục", "Gửi tiếp".)
- **SecondaryButton**: pill 52px, viền 2px `border-strong`, nền trong suốt/`surface-card`, chữ semibold. (vd "Thêm", "Xong", "Chia sẻ link mời".)
- **DangerButton**: pill viền 2px `danger`, chữ `danger` (nút "Hủy" khi đang truyền).
- **FileChip**: ô bo 11–13px, nền màu theo loại file (bảng ext→màu bên dưới), nhãn ext mono 10–11px bold.
- **FileRow**: card `surface-card`, FileChip + tên (semibold 14, ellipsis) + meta mono 11px `text-muted` + trailing (checkbox tròn / spinner / check / time).
- **SegmentedTabs**: nền `surface-sunken`, tab active = `surface-card` + chữ `accent` + soft shadow (dùng ở màn Kết nối: Mã 6 số / QR / Gần đây).
- **CodeBox**: ô 44×56px (hiện) / 48–58px (nhập), viền 2px `accent-border` (hiện) hoặc `accent` (ô đang focus, có caret), số mono 24–26px bold.
- **DeviceRow**: avatar gradient chữ-cái + tên thiết bị + trạng thái + nút "Nhận" pill `accent`.
- **StatTile / QuickActionCard**: tile bo 18–20px; quick-action có gradient riêng + icon trong ô `rgba(255,255,255,.22)`.
- **ToggleRow (Settings)**: icon ô `accent-subtle` + label/sub + switch pill 46×27 (track `accent` khi bật / `border-strong` khi tắt, knob trắng 21px).
- **ProgressBar**: rãnh `surface-sunken` cao 7–10px, fill `gradient-brand`, bo pill.
- **Icon set**: Lucide trong design (smartphone, arrow-up-right/down-left, qr-code, radar, send, download, history, settings, house, check-check, chevrons-right, gauge, clock…). Trong Flutter map sang **lucide_icons** (hoặc tabler tương đương) — chốt ở #001.

### File-type chip colors (ext → [bg, fg])

`PDF` đỏ `#E5484D` · `DOCX/DOC/JPG` xanh dương `#2D9CF0` · `XLSX/PNG` xanh lá `#00A847` · `PPTX/KEY` hổ phách `#D98E0A` · `ZIP/MP4` teal `#009E8A` · `HTML/TAR` xám `#5B6B64`. (bg = cùng màu @ ~14–16% alpha.)

---

## Screen Specs (8 màn)

> Mỗi màn có biến thể **Light + Dark**. Mã spec dưới gắn với spec roadmap sẽ build nó.

### 01 · Trang chủ (`home`) — tab Home — *Spec #001 shell, #004/#005 wires actions, #006 recent data, #012 real data + See-all*
Entry point. Cuộn dọc. Gồm: header (logomark + "Safe Send" + icon settings) · search pill "Tìm file đã gửi hoặc nhận…" · **hero card gradient-brand**: tổng Đã gửi / Đã nhận (số mono) + progress bar + "N lượt truyền tháng này" · 3 **StatTile** (Ảnh / Video / File) · lưới **Ảnh gần đây** (3 cột) · **Video gần đây** (2 cột, thumbnail + play + duration) · **File gần đây** (FileRow list) · **Lượt truyền gần đây** (card + thumbnail strip + "+N") · **Thao tác nhanh** (lưới 2×2: Quét QR / Thiết bị gần / Gửi file / Nhận file) · **card Mẹo nhỏ** (`accent-subtle`).

> **#012 (implemented)**: hero/stats/recent-media giờ là **dữ liệu thật từ lịch sử #006** (chỉ file đã gửi/nhận — không đọc thư viện máy, không quyền mới). Ảnh gần đây hiển thị **thumbnail thật** (file nhận có trên đĩa) hoặc icon theo loại; video = tile play+duration (frame thật → #013). Mỗi section có **"Xem tất cả"** mở màn full-screen riêng (`AppRoutes.homeSeeAll`, lazy grid/list, tái dùng cell + FlowAppBar) cho từng nhóm Ảnh/Video/File; tap 1 item → **trang chi tiết History (#006)**. Fresh install → hero 0 + empty state mọi section. (claude_design `SafeSend` = component/token-level, không có mockup màn riêng — màn See-all theo pattern media-grid + FileRow sẵn có.)

### 02 · Gửi file (`send`) — flow — *Spec #004*
AppBar back + "Gửi file". Banner `accent-subtle`: "N mục đã chọn" + tổng dung lượng mono + `check-check`. List **FileRow** có checkbox chọn/bỏ (tròn, tick trắng khi chọn). Footer 2 nút: **Thêm** (secondary, +icon) · **Tiếp tục** (CTA gradient, →icon).

### 03 · Kết nối (`connect`) — flow — *Spec #003 (Mã 6 số) · #007 (QR) ✅ · #009 (Gần đây)*
Nền `gradient-radar`. AppBar `x` + "Kết nối thiết bị". **SegmentedTabs: Mã 6 số / QR / Gần đây** (1 màn, 3 tab — đây là pairing hub). Tab Mã 6 số: vòng tròn smartphone với **2 sóng radar `ssRadar`**, "Chia sẻ mã này với người nhận", **4–6 CodeBox** số mono, "Hết hạn sau mm:ss" (mono + clock). Footer secondary "**Chia sẻ link mời**" (→ Spec #008).
**Tab QR (#007, implemented)**: render `QrImageView` (nền sáng cố định + module tối, scannable ở cả light/dark) encode `safesend://connect?v=1&code=NNNNNN` — **cùng một phiên hosting** với tab Mã 6 số (đổi tab KHÔNG sinh mã mới / mở socket thứ 2). Bên dưới QR hiện lại mã 6 số đọc được + countdown TTL. Trong khi hiện QR, **tăng độ sáng màn hình** (khôi phục khi rời tab). Tab này **chỉ ở vai trò người gửi** — vai trò người nhận ẩn segment QR. *(Gần đây tab = #009.)*

### 04 · Nhận file (`receive`) — flow — *Spec #005 (nhập mã) · #007 (quét QR) ✅ · #009 (thiết bị gần)*
AppBar back + "Nhận file". Tiêu đề "Nhập mã kết nối" 23px extrabold + phụ đề. **6 CodeBox nhập** (ô active có caret `accent`). Divider "hoặc". Nút "**Quét mã QR**" (secondary + qr-code icon).
**Quét QR (#007, implemented)**: nút "Quét mã QR" mở **trang scanner full-screen riêng** (`AppRoutes.qrScan`, không phải tab) — camera (mobile_scanner) + nút **đèn pin** + **chọn ảnh từ thư viện** (reuse file_picker → analyzeImage). Quét hợp lệ → tự `joinWithCode` → thẳng vào prompt accept/reject (#005). QR lạ/hết hạn → toast nhẹ, vẫn quét tiếp. **Quyền camera** (lần đầu của app): granted → camera; denied → nút xin quyền; permanently-denied/restricted → "Mở Cài đặt" + chọn-ảnh fallback (không màn hình chết). Home "Quét QR" vào thẳng scanner. **DeviceRow** thiết bị gần (→ #009).

### 05 · Đang truyền (`progress`) — flow — *Spec #004/#005 (state machine #002)*
Badge "ĐANG GỬI"/"ĐANG NHẬN" (`accent-subtle`). 2 avatar smartphone + `chevrons-right`. "tới **<tên thiết bị>**". **% lớn mono 64px**. ProgressBar gradient. Hàng mono: tốc độ (gauge icon, MB/s) · "còn m:ss · X/Y MB". Card file hiện tại (FileChip + tên + "file i / n" + spinner `ssSpin`). Footer **DangerButton "Hủy"**.

### 06 · Hoàn tất (`complete`) — flow — *Spec #004/#005*
Giữa màn: vòng tròn 100px `gradient-brand` + check 48px (glow) · "Hoàn tất!" 28px extrabold · "Đã gửi **N files · X MB** tới <thiết bị> trong m:ss" (số mono). Card tóm tắt vài file (check xanh) + "và N mục khác". Footer 2 nút: **Xong** (secondary) · **Gửi tiếp** (CTA gradient + send icon).

### 07 · Lịch sử (`history`) — tab History — *Spec #006*
Tiêu đề "Lịch sử" 23px extrabold + nút filter (`sliders-horizontal`). Section theo ngày ("HÔM NAY" / "HÔM QUA" — caption mono uppercase). **HistoryRow**: avatar tròn hướng (`arrow-up-right` gửi = `accent-subtle`/accent · `arrow-down-left` nhận = info xanh dương) + tên + meta ("gửi/nhận · người · dung lượng") + giờ mono.

### 08 · Cài đặt (`settings`) — tab Settings — *Spec #010*
Tiêu đề "Cài đặt" 23px extrabold. Card hồ sơ thiết bị (avatar gradient chữ-cái + "<tên> · hiển thị với thiết bị gần đây" + pencil edit). Nhóm **ToggleRow**: Tự động nhận (từ thiết bị tin tưởng) · Lưu vào Thư viện · Thông báo · Giao diện tối (theo hệ thống). Footer mono "Safe Send v1.0.0 · WebRTC P2P".

---

## OS Surfaces — Background Transfer (distilled từ `Transfer Activity.dc.html`, pulled 2026-06-27) — *Spec #011*

> Đây **không phải màn app thứ 9** — là các surface do OS render khi truyền nền (app ở background). Cả ba đều **chỉ phản chiếu** `Stream<TransferSnapshot>` của #002 (Constitution VIII — không có progress model song song): %, tốc độ, X/Y MB, ETA, số tệp, tên thiết bị, hướng (gửi/nhận). Light/Dark theo OS. Hướng **gửi** = `gradient-brand` + `arrow-up` + accent xanh lá (`#1ED66E`/`#00A847`); **nhận** = `gradient-brand-vivid` + `arrow-down` + accent xanh dương (`#4FE6FF`).

### iOS · Dynamic Island (3 trạng thái)
- **Thu gọn (compact)**: pill đen. Trái = chấm tròn 25px `gradient-brand` + `arrow-up` (icon `#053019`). Phải = vòng ring `conic-gradient` (green-400 phủ theo %, nền `white 18%`) + số % mono 9px trắng ở giữa.
- **Tối giản (minimal)**: chỉ ring % (khi có activity khác chiếm chỗ) — vòng conic + `arrow-up` green-400 + "%" mono.
- **Mở rộng (expanded, chạm-giữ)**: thẻ đen radius 30px. Icon badge 38px `gradient-brand` radius 11px · tiêu đề "Đang gửi · 18 tệp" 14/700 + phụ "tới Minh's iPhone" 12px `white 60%` · **% lớn mono 22px** green-400 (phải). Bar 7px `gradient-brand`. Hàng mono 11px `white 60%`: "2.4 MB/s" ↔ "153 / 240 MB · còn 0:48".

### iOS · Lock Screen Live Activity (2 biến thể: gửi / nhận)
Thẻ `rgba(0,0,0,0.55)` + blur, radius 28px, padding 14/16, đặt dưới đỉnh màn khoá. Icon badge 34px radius 10px · tiêu đề 13/700 + tên thiết bị 11px `white 65%` · % mono 19px (gửi green-400 / nhận `#4FE6FF`). Bar 6px (gradient theo hướng). Hàng mono 10px `white 60%`: tốc độ ↔ "X / Y MB · còn m:ss".
- **Gửi**: "Đang gửi · 18 tệp" · "tới Minh's iPhone" · 64% · 2.4 MB/s · 153/240 MB · còn 0:48.
- **Nhận**: "Đang nhận · 8 tệp" · "từ MacBook của Linh" · 38% · 3.1 MB/s · 59/156 MB · còn 0:31.

### Android · Foreground Service notification (Light + Dark)
Card radius 24px. Header: badge logomark 18px `gradient-brand` + "Safe Send · bây giờ" + `chevron-down`. Thân: icon badge tròn 44px (hướng) · tiêu đề 15/700 "Đang gửi 18 tệp" · meta mono 12px "153 / 240 MB · 2.4 MB/s · còn 0:48" · % mono 16px phải (Light `#00A847` / Dark green-400). Bar 6px `gradient-brand`. **1 nút pill duy nhất: "Huỷ"** (`#E5484D` danger, chiếm cả hàng) — wired vào cancel của state machine #002.

> ℹ️ **Android render thực tế (plan #011)**: thông báo foreground-service dùng **template chuẩn của Android** (small icon + accent tint + title + text + progress bar 0–100 + action "Huỷ") — **không** vẽ được card bo góc gradient như mock (OS tự style ongoing notification). Khớp **nội dung + icon + accent + nút Huỷ**, không khớp pixel card. iOS Live Activity là SwiftUI tự vẽ nên bám mock sát.

> ✅ **Quyết định #011 (2026-06-27)**: **bỏ nút "Tạm dừng" của mock** — engine #002 (+ Send/Receive #004/#005) chỉ hỗ trợ **Huỷ**, không pause/resume ("pause-not-required" từ #004). #011 render **chỉ "Huỷ"** để khớp engine và đúng scope v1.0; pause/resume để v1.1. Notification tap (thân thông báo) → mở lại màn Đang truyền (Screen 05) trong app. iOS Live Activity không có nút điều khiển (chỉ chạm-giữ để mở rộng) → không vướng.
> **Khi OS suspend/hết-giờ-background giữa transfer**: fail **sạch** với copy rõ ràng khi quay lại foreground, **giữ các tệp đã nhận xong** (partial như #005), cho **retry**. Resume lượt dở dang = v1.1 (post-v1.0 roadmap).

## Dialogs & Toasts (distilled từ `Dialogs & Toasts.dc.html`, pulled 2026-06-25)

> Nguồn: claude_design `SafeSend` → `Dialogs & Toasts.dc.html`. Light + Dark. Overlay `var(--overlay)`; card `surface-card`, radius 24px, `soft-shadow`, padding 24/22; icon-badge tròn 58px trên đầu; nút pill cao 48px xếp dọc (primary trên, secondary `surface-sunken` dưới). Mỗi dialog ≤ 1 primary + tối đa 1 secondary.

### Dialog patterns (6 dạng)

| Dạng | Icon badge | Title · Body | Primary | Secondary | Dùng ở |
|---|---|---|---|---|---|
| **Incoming transfer** (accept/reject) | avatar chữ-cái trên `gradient-brand-vivid` (generic tới #010) | "‹Peer› muốn gửi cho bạn" · "N tệp · TỔNG · loại file" | **Nhận** (gradient, `#053019`) | **Từ chối** | **#005** prompt |
| **Cancel transfer** (xác nhận huỷ) | `alert-triangle` trên `danger` 14% | "Huỷ lượt truyền?" · "Đang gửi/nhận N tệp… Tiến độ sẽ mất." | **Huỷ truyền** (`danger`, trắng) | **Tiếp tục** | #004/#005 progress |
| **Success** (hoàn tất) | `check` trên `gradient-brand`, trắng | "Đã gửi/nhận xong" · "N tệp … an toàn, không qua máy chủ." | **Xong** (gradient) | — | #004/#005 (có thể dùng Complete screen thay) |
| **Connecting** (loading) | spinner 48px (`accent` top, `ssSpin` 0.8s) | "Đang kết nối…" · phụ đề | — | **Huỷ** | #004/#005 connect |
| **Text input** (đổi tên / tên thiết bị) | — | title + ô input viền 2px (`accent` khi focus) | **Lưu** (gradient) | **Huỷ** (cùng hàng, 2 nút ngang) | #010 (đổi tên tệp / device name) |
| **Permission** (mạng cục bộ) | `shield-check` trên `accent-subtle` | "Cho phép tìm thiết bị gần" · lý do | **Cho phép** (gradient) | **Để sau** | #009 |

- **Bottom sheet** (file actions): handle 38×5px, header FileRow (chip type + tên + "KB · EXT"), list action-row (icon 20px + label 15/600); destructive = `#E5484D`. Actions mẫu: Gửi tệp này / Chia sẻ link / Đổi tên / Xoá. Dùng ở #006/#010.

### Toast / Snackbar (tuân thủ `AppToast`, token chung #001)
Card `surface-card` radius 15px + `soft-shadow`, icon tròn 34px màu theo loại, text 13.5/600, **tuỳ chọn** action (chữ `accent` in hoa) **hoặc** nút close `x`. 5 biến thể:

| Loại | Icon · màu | Ví dụ | Action/Close |
|---|---|---|---|
| success | `check` · green | "Đã gửi N tệp thành công" | — |
| error | `x` · `danger` | "Kết nối thất bại — thử lại" | action **Thử lại** |
| info | `link` · `info` | "Đã sao chép link mời" | close |
| warning | `clock` · `warning` | "Mã kết nối sắp hết hạn" | close |
| neutral/undo | `trash-2` · `text-secondary` | "Đã xoá ‹tệp›" | action **Hoàn tác** |

> #005 dùng: **Incoming-transfer dialog** (accept/reject) + **Cancel-transfer dialog** + toast **error "thử lại"** (lỗi nhận) + có thể **Success**. Avatar/tên peer = generic label tới #010.

---

## Implementation Rules (UI)

- **Fixed palette** — chỉ Light/Dark + mode follow-system (Spec #010). **Không** có scheme picker.
- Dùng **semantic token names** (`accent`, `surface-card`, `text-secondary`…) — không hardcode hex trong widget.
- Mọi **số/giá trị kỹ thuật** dùng `font-mono` + tabular-nums.
- **CTA = pill gradient-brand**; **secondary = pill viền 2px**; nhất quán cao 52px.
- Bottom nav chỉ hiện ở 3 tab (home/history/settings); flow screens ẩn nav.
- Reduce-Motion: tắt radar + spinner animation.
- Tái dựng component dùng lại (FileRow, CodeBox, SegmentedTabs, ToggleRow, PrimaryButton…) thành shared widgets ở **#001**, không lặp markup mỗi feature.
- UI/UX gốc của Safe Send — pull từ claude_design, **không** sao chép app khác.
