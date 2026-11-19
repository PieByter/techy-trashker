import 'models/news_item.dart';
import 'models/user_profile.dart';
import 'models/waste_bank.dart';
import 'models/waste_deposit.dart';

const demoProfile = UserProfile(
  name: 'Andhika Pratama',
  email: 'andhika@techytrashker.id',
  level: 'Eco Warrior',
  points: 147,
  totalWeightKg: 12.4,
  rewards: 3,
  nextLevelPoints: 200,
);

const demoNews = <NewsItem>[
  NewsItem(
    title: 'Siswa/i asal Medan adakan gerakan untuk revolusi sampah',
    category: 'Lingkungan',
    date: '12 Nov 2026',
    imageAsset: 'assets/images/news-1.jpg',
    summary:
        'Komunitas pelajar di Medan mengajak warga memilah sampah dari rumah. '
        'Gerakan ini menggabungkan edukasi, bank sampah, dan tantangan mingguan '
        'untuk mengurangi sampah yang berakhir di TPA.',
  ),
  NewsItem(
    title: '5 cara mudah memilah sampah dari rumah',
    category: 'Tips',
    date: '08 Nov 2026',
    imageAsset: 'assets/images/news-2.jpg',
    summary:
        'Mulai dari memisahkan organik, anorganik, dan B3. Sediakan tiga wadah '
        'sederhana, beri label, lalu biasakan seluruh anggota keluarga ikut '
        'memilah setiap hari.',
  ),
  NewsItem(
    title: 'Bank sampah digital semakin diminati warga kota',
    category: 'Komunitas',
    date: '02 Nov 2026',
    imageAsset: 'assets/images/news-3.jpg',
    summary:
        'Layanan setor sampah berbasis aplikasi memudahkan warga memantau '
        'tabungan sampah, poin, dan jadwal penjemputan. Bank sampah kini hadir '
        'lebih dekat ke lingkungan tempat tinggal.',
  ),
];

final demoDeposits = <WasteDeposit>[
  WasteDeposit(
    id: 'TT-00147',
    code: 'TT-00147',
    material: 'Botol Plastik',
    category: 'Plastik',
    weightKg: 2.4,
    points: 48,
    date: DateTime.now().subtract(const Duration(days: 2)),
    status: DepositStatus.completed,
    method: DepositMethod.dropOff,
  ),
  WasteDeposit(
    id: 'TT-00146',
    code: 'TT-00146',
    material: 'Kertas & Kardus',
    category: 'Kertas',
    weightKg: 3.1,
    points: 31,
    date: DateTime.now().subtract(const Duration(days: 5)),
    status: DepositStatus.completed,
    method: DepositMethod.pickup,
  ),
  WasteDeposit(
    id: 'TT-00145',
    code: 'TT-00145',
    material: 'Kaleng Aluminium',
    category: 'Logam',
    weightKg: 1.2,
    points: 24,
    date: DateTime.now().subtract(const Duration(days: 9)),
    status: DepositStatus.completed,
    method: DepositMethod.dropOff,
  ),
  WasteDeposit(
    id: 'TT-00144',
    code: 'TT-00144',
    material: 'Sampah Organik',
    category: 'Organik',
    weightKg: 4.8,
    points: 18,
    date: DateTime.now().subtract(const Duration(days: 12)),
    status: DepositStatus.completed,
    method: DepositMethod.pickup,
  ),
  WasteDeposit(
    id: 'TT-00143',
    code: 'TT-00143',
    material: 'Elektronik Kecil',
    category: 'E-Waste',
    weightKg: 0.9,
    points: 26,
    date: DateTime.now().subtract(const Duration(days: 14)),
    status: DepositStatus.processing,
    method: DepositMethod.dropOff,
  ),
];

const demoWasteBanks = <WasteBank>[
  WasteBank(
    id: 'bs-berseri',
    name: 'Bank Sampah Berseri',
    address: 'Jl. Gatot Subroto No. 12',
    distanceKm: 0.8,
    rating: 4.8,
    isOpen: true,
    latitude: 3.6015,
    longitude: 98.6690,
    mapX: 0.22,
    mapY: 0.10,
  ),
  WasteBank(
    id: 'bs-medan-peduli',
    name: 'Bank Sampah Medan Peduli',
    address: 'Jl. Imam Bonjol No. 45',
    distanceKm: 1.4,
    rating: 4.6,
    isOpen: true,
    latitude: 3.6075,
    longitude: 98.6780,
    mapX: 0.75,
    mapY: 0.25,
  ),
  WasteBank(
    id: 'bs-eco-center',
    name: 'Bank Sampah Eco Center',
    address: 'Jl. Sisingamangaraja No. 8',
    distanceKm: 2.1,
    rating: 4.7,
    isOpen: false,
    latitude: 3.5790,
    longitude: 98.6650,
    mapX: 0.16,
    mapY: 0.68,
  ),
  WasteBank(
    id: 'bs-hijau-lestari',
    name: 'Bank Sampah Hijau Lestari',
    address: 'Jl. Ring Road No. 21',
    distanceKm: 3.2,
    rating: 4.5,
    isOpen: true,
    latitude: 3.6200,
    longitude: 98.6900,
    mapX: 0.78,
    mapY: 0.82,
  ),
];
