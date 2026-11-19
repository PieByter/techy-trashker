import { eq, inArray, sql } from 'drizzle-orm';
import type { AppDatabase } from './index';
import {
  depositItems,
  deposits,
  news,
  pointTransactions,
  profiles,
  rewards,
  wasteBanks,
} from './schema';

export interface SeedUserIds {
  member: string;
  officer: string;
  admin: string;
}

export const DEFAULT_SEED_USER_IDS: SeedUserIds = {
  member: '11111111-1111-4111-8111-111111111111',
  officer: '22222222-2222-4222-8222-222222222222',
  admin: '33333333-3333-4333-8333-333333333333',
};

export const DEMO_ACCOUNTS = [
  {
    key: 'member' as const,
    name: 'Andhika Pratama',
    email: 'andhika@techytrashker.id',
    password: 'rahasia123',
    role: 'user' as const,
    memberCode: 'TT-2024-00147',
    points: 147,
    totalWeightKg: 12.4,
    avatarUrl: '/static/avatar.jpg',
  },
  {
    key: 'officer' as const,
    name: 'Petugas Bank Sampah',
    email: 'petugas@techytrashker.id',
    password: 'rahasia123',
    role: 'officer' as const,
    memberCode: 'TT-2024-90001',
    points: 0,
    totalWeightKg: 0,
    avatarUrl: null,
  },
  {
    key: 'admin' as const,
    name: 'Admin Techy Trashker',
    email: 'admin@techytrashker.id',
    password: 'rahasia123',
    role: 'admin' as const,
    memberCode: 'TT-2024-90000',
    points: 0,
    totalWeightKg: 0,
    avatarUrl: null,
  },
];

const BANK_IDS = {
  berseri: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa1',
  medanPeduli: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa2',
  ecoCenter: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa3',
  hijauLestari: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa4',
};

const NEWS_IDS = {
  medan: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb1',
  tips: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb2',
  digital: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbb3',
};

const REWARD_IDS = {
  bibit: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc1',
  tote: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc2',
  tas: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc3',
  voucher: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc4',
  tumbler: 'cccccccc-cccc-4ccc-8ccc-ccccccccccc5',
};

function daysFrom(now: Date, days: number): Date {
  return new Date(now.getTime() + days * 24 * 60 * 60 * 1000);
}

export async function seedDatabase(
  db: AppDatabase,
  options: { users: SeedUserIds; now?: Date },
): Promise<{ memberId: string; officerId: string; adminId: string }> {
  const now = options.now ?? new Date();

  return db.transaction(async (tx) => {
    // ── Profil demo ────────────────────────────────────────────
    await tx
      .insert(profiles)
      .values(
        DEMO_ACCOUNTS.map((account) => ({
          id: options.users[account.key],
          memberCode: account.memberCode,
          name: account.name,
          email: account.email,
          role: account.role,
          points: account.points,
          totalWeightKg: account.totalWeightKg,
          avatarUrl: account.avatarUrl,
        })),
      )
      .onConflictDoNothing();

    const profileRows = await tx
      .select()
      .from(profiles)
      .where(
        inArray(
          profiles.email,
          DEMO_ACCOUNTS.map((account) => account.email),
        ),
      );

    const member = profileRows.find(
      (profile) => profile.email === DEMO_ACCOUNTS[0].email,
    );
    const officer = profileRows.find(
      (profile) => profile.email === DEMO_ACCOUNTS[1].email,
    );
    const admin = profileRows.find(
      (profile) => profile.email === DEMO_ACCOUNTS[2].email,
    );

    if (!member || !officer || !admin) {
      throw new Error('Gagal menyiapkan profil demo.');
    }

    // ── Berita ─────────────────────────────────────────────────
    await tx
      .insert(news)
      .values([
        {
          id: NEWS_IDS.medan,
          title: 'Siswa/i asal Medan adakan gerakan untuk revolusi sampah',
          slug: 'siswa-medan-gerakan-revolusi-sampah',
          category: 'Lingkungan',
          summary:
            'Komunitas pelajar di Medan mengajak warga memilah sampah dari rumah. ' +
            'Gerakan ini menggabungkan edukasi, bank sampah, dan tantangan mingguan ' +
            'untuk mengurangi sampah yang berakhir di TPA.',
          content:
            'Komunitas pelajar di Medan menginisiasi gerakan “Medan Bebas Sampah” ' +
            'yang mengajak warga memilah sampah sejak dari rumah. Kegiatan ini ' +
            'melibatkan sekolah, bank sampah, dan pemerintah kecamatan.\n\n' +
            'Setiap pekan, peserta mencatat berat sampah yang berhasil dipilah dan ' +
            'menyetornya ke bank sampah terdekat. Hasilnya diubah menjadi poin yang ' +
            'bisa ditukar dengan kebutuhan sehari-hari.\n\n' +
            'Selain mengurangi volume sampah ke TPA, gerakan ini membangun kebiasaan ' +
            'baru di keluarga. Edukasi dilakukan lewat kelas singkat, poster, dan ' +
            'tantangan antar-kelas.',
          imageUrl: '/static/news/news-1.jpg',
          publishedAt: new Date('2026-11-12T09:00:00+07:00'),
        },
        {
          id: NEWS_IDS.tips,
          title: '5 cara mudah memilah sampah dari rumah',
          slug: '5-cara-mudah-memilah-sampah-dari-rumah',
          category: 'Tips',
          summary:
            'Mulai dari memisahkan organik, anorganik, dan B3. Sediakan tiga wadah ' +
            'sederhana, beri label, lalu biasakan seluruh anggota keluarga ikut ' +
            'memilah setiap hari.',
          content:
            'Memilah sampah tidak perlu peralatan mahal. Mulailah dengan tiga wadah ' +
            'sederhana: organik, anorganik, dan B3.\n\n' +
            '1. Beri label dan warna berbeda agar mudah diingat.\n' +
            '2. Letakkan wadah di tempat yang sering dilewati.\n' +
            '3. Kosongkan wadah anorganik ke bank sampah minimal sekali sepekan.\n' +
            '4. Pisahkan baterai, lampu, dan elektronik kecil ke wadah B3.\n' +
            '5. Libatkan seluruh anggota keluarga dengan tugas bergilir.\n\n' +
            'Konsistensi lebih penting daripada kesempurnaan. Mulai dari satu jenis ' +
            'sampah yang paling sering muncul di rumah.',
          imageUrl: '/static/news/news-2.jpg',
          publishedAt: new Date('2026-11-08T09:00:00+07:00'),
        },
        {
          id: NEWS_IDS.digital,
          title: 'Bank sampah digital semakin diminati warga kota',
          slug: 'bank-sampah-digital-semakin-diminati',
          category: 'Komunitas',
          summary:
            'Layanan setor sampah berbasis aplikasi memudahkan warga memantau ' +
            'tabungan sampah, poin, dan jadwal penjemputan. Bank sampah kini hadir ' +
            'lebih dekat ke lingkungan tempat tinggal.',
          content:
            'Bank sampah digital mengubah cara warga mengelola sampah. Lewat ' +
            'aplikasi, warga bisa melihat riwayat setoran, saldo poin, dan jadwal ' +
            'penjemputan tanpa harus datang ke lokasi.\n\n' +
            'Petugas bank sampah juga terbantu karena pencatatan berat dan poin ' +
            'dilakukan langsung saat penimbangan. Data tersimpan rapi dan bisa ' +
            'menjadi laporan bulanan.\n\n' +
            'Ke depan, layanan seperti ini diharapkan terhubung dengan program ' +
            'pemerintah daerah dan mitra reward lokal agar semakin banyak warga ' +
            'terdorong memilah sampah.',
          imageUrl: '/static/news/news-3.jpg',
          publishedAt: new Date('2026-11-02T09:00:00+07:00'),
        },
      ])
      .onConflictDoUpdate({
        target: news.slug,
        set: {
          title: sql`excluded.title`,
          category: sql`excluded.category`,
          summary: sql`excluded.summary`,
          content: sql`excluded.content`,
          imageUrl: sql`excluded.image_url`,
          publishedAt: sql`excluded.published_at`,
        },
      });

    // ── Bank sampah ────────────────────────────────────────────
    await tx
      .insert(wasteBanks)
      .values([
        {
          id: BANK_IDS.berseri,
          name: 'Bank Sampah Berseri',
          slug: 'bank-sampah-berseri',
          address: 'Jl. Gatot Subroto No. 12',
          phone: '0812-6000-0001',
          latitude: 3.6015,
          longitude: 98.669,
          rating: 4.8,
          isOpen: true,
          openHours: '08.00 - 16.00',
          mapX: 0.22,
          mapY: 0.1,
        },
        {
          id: BANK_IDS.medanPeduli,
          name: 'Bank Sampah Medan Peduli',
          slug: 'bank-sampah-medan-peduli',
          address: 'Jl. Imam Bonjol No. 45',
          phone: '0812-6000-0002',
          latitude: 3.6075,
          longitude: 98.678,
          rating: 4.6,
          isOpen: true,
          openHours: '08.00 - 17.00',
          mapX: 0.75,
          mapY: 0.25,
        },
        {
          id: BANK_IDS.ecoCenter,
          name: 'Bank Sampah Eco Center',
          slug: 'bank-sampah-eco-center',
          address: 'Jl. Sisingamangaraja No. 8',
          phone: '0812-6000-0003',
          latitude: 3.579,
          longitude: 98.665,
          rating: 4.7,
          isOpen: false,
          openHours: '09.00 - 15.00',
          mapX: 0.16,
          mapY: 0.68,
        },
        {
          id: BANK_IDS.hijauLestari,
          name: 'Bank Sampah Hijau Lestari',
          slug: 'bank-sampah-hijau-lestari',
          address: 'Jl. Ring Road No. 21',
          phone: '0812-6000-0004',
          latitude: 3.62,
          longitude: 98.69,
          rating: 4.5,
          isOpen: true,
          openHours: '08.00 - 16.00',
          mapX: 0.78,
          mapY: 0.82,
        },
      ])
      .onConflictDoUpdate({
        target: wasteBanks.slug,
        set: {
          name: sql`excluded.name`,
          address: sql`excluded.address`,
          phone: sql`excluded.phone`,
          latitude: sql`excluded.latitude`,
          longitude: sql`excluded.longitude`,
          rating: sql`excluded.rating`,
          isOpen: sql`excluded.is_open`,
          openHours: sql`excluded.open_hours`,
          mapX: sql`excluded.map_x`,
          mapY: sql`excluded.map_y`,
        },
      });

    const bankRows = await tx.select().from(wasteBanks);
    const bankBySlug = new Map(bankRows.map((bank) => [bank.slug, bank]));

    // ── Reward ─────────────────────────────────────────────────
    await tx
      .insert(rewards)
      .values([
        {
          id: REWARD_IDS.bibit,
          slug: 'bibit-tanaman',
          title: 'Bibit Tanaman',
          description:
            'Satu paket bibit tanaman hias atau sayur untuk memulai kebun kecil di rumah.',
          pointsCost: 50,
          stock: 25,
        },
        {
          id: REWARD_IDS.tas,
          slug: 'tas-belanja-kain',
          title: 'Tas Belanja Kain',
          description:
            'Tas belanja kain daur ulang yang bisa dipakai berulang kali saat berbelanja.',
          pointsCost: 100,
          stock: 20,
        },
        {
          id: REWARD_IDS.tote,
          slug: 'tote-bag-daur-ulang',
          title: 'Tote Bag Daur Ulang',
          description:
            'Tote bag dari bahan daur ulang dengan desain khas Techy Trashker.',
          pointsCost: 150,
          stock: 12,
        },
        {
          id: REWARD_IDS.voucher,
          slug: 'voucher-belanja-25k',
          title: 'Voucher Belanja Rp25.000',
          description:
            'Voucher digital untuk berbelanja di mitra toko ramah lingkungan.',
          pointsCost: 250,
          stock: 15,
        },
        {
          id: REWARD_IDS.tumbler,
          slug: 'tumbler-eco-500ml',
          title: 'Tumbler Eco 500ml',
          description:
            'Tumbler stainless 500ml untuk mengurangi penggunaan botol plastik sekali pakai.',
          pointsCost: 300,
          stock: 8,
        },
      ])
      .onConflictDoUpdate({
        target: rewards.slug,
        set: {
          title: sql`excluded.title`,
          description: sql`excluded.description`,
          pointsCost: sql`excluded.points_cost`,
          stock: sql`excluded.stock`,
          isActive: sql`excluded.is_active`,
        },
      });

    // ── Setoran demo ───────────────────────────────────────────
    const [existingDeposit] = await tx
      .select({ id: deposits.id })
      .from(deposits)
      .where(eq(deposits.userId, member.id))
      .limit(1);

    if (!existingDeposit) {
      const bsBerseri = bankBySlug.get('bank-sampah-berseri');
      const bsMedanPeduli = bankBySlug.get('bank-sampah-medan-peduli');
      const bsEcoCenter = bankBySlug.get('bank-sampah-eco-center');

      const completedDeposits = [
        {
          id: 'dddddddd-dddd-4ddd-8ddd-dddddddddd43',
          code: 'TT-00143',
          material: 'Elektronik Kecil',
          category: 'E-Waste',
          weightKg: 0.9,
          points: 26,
          method: 'dropoff' as const,
          bankId: bsEcoCenter?.id ?? null,
          completedAt: daysFrom(now, -14),
        },
        {
          id: 'dddddddd-dddd-4ddd-8ddd-dddddddddd44',
          code: 'TT-00144',
          material: 'Sampah Organik',
          category: 'Organik',
          weightKg: 4.8,
          points: 18,
          method: 'pickup' as const,
          bankId: bsBerseri?.id ?? null,
          completedAt: daysFrom(now, -12),
        },
        {
          id: 'dddddddd-dddd-4ddd-8ddd-dddddddddd45',
          code: 'TT-00145',
          material: 'Kaleng Aluminium',
          category: 'Logam',
          weightKg: 1.2,
          points: 24,
          method: 'dropoff' as const,
          bankId: bsEcoCenter?.id ?? null,
          completedAt: daysFrom(now, -9),
        },
        {
          id: 'dddddddd-dddd-4ddd-8ddd-dddddddddd46',
          code: 'TT-00146',
          material: 'Kertas & Kardus',
          category: 'Kertas',
          weightKg: 3.1,
          points: 31,
          method: 'pickup' as const,
          bankId: bsMedanPeduli?.id ?? null,
          completedAt: daysFrom(now, -5),
        },
        {
          id: 'dddddddd-dddd-4ddd-8ddd-dddddddddd47',
          code: 'TT-00147',
          material: 'Botol Plastik',
          category: 'Plastik',
          weightKg: 2.4,
          points: 48,
          method: 'dropoff' as const,
          bankId: bsBerseri?.id ?? null,
          completedAt: daysFrom(now, -2),
        },
      ];

      await tx.insert(deposits).values(
        completedDeposits.map((deposit) => ({
          id: deposit.id,
          code: deposit.code,
          userId: member.id,
          wasteBankId: deposit.bankId,
          method: deposit.method,
          status: 'completed' as const,
          material: deposit.material,
          category: deposit.category,
          weightKg: deposit.weightKg,
          points: deposit.points,
          completedAt: deposit.completedAt,
          createdAt: daysFrom(deposit.completedAt, -1),
          updatedAt: deposit.completedAt,
        })),
      );

      await tx.insert(depositItems).values(
        completedDeposits.map((deposit) => ({
          depositId: deposit.id,
          material: deposit.material,
          category: deposit.category,
          weightKg: deposit.weightKg,
          points: deposit.points,
        })),
      );

      await tx.insert(pointTransactions).values(
        completedDeposits.map((deposit) => ({
          userId: member.id,
          amount: deposit.points,
          type: 'deposit' as const,
          description: `Poin setoran ${deposit.code}`,
          depositId: deposit.id,
          createdAt: deposit.completedAt,
        })),
      );

      await tx.insert(deposits).values({
        id: 'dddddddd-dddd-4ddd-8ddd-dddddddddd48',
        code: 'TT-00148',
        userId: member.id,
        wasteBankId: bsBerseri?.id ?? null,
        method: 'pickup',
        status: 'scheduled',
        material: 'Botol Plastik',
        category: 'Plastik',
        weightKg: 1.5,
        points: 0,
        address: 'Jl. Gatot Subroto No. 12, Medan',
        scheduledAt: daysFrom(now, 2),
        notes: 'Estimasi 1,5 kg botol plastik.',
        createdAt: daysFrom(now, -1),
        updatedAt: daysFrom(now, -1),
      });

      await tx
        .update(profiles)
        .set({
          points: 147,
          totalWeightKg: 12.4,
          updatedAt: now,
        })
        .where(eq(profiles.id, member.id));
    }

    return {
      memberId: member.id,
      officerId: officer.id,
      adminId: admin.id,
    };
  });
}
