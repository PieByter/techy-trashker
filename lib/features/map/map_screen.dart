import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/profile_avatar.dart';
import '../../data/mock_data.dart';
import '../../data/models/waste_bank.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  var _query = '';
  var _selectedName = demoWasteBanks.first.name;

  List<WasteBank> get _filteredBanks {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return demoWasteBanks;
    return demoWasteBanks
        .where(
          (bank) =>
              bank.name.toLowerCase().contains(query) ||
              bank.address.toLowerCase().contains(query),
        )
        .toList();
  }

  void _showFilterInfo() {
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
                'Filter Lokasi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Versi prototype menampilkan semua bank sampah di sekitar Medan.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _FilterRow(
                icon: Icons.near_me_rounded,
                title: 'Terdekat',
                subtitle: 'Urutkan berdasarkan jarak',
                selected: true,
              ),
              const SizedBox(height: 10),
              const _FilterRow(
                icon: Icons.star_rounded,
                title: 'Rating tertinggi',
                subtitle: 'Bank sampah dengan ulasan terbaik',
                selected: false,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Terapkan'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final banks = _filteredBanks;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final zoneTop = height * 0.28;
          final zoneHeight = height * 0.18;

          return Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _RadarMapPainter())),
              Positioned(
                left: 0,
                right: 0,
                top: zoneTop,
                height: zoneHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final bank in demoWasteBanks)
                      Positioned(
                        left: (bank.mapX * width - 60).clamp(4.0, width - 124),
                        top: bank.mapY * zoneHeight - 20,
                        child: _BankMarker(
                          bank: bank,
                          selected: _selectedName == bank.name,
                          onTap: () =>
                              setState(() => _selectedName = bank.name),
                        ),
                      ),
                    Positioned(
                      left: width / 2 - 50,
                      top: height * 0.14 - 20,
                      child: const _PulseLocation(),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                left: 20,
                right: 20,
                child: _buildTopPanel(context),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 104 + bottomInset,
                child: _BankListCard(
                  banks: banks,
                  selectedName: _selectedName,
                  onSelect: (bank) => setState(() => _selectedName = bank.name),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Peta',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Temukan bank sampah di sekitarmu.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _CircleButton(icon: Icons.tune_rounded, onTap: _showFilterInfo),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withValues(alpha: .10),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            style: const TextStyle(fontSize: 13.5),
            decoration: const InputDecoration(
              hintText: 'Cari bank sampah atau jalan...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.muted,
                size: 21,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                const SnackBar(
                  content: Text('Lokasi saat ini: Medan, Sumatera Utara.'),
                ),
              );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: .94),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppColors.line),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.forest,
                  size: 14,
                ),
                SizedBox(width: 4),
                Text(
                  'Medan, Sumatera Utara',
                  style: TextStyle(
                    color: AppColors.ink,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.muted,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BankListCard extends StatelessWidget {
  const _BankListCard({
    required this.banks,
    required this.selectedName,
    required this.onSelect,
  });

  final List<WasteBank> banks;
  final String selectedName;
  final ValueChanged<WasteBank> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: .14),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bank Sampah Terdekat',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${banks.length} lokasi',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (banks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Tidak ada bank sampah yang cocok.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          else
            SizedBox(
              height: 126,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: banks.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final bank = banks[index];
                  return _BankCard(
                    bank: bank,
                    selected: bank.name == selectedName,
                    onTap: () => onSelect(bank),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _BankCard extends StatelessWidget {
  const _BankCard({
    required this.bank,
    required this.selected,
    required this.onTap,
  });

  final WasteBank bank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 228,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: selected ? AppColors.mint : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.forest : AppColors.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    bank.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.forest,
                    size: 17,
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              bank.address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.amber,
                  size: 15,
                ),
                const SizedBox(width: 3),
                Text(
                  bank.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.near_me_rounded,
                  color: AppColors.muted,
                  size: 13,
                ),
                const SizedBox(width: 3),
                Text(
                  '${bank.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bank.isOpen
                        ? AppColors.forest.withValues(alpha: .10)
                        : AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    bank.isOpen ? 'Buka' : 'Tutup',
                    style: TextStyle(
                      color: bank.isOpen ? AppColors.forest : AppColors.muted,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BankMarker extends StatelessWidget {
  const _BankMarker({
    required this.bank,
    required this.selected,
    required this.onTap,
  });

  final WasteBank bank;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: selected ? 1 : 0,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 120),
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.forestDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                bank.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 44 : 36,
              height: selected ? 44 : 36,
              decoration: BoxDecoration(
                color: selected ? AppColors.forest : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forestDark.withValues(alpha: .22),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.storefront_rounded,
                color: selected ? Colors.white : AppColors.forest,
                size: selected ? 20 : 17,
              ),
            ),
          ),
          Container(
            width: 2,
            height: 7,
            color: selected ? AppColors.forest : AppColors.surface,
          ),
        ],
      ),
    );
  }
}

class _PulseLocation extends StatefulWidget {
  const _PulseLocation();

  @override
  State<_PulseLocation> createState() => _PulseLocationState();
}

class _PulseLocationState extends State<_PulseLocation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 52 + 44 * t,
                height: 52 + 44 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.forest.withValues(alpha: .18 * (1 - t)),
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.forest, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forest.withValues(alpha: .18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const ProfileAvatar(initials: 'AP', size: 38),
              ),
            ],
          );
        },
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
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withValues(alpha: .08),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.ink, size: 21),
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: selected ? AppColors.mint : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? AppColors.forest : Colors.transparent,
        ),
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
          Icon(
            selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? AppColors.forest : AppColors.muted,
            size: 19,
          ),
        ],
      ),
    );
  }
}

class _RadarMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = const Color(0xFFE9F0E6));

    final grid = Paint()
      ..color = Colors.white.withValues(alpha: .46)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 44) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 44) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }

    // Green pockets / parks.
    final park = Paint()..color = const Color(0xFFDDE9D9);
    canvas.drawCircle(Offset(size.width * .12, size.height * .18), 70, park);
    canvas.drawCircle(Offset(size.width * .9, size.height * .34), 56, park);
    canvas.drawCircle(Offset(size.width * .3, size.height * .7), 90, park);

    // Roads.
    final roadBorder = Paint()
      ..color = const Color(0xFFD7E3D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round;
    final road = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final horizontalRoad = Path()
      ..moveTo(-20, size.height * .42)
      ..cubicTo(
        size.width * .24,
        size.height * .34,
        size.width * .62,
        size.height * .5,
        size.width + 20,
        size.height * .39,
      );
    canvas.drawPath(horizontalRoad, roadBorder);
    canvas.drawPath(horizontalRoad, road);

    final verticalRoad = Path()
      ..moveTo(size.width * .63, -20)
      ..cubicTo(
        size.width * .58,
        size.height * .3,
        size.width * .67,
        size.height * .62,
        size.width * .55,
        size.height + 20,
      );
    canvas.drawPath(verticalRoad, roadBorder);
    canvas.drawPath(verticalRoad, road);

    // Radar rings around the user.
    final center = Offset(size.width * .5, size.height * .42);
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        42.0 * i,
        Paint()
          ..color = AppColors.forest.withValues(alpha: .10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }

    final sweepRect = Rect.fromCircle(center: center, radius: 126);
    final sweep = Paint()
      ..shader = SweepGradient(
        colors: [
          AppColors.forest.withValues(alpha: .00),
          AppColors.forest.withValues(alpha: .13),
        ],
        stops: const [0.0, 1.0],
        startAngle: 0,
        endAngle: math.pi * 1.4,
      ).createShader(sweepRect);
    canvas.drawCircle(center, 126, sweep);

    // Building blocks.
    final block = Paint()..color = Colors.white.withValues(alpha: .55);
    final blocks = <Rect>[
      Rect.fromLTWH(size.width * .08, size.height * .56, 54, 34),
      Rect.fromLTWH(size.width * .78, size.height * .16, 46, 30),
      Rect.fromLTWH(size.width * .68, size.height * .68, 58, 34),
      Rect.fromLTWH(size.width * .38, size.height * .14, 38, 24),
    ];
    for (final b in blocks) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(7)),
        block,
      );
    }

    // Trees.
    final tree = Paint()..color = AppColors.sage.withValues(alpha: .55);
    final trunk = Paint()..color = const Color(0xFFB8C6A4);
    for (final point in [
      Offset(size.width * .16, size.height * .34),
      Offset(size.width * .86, size.height * .58),
      Offset(size.width * .46, size.height * .62),
      Offset(size.width * .7, size.height * .12),
    ]) {
      canvas.drawRect(
        Rect.fromCenter(center: point, width: 2, height: 7),
        trunk,
      );
      canvas.drawCircle(point - const Offset(0, 5), 5, tree);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
