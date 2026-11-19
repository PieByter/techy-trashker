import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/deposit_tile.dart';
import '../../core/widgets/eco_pattern.dart';
import '../../core/widgets/page_container.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../core/widgets/section_header.dart';
import '../../data/mock_data.dart';
import '../../data/models/news_item.dart';
import '../../data/models/user_profile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: PageContainer(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HomeHeader(
                profile: demoProfile,
                onNotifications: () => _showNotifications(context),
              ),
              const SizedBox(height: 22),
              _PointsCard(
                profile: demoProfile,
                onRewards: () => _showRewardsSheet(context),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Hot News',
                actionLabel: 'Lihat semua',
                onAction: () => _showAllNews(context),
              ),
              const SizedBox(height: 12),
              _NewsCarousel(
                news: demoNews,
                onTap: (item) => _showNewsDetail(context, item),
              ),
              const SizedBox(height: 26),
              const SectionHeader(title: 'Aksi Cepat'),
              const SizedBox(height: 12),
              _QuickActions(
                onPickup: () => _showPickupSheet(context),
                onDeposit: () => context.push('/qr'),
                onHistory: () => context.go('/history'),
                onRewards: () => _showRewardsSheet(context),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Aktivitas Terakhir',
                actionLabel: 'Riwayat',
                onAction: () => context.go('/history'),
              ),
              const SizedBox(height: 12),
              for (final deposit in demoDeposits.take(2)) ...[
                DepositTile(deposit: deposit),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
              _NearestBankCard(onTap: () => context.go('/map')),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AppSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifikasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Update terbaru seputar aktivitasmu.',
                style: Theme.of(sheetContext).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              const _NotificationRow(
                icon: Icons.local_shipping_rounded,
                title: 'Penjemputan dijadwalkan',
                subtitle: 'Besok, 08.00 · Kurir Budi',
                color: AppColors.forest,
                background: AppColors.mint,
              ),
              const SizedBox(height: 10),
              const _NotificationRow(
                icon: Icons.workspace_premium_rounded,
                title: 'Kamu naik level!',
                subtitle: 'Eco Warrior · +12 poin minggu ini',
                color: Color(0xFF9A6B1F),
                background: AppColors.amberSoft,
              ),
              const SizedBox(height: 10),
              const _NotificationRow(
                icon: Icons.card_giftcard_rounded,
                title: 'Reward baru tersedia',
                subtitle: 'Tumbler Eco hanya 120 poin',
                color: AppColors.skyInk,
                background: AppColors.sky,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAllNews(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AppSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Semua Berita',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 14),
              for (final item in demoNews) ...[
                _NewsListTile(
                  item: item,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showNewsDetail(context, item);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showNewsDetail(BuildContext context, NewsItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.sizeOf(sheetContext).height * .86,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    SizedBox(
                      height: 240,
                      width: double.infinity,
                      child: Image.asset(item.imageAsset, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: _Pill(
                        label: item.category,
                        background: Colors.white.withValues(alpha: .92),
                        foreground: AppColors.forest,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Material(
                        color: Colors.white.withValues(alpha: .92),
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.date,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '3 menit baca',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        item.summary,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Techy Trashker terus mengajak warga untuk memilah sampah '
                        'dari rumah. Mulai dari langkah kecil: pisahkan organik '
                        'dan anorganik, lalu setor ke bank sampah terdekat.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPickupSheet(BuildContext context) {
    var selectedType = 'Plastik';
    var selectedDate = 'Besok';
    var address = '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return AppSheet(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Jemput Sampah',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pilih jenis sampah dan jadwal penjemputan.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel('Jenis sampah'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final type in const [
                          'Plastik',
                          'Kertas',
                          'Logam',
                          'Organik',
                          'E-Waste',
                        ])
                          _ChoicePill(
                            label: type,
                            selected: selectedType == type,
                            onTap: () =>
                                setSheetState(() => selectedType = type),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel('Alamat penjemputan'),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (value) => address = value,
                      decoration: const InputDecoration(
                        hintText: 'Nama jalan, nomor rumah, patokan',
                        prefixIcon: Icon(
                          Icons.location_on_outlined,
                          color: AppColors.muted,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const _FieldLabel('Jadwal'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final date in const [
                          'Hari ini',
                          'Besok',
                          'Pilih tanggal',
                        ])
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: date == 'Pilih tanggal' ? 0 : 8,
                              ),
                              child: _ChoicePill(
                                label: date,
                                selected: selectedDate == date,
                                onTap: () =>
                                    setSheetState(() => selectedDate = date),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final messenger = ScaffoldMessenger.of(context);
                          Navigator.pop(sheetContext);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                address.trim().isEmpty
                                    ? 'Penjemputan $selectedType dijadwalkan $selectedDate (demo).'
                                    : 'Penjemputan $selectedType ke $address dijadwalkan $selectedDate (demo).',
                              ),
                            ),
                          );
                        },
                        child: const Text('Jadwalkan Penjemputan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRewardsSheet(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        void redeem(String title) {
          Navigator.pop(sheetContext);
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text('$title berhasil ditukar (demo).')),
            );
        }

        return AppSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tukar Poin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  _Pill(
                    label: '${demoProfile.points} poin',
                    background: AppColors.mint,
                    foreground: AppColors.forest,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Tukarkan poinmu dengan reward yang bermanfaat.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 18),
              _RewardRow(
                icon: Icons.local_offer_rounded,
                title: 'Voucher Belanja Rp 10.000',
                points: 50,
                available: true,
                onTap: () => redeem('Voucher Belanja Rp 10.000'),
              ),
              const SizedBox(height: 10),
              _RewardRow(
                icon: Icons.local_cafe_rounded,
                title: 'Tumbler Eco',
                points: 120,
                available: true,
                onTap: () => redeem('Tumbler Eco'),
              ),
              const SizedBox(height: 10),
              const _RewardRow(
                icon: Icons.emoji_nature_rounded,
                title: 'Tanaman Hias',
                points: 200,
                available: false,
              ),
              const SizedBox(height: 10),
              _RewardRow(
                icon: Icons.park_rounded,
                title: 'Donasi 1 Pohon',
                points: 75,
                available: true,
                onTap: () => redeem('Donasi 1 Pohon'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.profile, required this.onNotifications});

  final UserProfile profile;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, selamat pagi',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    '${profile.firstName}!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text('👋', style: TextStyle(fontSize: 20)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    'Medan, Sumatera Utara',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        _CircleIconButton(
          icon: Icons.notifications_none_rounded,
          showDot: true,
          onTap: onNotifications,
        ),
        const SizedBox(width: 10),
        ProfileAvatar(initials: profile.initials, size: 48, showRing: true),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
              ),
              child: Icon(icon, color: AppColors.ink, size: 22),
            ),
          ),
        ),
        if (showDot)
          Positioned(
            top: 9,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.amber,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.profile, required this.onRewards});

  final UserProfile profile;
  final VoidCallback onRewards;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 202,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.forest, AppColors.forestDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: .22),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: EcoPattern(opacity: .10)),
          Positioned(
            right: -34,
            top: -24,
            child: Icon(
              Icons.recycling_rounded,
              size: 190,
              color: Colors.white.withValues(alpha: .06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.eco_rounded,
                      color: AppColors.sage,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'Poin Kamu',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .72),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.trending_up_rounded,
                            color: AppColors.amber,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+12 minggu ini',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .82),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatPoints(profile.points),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 46,
                        height: .95,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 6),
                      child: Text(
                        'poin',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .64),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onRewards,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cream,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Tukar Reward',
                              style: TextStyle(
                                color: AppColors.forestDark,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: AppColors.forestDark,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      '${profile.nextLevelPoints - profile.points} poin lagi menuju level berikutnya',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .62),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(profile.levelProgress * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: profile.levelProgress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: .12),
                    valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsCarousel extends StatelessWidget {
  const _NewsCarousel({required this.news, required this.onTap});

  final List<NewsItem> news;
  final ValueChanged<NewsItem> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 212,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: news.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return _NewsCard(
            item: news[index],
            width: index == 0 ? 292 : 250,
            onTap: () => onTap(news[index]),
          );
        },
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({
    required this.item,
    required this.width,
    required this.onTap,
  });

  final NewsItem item;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.forestDark,
        borderRadius: BorderRadius.circular(26),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(item.imageAsset, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.forestDark.withValues(alpha: .28),
                      AppColors.forestDark.withValues(alpha: .94),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, .42, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Pill(
                      label: item.category,
                      background: Colors.white.withValues(alpha: .90),
                      foreground: AppColors.forest,
                    ),
                    const Spacer(),
                    Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 11,
                          color: Colors.white.withValues(alpha: .62),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          item.date,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .62),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_outward_rounded,
                          size: 16,
                          color: Colors.white.withValues(alpha: .72),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onPickup,
    required this.onDeposit,
    required this.onHistory,
    required this.onRewards,
  });

  final VoidCallback onPickup;
  final VoidCallback onDeposit;
  final VoidCallback onHistory;
  final VoidCallback onRewards;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        label: 'Jemput\nSampah',
        icon: Icons.local_shipping_rounded,
        background: AppColors.mint,
        foreground: AppColors.forest,
        onTap: onPickup,
      ),
      (
        label: 'Setor\nSampah',
        icon: Icons.qr_code_2_rounded,
        background: AppColors.amberSoft,
        foreground: const Color(0xFF9A6B1F),
        onTap: onDeposit,
      ),
      (
        label: 'Riwayat\nSetor',
        icon: Icons.receipt_long_rounded,
        background: AppColors.sky,
        foreground: AppColors.skyInk,
        onTap: onHistory,
      ),
      (
        label: 'Tukar\nReward',
        icon: Icons.card_giftcard_rounded,
        background: AppColors.rose,
        foreground: AppColors.roseInk,
        onTap: onRewards,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: actions[i].onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: actions[i].background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        actions[i].icon,
                        color: actions[i].foreground,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      actions[i].label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 10.5,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (i != actions.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _NearestBankCard extends StatelessWidget {
  const _NearestBankCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: AppColors.mint,
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.forest,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bank Sampah Terdekat',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(
                  'Bank Sampah Berseri · 0,8 km',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_rounded,
            color: AppColors.forest,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsListTile extends StatelessWidget {
  const _NewsListTile({required this.item, required this.onTap});

  final NewsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(10),
      onTap: onTap,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              item.imageAsset,
              width: 74,
              height: 64,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.category,
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(item.date, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.muted,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({
    required this.icon,
    required this.title,
    required this.points,
    required this.available,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final int points;
  final bool available;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: available ? AppColors.amberSoft : AppColors.line,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: available ? const Color(0xFF9A6B1F) : AppColors.muted,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '$points poin',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: available ? AppColors.forest : AppColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                available ? 'Tukar' : 'Locked',
                style: TextStyle(
                  color: available ? Colors.white : AppColors.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }
}

class _ChoicePill extends StatelessWidget {
  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.forest : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.forest : AppColors.line,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: .2,
        ),
      ),
    );
  }
}
