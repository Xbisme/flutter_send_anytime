# Safe Send — UI Design Context

> **Vai trò file này**: single source of truth cho **giao diện** — screens, design tokens, components, navigation IA. Mọi spec có phần UI/UX phải bám file này. Khi implement một màn, đọc file này + pull bản design gốc từ claude_design MCP (xem "Design Source" bên dưới) để lấy chi tiết pixel.
>
> Last updated: 2026-06-24 (Imported from claude_design project "SafeSend")

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

### 01 · Trang chủ (`home`) — tab Home — *Spec #001 shell, #004/#005 wires actions, #006 recent data*
Entry point. Cuộn dọc. Gồm: header (logomark + "Safe Send" + icon settings) · search pill "Tìm file đã gửi hoặc nhận…" · **hero card gradient-brand**: tổng Đã gửi / Đã nhận (số mono) + progress bar + "N lượt truyền tháng này" · 3 **StatTile** (Ảnh / Video / File) · lưới **Ảnh gần đây** (3 cột) · **Video gần đây** (2 cột, thumbnail + play + duration) · **File gần đây** (FileRow list) · **Lượt truyền gần đây** (card + thumbnail strip + "+N") · **Thao tác nhanh** (lưới 2×2: Quét QR / Thiết bị gần / Gửi file / Nhận file) · **card Mẹo nhỏ** (`accent-subtle`).

### 02 · Gửi file (`send`) — flow — *Spec #004*
AppBar back + "Gửi file". Banner `accent-subtle`: "N mục đã chọn" + tổng dung lượng mono + `check-check`. List **FileRow** có checkbox chọn/bỏ (tròn, tick trắng khi chọn). Footer 2 nút: **Thêm** (secondary, +icon) · **Tiếp tục** (CTA gradient, →icon).

### 03 · Kết nối (`connect`) — flow — *Spec #003 (Mã 6 số) · #007 (QR) · #009 (Gần đây)*
Nền `gradient-radar`. AppBar `x` + "Kết nối thiết bị". **SegmentedTabs: Mã 6 số / QR / Gần đây** (1 màn, 3 tab — đây là pairing hub). Tab Mã 6 số: vòng tròn smartphone với **2 sóng radar `ssRadar`**, "Chia sẻ mã này với người nhận", **4–6 CodeBox** số mono, "Hết hạn sau mm:ss" (mono + clock). Footer secondary "**Chia sẻ link mời**" (→ Spec #008). *(QR tab = #007, Gần đây tab = #009.)*

### 04 · Nhận file (`receive`) — flow — *Spec #005 (nhập mã) · #007 (quét QR) · #009 (thiết bị gần)*
AppBar back + "Nhận file". Tiêu đề "Nhập mã kết nối" 23px extrabold + phụ đề. **6 CodeBox nhập** (ô active có caret `accent`). Divider "hoặc". Nút "**Quét mã QR**" (secondary + qr-code icon, → #007). **DeviceRow** thiết bị gần đang chờ ("Minh's iPhone · đang chờ ở gần bạn" + nút "Nhận", → #009).

### 05 · Đang truyền (`progress`) — flow — *Spec #004/#005 (state machine #002)*
Badge "ĐANG GỬI"/"ĐANG NHẬN" (`accent-subtle`). 2 avatar smartphone + `chevrons-right`. "tới **<tên thiết bị>**". **% lớn mono 64px**. ProgressBar gradient. Hàng mono: tốc độ (gauge icon, MB/s) · "còn m:ss · X/Y MB". Card file hiện tại (FileChip + tên + "file i / n" + spinner `ssSpin`). Footer **DangerButton "Hủy"**.

### 06 · Hoàn tất (`complete`) — flow — *Spec #004/#005*
Giữa màn: vòng tròn 100px `gradient-brand` + check 48px (glow) · "Hoàn tất!" 28px extrabold · "Đã gửi **N files · X MB** tới <thiết bị> trong m:ss" (số mono). Card tóm tắt vài file (check xanh) + "và N mục khác". Footer 2 nút: **Xong** (secondary) · **Gửi tiếp** (CTA gradient + send icon).

### 07 · Lịch sử (`history`) — tab History — *Spec #006*
Tiêu đề "Lịch sử" 23px extrabold + nút filter (`sliders-horizontal`). Section theo ngày ("HÔM NAY" / "HÔM QUA" — caption mono uppercase). **HistoryRow**: avatar tròn hướng (`arrow-up-right` gửi = `accent-subtle`/accent · `arrow-down-left` nhận = info xanh dương) + tên + meta ("gửi/nhận · người · dung lượng") + giờ mono.

### 08 · Cài đặt (`settings`) — tab Settings — *Spec #010*
Tiêu đề "Cài đặt" 23px extrabold. Card hồ sơ thiết bị (avatar gradient chữ-cái + "<tên> · hiển thị với thiết bị gần đây" + pencil edit). Nhóm **ToggleRow**: Tự động nhận (từ thiết bị tin tưởng) · Lưu vào Thư viện · Thông báo · Giao diện tối (theo hệ thống). Footer mono "Safe Send v1.0.0 · WebRTC P2P".

---

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
