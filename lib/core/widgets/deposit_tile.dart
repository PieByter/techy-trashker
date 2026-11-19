import 'package:flutter/material.dart';

import '../../data/models/waste_deposit.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';
import '../utils/material_style.dart';
import 'app_card.dart';

class DepositTile extends StatelessWidget {
  const DepositTile({super.key, required this.deposit, this.onTap});

  final WasteDeposit deposit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = styleForCategory(deposit.category);
    final status = _statusLabel(deposit.status);
    final method = deposit.method == DepositMethod.pickup ? 'Jemput' : 'Setor';

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(style.icon, color: style.foreground, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deposit.material,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatShortDate(deposit.date)}  •  ${deposit.weightLabel}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$method  •  ${status.label}',
                      style: TextStyle(
                        color: status.color,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${deposit.points}',
                style: const TextStyle(
                  color: AppColors.forest,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'poin',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

({String label, Color color}) _statusLabel(DepositStatus status) {
  switch (status) {
    case DepositStatus.completed:
      return (label: 'Selesai', color: AppColors.forest);
    case DepositStatus.processing:
      return (label: 'Diproses', color: const Color(0xFF9A6B1F));
    case DepositStatus.scheduled:
      return (label: 'Dijadwalkan', color: AppColors.skyInk);
    case DepositStatus.cancelled:
      return (label: 'Dibatalkan', color: AppColors.danger);
  }
}
