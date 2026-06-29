# Store Listing Package (US6 — staged, NOT submitted)

Everything needed to submit. The maintainer uploads/submits with their own
Apple Developer + Google Play accounts (FR-029). Keep all answers accurate
against the US2-verified behavior.

## Metadata (VI primary + EN)

| Field | VI | EN |
|---|---|---|
| Name | Safe Send | Safe Send |
| Subtitle | Gửi file trực tiếp, riêng tư | Direct, private file sending |
| Description | _(draft)_ Gửi file mọi loại, mọi kích thước trực tiếp giữa hai thiết bị qua WebRTC mã hoá đầu-cuối. Không máy chủ nào giữ dữ liệu của bạn. | _(draft)_ Send files of any type and size directly between two devices over end-to-end encrypted WebRTC. No server ever holds your data. |
| Keywords | gửi file, chia sẻ, p2p, wifi, qr | file transfer, share, p2p, wifi, qr |
| Support URL | _(TODO)_ | _(TODO)_ |

## Screenshots (TODO — capture on device)

Required sizes: iPhone 6.7"/6.5"/5.5"; Android phone. Screens: Home, Connect
(6-digit + QR), Progress, Complete, History, Settings.

## Privacy policy

_(TODO: host the policy; draft below.)_ Safe Send transfers files directly
between devices over end-to-end encrypted WebRTC. The signaling server only
helps two devices find each other and never receives or stores file contents.
When a direct connection isn't possible, an encrypted TURN relay may forward the
(still-encrypted) bytes; it stores nothing. The app collects no personal data
and uses no analytics.

## Apple privacy nutrition

- **Data collected**: None.
- **Tracking**: None.

## Google Play data safety

- **Data collected/shared**: None.
- **Encryption in transit**: Yes (DTLS end-to-end; TURN relay encrypted-only).
- **Data deletion**: N/A (no account, no server-side data).

> Consistency note: these "no data collected" answers match the US2 security
> verification, including the encrypted-non-persisted TURN relay added in #014.
