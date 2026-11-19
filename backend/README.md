# Techy Trashker API

Backend MVP untuk aplikasi bank sampah **Techy Trashker**. API ini melayani
aplikasi Flutter (dan client lain) dengan autentikasi **Supabase Auth**, data
**Supabase Postgres**, dan query type-safe lewat **Drizzle ORM**.

> Status: **MVP selesai** — auth, profil/poin, berita, bank sampah, setoran,
> penjemputan, QR setor, reward, leaderboard, dan panel admin sudah tersedia.
> Aplikasi Flutter belum di-wire ke API ini; langkah berikutnya ada di
> [Integrasi Flutter](#integrasi-flutter).

## Stack

| Layer | Teknologi |
| --- | --- |
| Runtime | Node.js 24 + TypeScript |
| HTTP | Fastify 5 |
| Auth | Supabase Auth (access token Bearer) |
| Database | Supabase Postgres |
| ORM / migrasi | Drizzle ORM + drizzle-kit |
| Validasi / docs | Zod + OpenAPI (`/docs`) |
| Test | Vitest + PGlite (Postgres in-memory) + fake auth |
| Deploy | Docker / Node host mana pun |

```text
Flutter / Web
      │  HTTPS + Bearer access token
      ▼
Fastify API  ──────────────►  Supabase Auth
      │                         (register/login/refresh/logout)
      │  postgres (pooler)
      ▼
Supabase Postgres (Drizzle, RLS deny-all)
```

## Fitur MVP

- Registrasi, login, refresh, logout memakai Supabase Auth.
- Profil member: poin, total berat, level, progress, statistik.
- Riwayat poin (ledger) dengan ringkasan earned/spent/balance.
- Berita + detail berita.
- Bank sampah terdekat (haversine), filter buka/tutup, pencarian.
- Setoran:
  - drop-off (status `processing`, menunggu ditimbang petugas),
  - penjemputan (status `scheduled`, alamat + jadwal),
  - pembatalan oleh member,
  - penyelesaian oleh petugas dengan item aktual + poin otomatis.
- Antrean petugas untuk melihat penjemputan/setoran aktif.
- QR setor berumur 5 menit, disimpan sebagai hash, sekali pakai.
- Scan QR oleh petugas (atau fallback `memberCode`) yang langsung membuat
  setoran selesai dan memberi poin.
- Reward: katalog, penukaran poin, stok, riwayat redemption.
- Admin: CRUD reward, daftar redemption, fulfill/cancel + refund.
- Leaderboard all-time.
- Dokumentasi OpenAPI interaktif di `/docs`.
- Rate limit, Helmet, CORS, error envelope konsisten, validasi Zod.
- RLS deny-all untuk semua tabel domain (akses hanya lewat backend).

## Quick start

### 1. Siapkan Supabase

1. Buat project di [supabase.com](https://supabase.com) (atau pakai project
   yang sudah ada).
2. Ambil kredensial dari **Project Settings → API**:
   - Project URL
   - anon/publishable key
   - service role/secret key (**jangan pernah** dipakai di client)
3. Ambil connection string dari **Database → Connect**:
   - `DATABASE_URL` → **Transaction pooler**, port `6543`
   - `DIRECT_URL` → **Direct connection**, port `5432` (khusus migrasi/seed)

### 2. Konfigurasi

```bash
cd backend
cp .env.example .env
```

Isi `.env`. Nama env baru Supabase (`SUPABASE_PUBLISHABLE_KEY`,
`SUPABASE_SECRET_KEY`) juga didukung; backend menerima keduanya.

### 3. Install, migrasi, seed

```bash
npm install
npm run db:migrate   # schema + index + RLS
npm run db:seed      # akun demo + berita + bank sampah + reward + riwayat
npm run dev
```

Buka:

- Swagger UI: <http://localhost:3000/docs>
- OpenAPI JSON: <http://localhost:3000/docs/json>
- Health: <http://localhost:3000/health>

### Akun demo

| Role | Email | Password |
| --- | --- | --- |
| Member | `andhika@techytrashker.id` | `rahasia123` |
| Petugas | `petugas@techytrashker.id` | `rahasia123` |
| Admin | `admin@techytrashker.id` | `rahasia123` |

Seed membuat user Supabase Auth sekaligus profil, 6 setoran demo (5 selesai +
1 penjemputan terjadwal), 147 poin / 12,4 kg, 3 berita, 4 bank sampah, dan 5
reward. Kalau auth user dengan email tersebut sudah ada, seed memakai user itu.

## Endpoint

Base path: `/api/v1`. Endpoint dengan 🔒 butuh
`Authorization: Bearer <access_token>`.

### Auth

| Method | Path | Akses | Keterangan |
| --- | --- | --- | --- |
| POST | `/auth/register` | publik | Daftar akun + profil |
| POST | `/auth/login` | publik | Login |
| POST | `/auth/refresh` | publik | Rotasi access/refresh token |
| POST | `/auth/logout` | 🔒 | Cabut sesi Supabase |

### Profil & poin

| Method | Path | Akses | Keterangan |
| --- | --- | --- | --- |
| GET | `/me` | 🔒 | Profil + statistik |
| PATCH | `/me` | 🔒 | Ubah nama/avatar |
| GET | `/me/stats` | 🔒 | Ringkasan poin/berat/setoran |
| GET | `/points/history` | 🔒 | Ledger poin + summary |

### Konten & bank sampah

| Method | Path | Akses | Keterangan |
| --- | --- | --- | --- |
| GET | `/news` | publik | List + pagination + filter |
| GET | `/news/:id` | publik | Detail + konten |
| GET | `/waste-banks` | publik | Terdekat + filter buka |
| GET | `/waste-banks/:id` | publik | Detail |

### Setoran & QR

| Method | Path | Akses | Keterangan |
| --- | --- | --- | --- |
| GET | `/deposits` | 🔒 | Riwayat + filter + sorting |
| GET | `/deposits/summary` | 🔒 | Ringkasan header riwayat |
| GET | `/deposits/:id` | 🔒 | Detail + item |
| POST | `/deposits` | 🔒 | Drop-off atau jadwal penjemputan |
| POST | `/deposits/:id/cancel` | 🔒 | Batalkan yang belum selesai |
| POST | `/deposits/:id/complete` | petugas/admin | Timbang + beri poin |
| GET | `/officer/deposits` | petugas/admin | Antrean setoran aktif |
| POST | `/qr/session` | 🔒 | QR setor 5 menit |
| POST | `/qr/scan` | petugas/admin | Scan QR / `memberCode` |

### Reward, leaderboard, admin

| Method | Path | Akses | Keterangan |
| --- | --- | --- | --- |
| GET | `/rewards` | publik | Katalog aktif |
| GET | `/rewards/:id` | publik | Detail |
| POST | `/rewards/:id/redeem` | 🔒 | Tukar poin |
| GET | `/redemptions` | 🔒 | Riwayat penukaran |
| GET | `/redemptions/:id` | 🔒 | Detail penukaran |
| GET | `/leaderboard` | publik | Peringkat all-time |
| POST | `/admin/rewards` | admin | Tambah reward |
| PATCH | `/admin/rewards/:id` | admin | Ubah reward |
| DELETE | `/admin/rewards/:id` | admin | Nonaktifkan reward |
| GET | `/admin/redemptions` | admin | Semua redemption |
| PATCH | `/admin/redemptions/:id` | admin | Fulfill / cancel + refund |

## Alur utama

### Setor via QR

```text
Member                         Petugas                      Backend
  │ POST /qr/session              │                            │
  │───────────────────────────────────────────────────────────►│ simpan SHA-256 token, 5 menit
  │◄───────────────────────────────────────────────────────────│ token + qrPayload
  │ tunjukkan QR                 │                            │
  │                              │ POST /qr/scan {token,items}│
  │                              │───────────────────────────►│ validasi token
  │                              │                            │ hitung poin per item
  │                              │                            │ buat deposit completed
  │                              │                            │ update poin + berat
  │                              │                            │ tandai QR used
  │                              │◄───────────────────────────│ deposit + poin
```

- Token hanya disimpan sebagai hash, berlaku 5 menit, dan sekali pakai.
- `memberCode` bisa dipakai petugas sebagai fallback kalau QR tidak terbaca.
- Poin dihitung di server; client tidak boleh mengirim poin.

### Penjemputan

1. Member `POST /deposits` dengan `method: "pickup"`, `address`, dan
   `scheduledAt` (minimal 15 menit, maksimal 30 hari dari sekarang).
2. Status menjadi `scheduled`.
3. Petugas melihat antrean lewat `GET /officer/deposits`.
4. Petugas menimbang lalu `POST /deposits/:id/complete` dengan item aktual.
5. Status menjadi `completed`, poin + berat masuk ke profil member.

### Reward

1. Member `POST /rewards/:id/redeem`.
2. Poin langsung dipotong, stok berkurang, redemption berstatus `pending`.
3. Admin `PATCH /admin/redemptions/:id`:
   - `fulfilled` → selesai, poin tidak kembali.
   - `cancelled` → poin kembali + stok kembali.

## Aturan domain

### Status setoran

| Status | Arti |
| --- | --- |
| `scheduled` | Penjemputan terjadwal |
| `processing` | Drop-off menunggu ditimbang |
| `completed` | Sudah ditimbang, poin diberikan |
| `cancelled` | Dibatalkan sebelum selesai |

Poin hanya diberikan saat status menjadi `completed`. Poin dan total berat
di-update dalam transaksi yang sama dengan pembuatan item setoran.

### Poin per kg

| Kategori | Poin/kg |
| --- | ---: |
| Plastik | 20 |
| Kertas | 10 |
| Logam | 20 |
| Organik | 3,75 |
| E-Waste | 29 |
| Kaca | 5 |
| Lainnya | 5 |

`poin = round(berat_kg × tarif)`, dihitung per item lalu dijumlahkan.
Tarif ada di `src/lib/points.ts`.

### Level

| Level | Minimal poin |
| --- | ---: |
| Pemula | 0 |
| Eco Warrior | 100 |
| Green Hero | 200 |
| Earth Champion | 500 |
| Eco Legend | 1000 |

`levelProgress` mengikuti UI: `points / nextLevelPoints` (clamp 0..1).
Untuk level tertinggi, progress = 1.

## Contoh request

Login:

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"andhika@techytrashker.id","password":"rahasia123"}'
```

Buat penjemputan:

```bash
curl -X POST http://localhost:3000/api/v1/deposits \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "method": "pickup",
    "material": "Botol Plastik",
    "category": "Plastik",
    "weightKg": 1.5,
    "address": "Jl. Gatot Subroto No. 12, Medan",
    "scheduledAt": "2026-11-22T09:00:00+07:00"
  }'
```

Petugas menyelesaikan setoran:

```bash
curl -X POST http://localhost:3000/api/v1/deposits/$DEPOSIT_ID/complete \
  -H "Authorization: Bearer $OFFICER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "items": [
      { "material": "Botol Plastik", "category": "Plastik", "weightKg": 2 },
      { "material": "Kardus", "category": "Kertas", "weightKg": 1 }
    ]
  }'
```

QR setor + scan:

```bash
# member
curl -X POST http://localhost:3000/api/v1/qr/session \
  -H "Authorization: Bearer $TOKEN"

# petugas
curl -X POST http://localhost:3000/api/v1/qr/scan \
  -H "Authorization: Bearer $OFFICER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "token": "ttqr_...",
    "items": [
      { "material": "Kaleng", "category": "Logam", "weightKg": 1.2 }
    ]
  }'
```

## Format response

Sukses dengan list:

```json
{
  "data": [],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 0,
    "totalPages": 0,
    "hasNext": false,
    "hasPrev": false
  }
}
```

Error:

```json
{
  "error": {
    "code": "INSUFFICIENT_POINTS",
    "message": "Poin belum cukup. Butuh 150 poin, kamu punya 20.",
    "details": null
  }
}
```

`details` hanya muncul untuk error validasi (array issue Zod).

## Setup Supabase & keamanan

- **Auth**: password hashing, sesi, refresh, dan revoke ditangani Supabase.
  Backend memverifikasi Bearer token dengan `supabase.auth.getUser`.
- **Service role key** hanya dipakai di server untuk register/logout/seed.
  Jangan pernah mengirimkannya ke Flutter atau web.
- **RLS**: migration `0001_enable_rls.sql` mengaktifkan RLS tanpa policy pada
  semua tabel domain. Artinya anon/authenticated key tidak bisa membaca atau
  menulis tabel langsung lewat PostgREST. Backend memakai koneksi Postgres
  sebagai role `postgres` yang bypass RLS. Jangan menambahkan policy longgar
  tanpa memahami konsekuensinya.
- **Email confirmation**: untuk MVP, register dan seed memakai
  `email_confirm: true` agar onboarding demo mulus. Untuk produksi, pertimbangkan
  verifikasi email dan flow reset password.
- **Rate limit**: default 300 request/menit per IP; login 20/menit; register
  10/menit. Ubah `RATE_LIMIT_MAX` bila perlu.
- **Verifikasi token**: setiap request memanggil Supabase `auth.getUser` untuk
  memastikan token masih valid. Untuk trafik tinggi, langkah optimasi berikutnya
  adalah verifikasi JWT lewat JWKS + cache.
- **QR**: token acak 32 byte, disimpan sebagai SHA-256, TTL 300 detik, sekali
  pakai, dan hanya bisa dipakai role petugas/admin.
- **CORS**: default `*` untuk development. Set `CORS_ORIGIN` ke origin web
  produksi (dipisah koma) saat deploy.
- **Helmet** aktif; CSP dimatikan agar Swagger UI bisa memuat asetnya.

## Testing

```bash
npm test
```

Test berjalan tanpa Supabase:

- **PGlite** sebagai Postgres in-memory, memakai migration Drizzle yang sama
  dengan produksi.
- **FakeAuthProvider** in-memory untuk register/login/refresh/logout/verify.
- **51 integration test** mencakup auth, profil, berita, bank sampah, setoran,
  antrean petugas, QR (termasuk expired/reuse), reward/refund, leaderboard,
  poin, validasi, RLS-compatible schema, idempotensi seed, dan OpenAPI.

Perintah lain:

```bash
npm run typecheck
npm run build
npm run start
```

## Scripts

| Script | Fungsi |
| --- | --- |
| `npm run dev` | Hot reload (`tsx watch`) |
| `npm run build` | Bundle ke `dist/` |
| `npm run start` | Jalankan hasil build |
| `npm run typecheck` | Cek TypeScript |
| `npm test` | Integration test |
| `npm run db:generate` | Generate migration dari schema |
| `npm run db:migrate` | Jalankan migration (direct connection) |
| `npm run db:seed` | Seed akun + data demo |
| `npm run db:setup` | Migrate + seed |
| `npm run db:studio` | Drizzle Studio |
| `npm run db:migrate:prod` | Migration dari bundle (`dist/`) |
| `npm run db:seed:prod` | Seed dari bundle (`dist/`) |

## Deploy

### Docker

```bash
docker build -t techy-trashker-api ./backend

docker run --rm --env-file backend/.env techy-trashker-api \
  node dist/db/migrate-cli.js

docker run --rm -p 3000:3000 --env-file backend/.env techy-trashker-api
```

`NODE_ENV=production` menonaktifkan `pino-pretty` (dev dependency).

### Platform

Backend ini long-running process, jadi cocok di Railway, Render, Fly.io, VPS,
atau container platform lain. Vercel serverless bisa dipakai dengan adaptor,
tetapi bukan target utama.

Checklist deploy:

1. Set semua env produksi (`SUPABASE_*`, `DATABASE_URL`, `DIRECT_URL`,
   `PUBLIC_BASE_URL`, `CORS_ORIGIN`, `TRUST_PROXY`, `NODE_ENV=production`).
   Set `TRUST_PROXY=true` kalau berjalan di belakang reverse proxy.
2. Jalankan migrasi dengan **direct connection** sebelum start.
3. Jangan jalankan `db:seed` di produksi (data demo).
4. `PUBLIC_BASE_URL` harus URL publik agar `imageUrl`/`avatarUrl` valid.
5. Pastikan service role key hanya tersedia di secret manager.

## Integrasi Flutter

Langkah berikutnya di aplikasi Flutter:

1. Tambahkan `http`/`dio` + penyimpanan token aman
   (`flutter_secure_storage`).
2. Buat API client dengan base URL:
   - Android emulator: `http://10.0.2.2:3000`
   - iOS simulator: `http://localhost:3000`
   - device fisik: IP LAN mesin backend
   - produksi: HTTPS domain API
3. Simpan `accessToken`, `refreshToken`, dan `expiresAt`; panggil
   `POST /auth/refresh` sebelum expired (atau saat 401).
4. Ganti `lib/data/mock_data.dart` dengan repository yang memanggil endpoint:
   - `UserProfile` ← `GET /me`
   - `NewsItem` ← `GET /news` / `GET /news/:id`
   - `WasteDeposit` ← `GET /deposits` / `GET /deposits/:id`
   - `WasteBank` ← `GET /waste-banks`
5. Set `PUBLIC_BASE_URL` backend ke host yang bisa diakses device (mis.
   `http://10.0.2.2:3000` untuk Android emulator) agar `imageUrl` dan
   `avatarUrl` valid.
6. Halaman QR: panggil `POST /qr/session`, render QR dari `qrPayload`/
   `token`, tampilkan countdown `expiresInSeconds`.
7. Setor/jemput: `POST /deposits`. Reward: `GET /rewards`,
   `POST /rewards/:id/redeem`.
8. Petugas: login role `officer`, gunakan `GET /officer/deposits` dan
   `POST /deposits/:id/complete`, atau `POST /qr/scan`.

Mapping status backend → UI:

| Backend | UI |
| --- | --- |
| `dropoff` | Setor |
| `pickup` | Jemput |
| `scheduled` | Terjadwal / Menunggu penjemputan |
| `processing` | Diproses |
| `completed` | Selesai |
| `cancelled` | Dibatalkan |

## Struktur

```text
backend/
├── drizzle/                  # SQL migration + journal
├── public/                   # avatar & gambar berita statis
├── src/
│   ├── app.ts                # Fastify app factory
│   ├── index.ts              # entrypoint produksi
│   ├── config.ts             # env + validasi
│   ├── auth/                 # Supabase auth provider + interface
│   ├── db/                   # schema, client, migrate/seed CLI
│   ├── lib/                  # poin, level, jarak, serializer, validasi
│   ├── plugins/              # auth guard, error handler
│   ├── routes/               # endpoint per domain
│   ├── services/             # profil & transaksi setoran
│   └── schemas.ts            # response schema + OpenAPI
├── tests/                    # integration tests + fake auth
├── Dockerfile
└── README.md
```

## Batasan MVP

- Reset password dan verifikasi email belum diekspos lewat API.
- Upload foto setoran/avatar belum ada; avatar memakai URL, berita memakai
  aset statis backend.
- Notifikasi push/email belum ada.
- Admin belum bisa CRUD berita/bank sampah/user.
- Leaderboard baru all-time (belum bulanan).
- Belum ada idempotency key untuk create deposit/redemption.
- Aplikasi Flutter masih memakai mock data.
