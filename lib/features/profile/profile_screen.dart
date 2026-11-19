import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/session_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/eco_pattern.dart';
import '../../core/widgets/page_container.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../data/api/api_client.dart';
import '../../data/mock_data.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/app_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.session});

  final SessionController? session;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final AppRepository _repository =
      widget.session?.repository ?? AppRepository(ApiClient());
  late Future<UserProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = widget.session == null
        ? Future.value(demoProfile)
        : _repository.getProfile();
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label akan tersedia segera.')));
  }

  void _showSettings(BuildContext context) {
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
                'Pengaturan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              const _SettingsRow(
                icon: Icons.notifications_none_rounded,
                title: 'Notifikasi',
                subtitle: 'Pengingat jemput & reward',
              ),
              const SizedBox(height: 10),
              const _SettingsRow(
                icon: Icons.language_rounded,
                title: 'Bahasa',
                subtitle: 'Bahasa Indonesia',
              ),
              const SizedBox(height: 10),
              const _SettingsRow(
                icon: Icons.shield_outlined,
                title: 'Privasi & Keamanan',
                subtitle: 'Kelola data akunmu',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Selesai'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Bantuan & FAQ'),
          content: const Text(
            'Punya pertanyaan tentang setor sampah, penjemputan, atau poin? '
            'Hubungi tim Techy Trashker di support@techytrashker.id.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editProfile(BuildContext context, UserProfile profile) async {
    final controller = TextEditingController(text: profile.name);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Profil'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Nama lengkap'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().length < 2) return;

    try {
      final updated = await _repository.updateProfile(name: name.trim());
      if (!mounted) return;
      setState(() => _profileFuture = Future.value(updated));
      await widget.session?.refreshProfile();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Keluar dari akun?'),
          content: const Text(
            'Kamu bisa masuk kembali kapan saja untuk melihat poin dan riwayat.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await widget.session?.logout();
                  if (context.mounted) context.go('/login');
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfile>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => setState(
                      () => _profileFuture = _repository.getProfile(),
                    ),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          );
        }
        return _buildProfile(context, snapshot.requireData);
      },
    );
  }

  Widget _buildProfile(BuildContext context, UserProfile profile) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: PageContainer(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Profil',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  _CircleButton(
                    icon: Icons.settings_outlined,
                    onTap: () => _showSettings(context),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ProfileHero(
                profile: profile,
                onEdit: () => _editProfile(context, profile),
              ),
              const SizedBox(height: 24),
              _MenuSection(
                title: 'Akun',
                items: [
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit Profil',
                    subtitle: 'Nama, email, dan foto',
                    onTap: () => _editProfile(context, profile),
                  ),
                  _MenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Alamat & Lokasi',
                    subtitle: 'Medan, Sumatera Utara',
                    onTap: () => _showComingSoon(context, 'Alamat'),
                  ),
                  _MenuItem(
                    icon: Icons.card_giftcard_rounded,
                    title: 'Reward Saya',
                    subtitle: '${profile.rewards} reward ditukar',
                    onTap: () => _showComingSoon(context, 'Reward'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _MenuSection(
                title: 'Lainnya',
                items: [
                  _MenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Pengaturan',
                    subtitle: 'Notifikasi, bahasa, privasi',
                    onTap: () => _showSettings(context),
                  ),
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Bantuan & FAQ',
                    subtitle: 'Pertanyaan yang sering diajukan',
                    onTap: () => _showHelp(context),
                  ),
                  _MenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang Aplikasi',
                    subtitle: 'Techy Trashker v1.0.0',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'Techy Trashker',
                      applicationVersion: '1.0.0',
                      applicationLegalese: 'Prototype · data dummy',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              AppCard(
                padding: const EdgeInsets.all(14),
                onTap: () => _showLogoutDialog(context),
                child: const Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: AppColors.danger,
                      size: 21,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Keluar',
                        style: TextStyle(
                          color: AppColors.danger,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.danger,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Center(
                child: Text(
                  'Techy Trashker v1.0.0',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.onEdit});

  final UserProfile profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.forest, AppColors.forestDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: .18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: EcoPattern(opacity: .09)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfileAvatar(
                    initials: profile.initials,
                    size: 66,
                    showRing: true,
                    imageAsset: profile.avatarUrl == null
                        ? 'assets/images/avatar.jpg'
                        : null,
                    imageUrl: profile.avatarUrl,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.workspace_premium_rounded,
                                    color: AppColors.amber,
                                    size: 12,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Eco Warrior',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .10),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ProfileStat(
                      value: formatWeight(profile.totalWeightKg),
                      label: 'Total Sampah',
                    ),
                  ),
                  _Divider(),
                  Expanded(
                    child: _ProfileStat(
                      value: formatPoints(profile.points),
                      label: 'Poin',
                    ),
                  ),
                  _Divider(),
                  Expanded(
                    child: _ProfileStat(
                      value: '${profile.rewards}',
                      label: 'Reward',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    profile.level,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .70),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${profile.points}/${profile.nextLevelPoints}',
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
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: .62),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      color: Colors.white.withValues(alpha: .14),
    );
  }
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                _MenuTile(item: items[i]),
                if (i != items.length - 1)
                  const Divider(indent: 62, endIndent: 16),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item});

  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(item.icon, color: AppColors.forest, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

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
          Icon(icon, color: AppColors.forest, size: 21),
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
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
          child: Icon(icon, color: AppColors.ink, size: 21),
        ),
      ),
    );
  }
}
