import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  /// 0 = Beranda, 1 = Riwayat, 2 = QR, 3 = Peta, 4 = Profil.
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = <_NavItem>[
    _NavItem('Beranda', Icons.home_rounded),
    _NavItem('Riwayat', Icons.receipt_long_rounded),
    _NavItem('Setor', Icons.qr_code_2_rounded),
    _NavItem('Peta', Icons.map_rounded),
    _NavItem('Profil', Icons.person_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 96,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 96,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.forestDark,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.forestDark.withValues(
                                alpha: .28,
                              ),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Row(
                          children: [
                            for (var i = 0; i < _items.length; i++)
                              if (i == 2)
                                const Expanded(child: SizedBox())
                              else
                                Expanded(
                                  child: _NavButton(
                                    item: _items[i],
                                    selected: selectedIndex == i,
                                    onTap: () => onSelect(i),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Semantics(
                          button: true,
                          label: 'Setor sampah dengan QR',
                          child: Material(
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 10,
                            shadowColor: Colors.black.withValues(alpha: .22),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => onSelect(2),
                              child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.cream,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.qr_code_2_rounded,
                                  color: AppColors.forest,
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Colors.white.withValues(alpha: .55);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: .12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: color, size: 22),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.label, this.icon);

  final String label;
  final IconData icon;
}
