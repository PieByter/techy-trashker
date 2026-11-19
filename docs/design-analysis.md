# Techy Trashker — Design Analysis

## Source

- Figma file: [Techy Trashker (FORDIGI)](https://www.figma.com/design/vor2SRshrmWkFdKPTelwut/Techy-Trashker--FORDIGI-?node-id=0-1)
- File key: `vor2SRshrmWkFdKPTelwut`
- Access at time of analysis: **view-only**, `viewer_export_restricted: false`
- Board size: approximately **13.621 × 6.300 px**, roughly 20 mobile frames.

> This analysis is based on the public Figma embed and the board thumbnail. It is
> enough to reproduce the visual direction and flows, but it is not a layer-level
> handoff (auto-layout, exact constraints, and exported assets still need Figma
> export or a Figma API token).

## Product concept

Techy Trashker is an Indonesian waste-management app. Users can:

- setor sampah ke bank sampah,
- request penjemputan sampah,
- mengumpulkan poin dari setiap setoran,
- menukar poin dengan reward,
- membaca berita/edukasi lingkungan,
- menemukan bank sampah terdekat.

The visual language is a deep forest green with warm off-white surfaces, rounded
cards, soft mint highlights, and amber accents for points/rewards.

## Screen inventory (from the Figma board)

| Flow | Screens observed |
| --- | --- |
| Onboarding | 3–4 intro/splash frames with a large search/leaf motif |
| Auth | Login, register, and account recovery states |
| Home | Greeting "Hello! Andhika", Hot News card, points summary, bottom navigation |
| Setor | QR code screen for petugas bank sampah |
| Riwayat | Deposit history with photos, weights, points, and a large points summary |
| Profil | Avatar, level/points statistics, account menu |
| Berita | News list and news detail |
| Peta | Radar-style map / nearest waste-bank recommendation with avatars |
| Gamifikasi | Point total, leaderboard/reach visualization, reward states |

## Design tokens used in this Flutter prototype

| Token | Value | Usage |
| --- | --- | --- |
| Forest | `#344E41` | Primary brand, hero surfaces |
| Forest dark | `#24382F` | Bottom nav, gradients |
| Sage | `#A3B18A` | Muted accent icons |
| Mint | `#E4EFE6` | Soft success/background chips |
| Cream | `#F7F6F1` | App background |
| Surface | `#FFFFFF` | Cards and sheets |
| Ink | `#1C2620` | Primary text |
| Muted | `#6D7973` | Secondary text |
| Amber | `#E7A544` | Points/reward accent |
| Line | `#E3E9E2` | Borders and dividers |

- **Typography:** Poppins (Regular 400 → ExtraBold 800), bundled locally
  in `assets/fonts/`. The Figma file's exact text styles were not readable from
  the view-only embed, so weights/sizes are an approximation.
- **Shape:** 18–30 px rounded corners, pill-shaped chips and buttons.
- **Spacing:** 20 px page gutter, 12/16/24 px internal rhythm.
- **Motif:** concentric circles + magnifying glass + leaf/recycle icon. Implemented
  as `EcoPattern` in `lib/core/widgets/eco_pattern.dart`.

## Implemented in the Flutter app

1. **Onboarding** — three pages with animated dots, badges, and a skip action.
2. **Login / Register** — tabbed auth card, validation, Supabase Auth, and
   session token refresh.
3. **Home** — live profile/points, Hot News carousel, recent deposits, nearest
   bank card, pickup request, and reward redemption.
4. **Riwayat** — summary stats, filter by Setor/Jemput, newest/oldest sorting,
   deposit detail sheet.
5. **Peta** — Google Maps dengan marker dari API, pencarian, filter rating/jarak,
   GPS, dan fallback preview jika API key belum tersedia.
6. **Profil** — profil/statistik dari API, edit nama, pengaturan, bantuan, logout.
7. **QR Setor** — token singkat dari backend, QR asli, dan countdown.
8. **Panel petugas** — scan QR/kode member, catat berat, selesaikan penjemputan.

Backend MVP di `backend/` menggunakan Supabase Auth, Postgres, Drizzle, dan
Fastify. Data demo lokal hanya digunakan oleh widget/golden test tanpa session.

## Suggested next step: backend contract

Kontrak endpoint di bawah sudah diimplementasikan di [`backend/`](../backend/)
dan digunakan oleh aplikasi Flutter.

| Endpoint | Purpose |
| --- | --- |
| `POST /auth/login` | Login and token issuance |
| `GET /me` | Profile, points, level, total weight |
| `GET /news` | News list |
| `GET /news/:id` | News detail |
| `GET /deposits` | Deposit history (filter + pagination) |
| `POST /deposits` | Create a deposit / pickup request |
| `GET /waste-banks` | Nearest waste banks (lat/lng, open status) |
| `POST /rewards/:id/redeem` | Redeem a reward |
| `POST /qr/session` | Short-lived QR token for setor |

## Fidelity notes

- The design's photos are represented by local Unsplash placeholders
  (`assets/images/news-*.jpg`) for the prototype. Replace them with the final
  exported Figma assets when available.
- Icons use Material Rounded. If the Figma file uses a custom icon set, export
  those icons as SVG and swap them in.
- Exact font sizes, spacing, and illustrations should be verified against
  exported frames at 2x once Figma export or API access is available.
