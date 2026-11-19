# Techy Trashker

Aplikasi pengelolaan sampah dan bank sampah — prototype Flutter berdasarkan desain
Figma **Techy Trashker (FORDIGI)**.

> Status: **MVP** — UI prototype Flutter + backend API di [`backend/`](backend/).
> Backend sudah mencakup auth, profil/poin, setoran, penjemputan, QR, reward,
> leaderboard, dan admin. Peta sudah memakai **Google Maps** (API key lewat
> `.env`). Aplikasi Flutter masih memakai data dummy; integrasi API adalah
> langkah berikutnya.

## Screenshots

| Home | Riwayat | Peta |
| --- | --- | --- |
| ![Home](docs/screenshots/home.png) | ![Riwayat](docs/screenshots/history.png) | ![Peta](docs/screenshots/map.png) |

| Onboarding | Login | Profil | QR Setor |
| --- | --- | --- | --- |
| ![Onboarding](docs/screenshots/onboarding.png) | ![Login](docs/screenshots/login.png) | ![Profil](docs/screenshots/profile.png) | ![QR](docs/screenshots/qr.png) |

> Screenshot Peta di atas memakai fallback preview (golden test). Di runtime
> dengan `GOOGLE_MAPS_API_KEY` terisi, yang tampil adalah Google Maps asli.

## Fitur prototype

- **Onboarding** 3 halaman dengan badges, dots indicator, dan skip.
- **Login / Daftar** dengan validasi form dan akun demo.
- **Home** — sapaan, poin, Hot News, aksi cepat, aktivitas terakhir, bank terdekat.
- **Riwayat** — ringkasan poin/berat, filter Setor/Jemput, sorting, detail transaksi.
- **Peta** — Google Maps asli dengan marker bank sampah, pencarian, dan info
  buka/tutup. Ada fallback preview kalau API key belum diisi.
- **Profil** — statistik, level progress, menu akun, pengaturan, bantuan, logout.
- **QR Setor** — kartu member, QR-style pattern, instruksi, simpan/bagikan.
- **Bottom sheet interaktif** untuk notifikasi, jadwal penjemputan, reward, berita,
  dan detail transaksi.

## Tech stack

- Flutter 3.44+ / Dart 3.12+
- `go_router` untuk routing dan stateful bottom navigation
- Material 3 + custom theme
- Poppins (bundled di `assets/fonts/`)
- `google_maps_flutter` untuk peta dan marker bank sampah
- Data dummy lokal di `lib/data/mock_data.dart`
- Backend: Fastify 5 + TypeScript, Supabase Auth, Supabase Postgres, Drizzle ORM

## Backend API (MVP)

Backend ada di [`backend/`](backend/) dan sudah siap dipakai sebagai API MVP:

- **Auth** — registrasi, login, refresh token, logout (Supabase Auth).
- **Profil & poin** — level, progress, total berat, ledger poin.
- **Berita & bank sampah** — list/detail, pencarian, jarak terdekat.
- **Setoran** — drop-off, jadwal penjemputan, pembatalan, penyelesaian oleh
  petugas dengan poin otomatis.
- **QR setor** — token 5 menit, sekali pakai, scan oleh petugas.
- **Reward** — katalog, penukaran poin, stok, refund saat dibatalkan admin.
- **Admin** — CRUD reward, fulfillment redemption.
- **Leaderboard** dan dokumentasi OpenAPI di `/docs`.

Quick start (detail lengkap ada di [`backend/README.md`](backend/README.md)):

```bash
cd backend
cp .env.example .env      # isi kredensial Supabase
npm install
npm run db:migrate
npm run db:seed
npm run dev               # http://localhost:3000/docs
```

Akun demo backend:

| Role | Email | Password |
| --- | --- | --- |
| Member | `andhika@techytrashker.id` | `rahasia123` |
| Petugas | `petugas@techytrashker.id` | `rahasia123` |
| Admin | `admin@techytrashker.id` | `rahasia123` |

## Menjalankan

### 1. Isi API key Google Maps

```bash
cp .env.example .env
```

Isi `GOOGLE_MAPS_API_KEY` di `.env` dengan key dari Google Cloud Console.
Aktifkan **Maps SDK for Android**, **Maps SDK for iOS**, dan/atau **Maps
JavaScript API** sesuai platform yang dipakai.

### 2. Jalankan aplikasi

```bash
flutter pub get
flutter run --dart-define-from-file=.env
```

Untuk web:

```bash
flutter run -d chrome --dart-define-from-file=.env
```

Android membaca `.env` otomatis lewat `android/app/build.gradle.kts`; flag
`--dart-define-from-file` diperlukan untuk web dan disarankan untuk semua
platform. Kalau memakai VS Code, pilih launch config **Techy Trashker (Chrome)**
atau **Techy Trashker (pilih device)**.

Detail setup Google Maps (termasuk iOS) ada di [Google Maps](#google-maps).

Build production:

```bash
flutter build web --dart-define-from-file=.env
flutter build apk --release
```

## Google Maps

Aplikasi memakai `google_maps_flutter` dengan marker custom
(`assets/images/map-pin-*.png`) dan style peta hijau yang selaras dengan brand.

- **Android**: key dibaca dari `.env` oleh Gradle, lalu dimasukkan ke
  `AndroidManifest.xml` sebagai `com.google.android.geo.API_KEY`.
- **Web**: key dibaca dari `--dart-define-from-file=.env`, lalu script Maps
  JavaScript API dimuat sebelum aplikasi berjalan. Tanpa key, halaman Peta
  menampilkan preview + petunjuk.
- **iOS**: salin `ios/Flutter/Secrets.xcconfig.example` menjadi
  `ios/Flutter/Secrets.xcconfig`, isi key, lalu build dari macOS. File tersebut
  sudah di-gitignore.

> Catatan: `.env` di root project khusus Google Maps. Konfigurasi backend
> Supabase ada di `backend/.env` (lihat [`backend/README.md`](backend/README.md)).

Batasi API key di Google Cloud:

- Android key → batasi ke package `com.techytrashker.techy_trashker` + SHA-1
  signing certificate.
- Web key → batasi ke HTTP referrer domain kamu (tambahkan juga
  `http://localhost:*/*` untuk development).
- Jangan commit `.env` atau `Secrets.xcconfig`.

Kalau Android masih memakai key lama setelah `.env` diubah, jalankan
`flutter clean` lalu build ulang. Untuk web, hentikan dan jalankan ulang
`flutter run` karena nilai `--dart-define` dibaca saat compile.

## Struktur project

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── config/           # konfigurasi Google Maps + loader web
│   ├── router.dart
│   ├── theme/            # warna, typography, theme
│   ├── utils/            # formatter, material icon mapping
│   └── widgets/          # AppCard, AppSheet, bottom nav, EcoPattern, dll
├── data/
│   ├── models/           # UserProfile, NewsItem, WasteDeposit, WasteBank
│   ├── mock_data.dart
└── features/
    ├── onboarding/
    ├── auth/
    ├── shell/
    ├── home/
    ├── history/
    ├── map/
    ├── profile/
    └── qr/

backend/
├── src/                  # Fastify routes, Supabase auth, Drizzle schema
├── drizzle/              # migration SQL
├── tests/                # integration tests (PGlite + fake auth)
└── README.md             # setup Supabase, endpoint, deploy
```

## Testing

Frontend:

```bash
flutter analyze
flutter test
```

Golden screenshots ada di `test/goldens/` dan `docs/screenshots/`. Untuk
memperbarui screenshot setelah perubahan UI:

```bash
flutter test --update-goldens test/screens_golden_test.dart
```

Backend:

```bash
cd backend
npm test        # PGlite + fake auth, tanpa kredensial Supabase
npm run typecheck
```

## Sumber desain

- Figma: [Techy Trashker (FORDIGI)](https://www.figma.com/design/vor2SRshrmWkFdKPTelwut/Techy-Trashker--FORDIGI-?node-id=0-1)
- Analisis desain lengkap: [`docs/design-analysis.md`](docs/design-analysis.md)

## Catatan

- Foto berita memakai placeholder Unsplash untuk kebutuhan prototype. Ganti dengan
  aset final dari Figma saat tersedia.
- Warna diambil dari board Figma (`#344E41` sebagai brand utama). Typography dan
  spacing adalah aproksimasi karena akses Figma saat ini view-only.
- Akun demo UI: `andhika@techytrashker.id` / `rahasia123` (UI prototype tidak
  memvalidasi ke backend). Akun demo backend sudah disiapkan di
  [`backend/README.md`](backend/README.md) dan dibuat oleh `npm run db:seed`.

## Roadmap berikutnya

- [x] Backend API MVP (Fastify + Supabase Auth/Postgres + Drizzle).
- [x] Autentikasi, profil, poin, setoran, QR, reward, leaderboard, admin.
- [x] Google Maps dengan marker bank sampah + API key lewat `.env`.
- [ ] Sambungkan aplikasi Flutter ke API (ganti `mock_data.dart`).
- [ ] Simpan token aman + auto-refresh di Flutter.
- [ ] Form penjemputan dengan tanggal, alamat, dan upload foto.
- [ ] QR asli di Flutter (render `qrPayload` + countdown token).
- [ ] Halaman reward redemption dan riwayat penukaran di Flutter.
- [ ] Notifikasi push.
- [ ] Export aset final dari Figma dan fine-tune 1:1.
