import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.initials,
    this.size = 52,
    this.showRing = false,
    this.imageAsset,
  });

  final String initials;
  final double size;
  final bool showRing;

  /// Optional bundled photo (e.g. the one used in the Figma design).
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final Widget avatar;
    if (imageAsset != null) {
      avatar = CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.mint,
        backgroundImage: AssetImage(imageAsset!),
      );
    } else {
      avatar = Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [AppColors.forestSoft, AppColors.forestDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.34,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      );
    }

    if (!showRing) return avatar;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: avatar,
    );
  }
}
