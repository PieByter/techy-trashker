import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_bottom_nav.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onSelect(BuildContext context, int index) {
    if (index == 2) {
      context.push('/qr');
      return;
    }

    final branch = index < 2 ? index : index - 1;
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = navigationShell.currentIndex < 2
        ? navigationShell.currentIndex
        : navigationShell.currentIndex + 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        extendBody: true,
        body: navigationShell,
        bottomNavigationBar: PointerInterceptor(
          child: AppBottomNav(
            selectedIndex: selectedIndex,
            onSelect: (index) => _onSelect(context, index),
          ),
        ),
      ),
    );
  }
}
