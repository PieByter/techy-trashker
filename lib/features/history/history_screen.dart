import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/material_style.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/deposit_tile.dart';
import '../../core/widgets/eco_pattern.dart';
import '../../core/widgets/page_container.dart';
import '../../data/mock_data.dart';
import '../../data/models/waste_deposit.dart';

enum _HistoryFilter { all, dropOff, pickup }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  var _filter = _HistoryFilter.all;
  var _newestFirst = true;

  List<WasteDeposit> get _filtered {
    final items = demoDeposits.where((deposit) {
      switch (_filter) {
        case _HistoryFilter.all:
          return true;
        case _HistoryFilter.dropOff:
          return deposit.method == DepositMethod.dropOff;
        case _HistoryFilter.pickup:
          return deposit.method == DepositMethod.pickup;
      }
    }).toList();

    items.sort(
      (a, b) =>
          _newestFirst ? b.date.compareTo(a.date) : a.date.compareTo(b.date),
    );
    return items;
  }

  void _toggleSort() {
    setState(() => _newestFirst = !_newestFirst);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _newestFirst
                ? 'Diurutkan dari transaksi terbaru.'
                : 'Diurutkan dari transaksi terlama.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        child: PageContainer(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
          child: Column(
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
                          'Riwayat',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Semua aktivitas sampahmu ada di sini.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _CircleButton(
                    icon: Icons.swap_vert_rounded,
                    onTap: _toggleSort,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _SummaryCard(),
              const SizedBox(height: 22),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Semua',
                      selected: _filter == _HistoryFilter.all,
                      onTap: () => setState(() => _filter = _HistoryFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Setor',
                      selected: _filter == _HistoryFilter.dropOff,
                      onTap: () =>
                          setState(() => _filter = _HistoryFilter.dropOff),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Jemput',
                      selected: _filter == _HistoryFilter.pickup,
                      onTap: () =>
                          setState(() => _filter = _HistoryFilter.pickup),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Transaksi',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Text(
                    '${items.length} item',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (items.isEmpty)
                const _EmptyState()
              else
                for (final deposit in items) ...[
                  DepositTile(
                    deposit: deposit,
                    onTap: () => _showDepositDetail(context, deposit),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }

  void _showDepositDetail(BuildContext context, WasteDeposit deposit) {
    final style = styleForCategory(deposit.category);
    final status = switch (deposit.status) {
      DepositStatus.completed => ('Selesai', AppColors.forest),
      DepositStatus.processing => ('Diproses', const Color(0xFF9A6B1F)),
      DepositStatus.scheduled => ('Dijadwalkan', AppColors.skyInk),
    };

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AppSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detail Transaksi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: status.$2.withValues(alpha: .10),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      status.$1,
                      style: TextStyle(
                        color: status.$2,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: Container(
                  width: 78,
                  height: 78,
                  decoration: BoxDecoration(
                    color: style.background,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(style.icon, color: style.foreground, size: 34),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  deposit.material,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  deposit.id,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 22),
              _DetailRow(
                label: 'Tanggal',
                value: formatShortDate(deposit.date),
              ),
              _DetailRow(label: 'Berat', value: deposit.weightLabel),
              _DetailRow(
                label: 'Metode',
                value: deposit.method == DepositMethod.pickup
                    ? 'Dijemput kurir'
                    : 'Setor mandiri',
              ),
              _DetailRow(
                label: 'Poin didapat',
                value: '+${deposit.points} poin',
                valueColor: AppColors.forest,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 142,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.forest, AppColors.forestDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    value: formatPoints(demoProfile.points),
                    label: 'Total Poin',
                    icon: Icons.eco_rounded,
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _SummaryStat(
                    value: formatWeight(demoProfile.totalWeightKg),
                    label: 'Total Sampah',
                    icon: Icons.scale_rounded,
                  ),
                ),
                _VerticalDivider(),
                Expanded(
                  child: _SummaryStat(
                    value: '${demoDeposits.length}',
                    label: 'Transaksi',
                    icon: Icons.receipt_long_rounded,
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

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.sage, size: 18),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
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

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 46,
      color: Colors.white.withValues(alpha: .14),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.forest : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected ? AppColors.forest : AppColors.line,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 38, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.mint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.forest,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada transaksi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Transaksi yang cocok dengan filter ini belum tersedia.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor = AppColors.ink,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
