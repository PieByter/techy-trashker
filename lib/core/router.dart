import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/map/map_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/qr/qr_screen.dart';
import '../features/shell/main_shell.dart';
import 'theme/app_colors.dart';

abstract final class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return MainShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (context, state) => const HomeScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/history',
                  builder: (context, state) => const HistoryScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/map',
                  builder: (context, state) => const MapScreen(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (context, state) => const ProfileScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(path: '/qr', builder: (context, state) => const QrScreen()),
      ],
      errorBuilder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.cream,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.eco_rounded,
                    color: AppColors.forest,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Halaman tidak ditemukan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Kembali ke Beranda'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
