import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MaterialStyle {
  const MaterialStyle({
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final Color foreground;
  final Color background;
}

MaterialStyle styleForCategory(String category) {
  switch (category.toLowerCase()) {
    case 'plastik':
      return const MaterialStyle(
        icon: Icons.water_drop_rounded,
        foreground: AppColors.skyInk,
        background: AppColors.sky,
      );
    case 'kertas':
      return const MaterialStyle(
        icon: Icons.description_rounded,
        foreground: Color(0xFF9A6B1F),
        background: AppColors.amberSoft,
      );
    case 'logam':
      return const MaterialStyle(
        icon: Icons.hardware_rounded,
        foreground: AppColors.lilacInk,
        background: AppColors.lilac,
      );
    case 'organik':
      return const MaterialStyle(
        icon: Icons.compost_rounded,
        foreground: AppColors.forest,
        background: AppColors.mint,
      );
    case 'e-waste':
      return const MaterialStyle(
        icon: Icons.devices_other_rounded,
        foreground: AppColors.roseInk,
        background: AppColors.rose,
      );
    default:
      return const MaterialStyle(
        icon: Icons.recycling_rounded,
        foreground: AppColors.forest,
        background: AppColors.mint,
      );
  }
}
