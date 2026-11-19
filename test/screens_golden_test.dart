import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techy_trashker/core/theme/app_colors.dart';
import 'package:techy_trashker/core/theme/app_theme.dart';
import 'package:techy_trashker/core/widgets/app_bottom_nav.dart';
import 'package:techy_trashker/features/auth/login_screen.dart';
import 'package:techy_trashker/features/history/history_screen.dart';
import 'package:techy_trashker/features/home/home_screen.dart';
import 'package:techy_trashker/features/map/map_screen.dart';
import 'package:techy_trashker/features/onboarding/onboarding_screen.dart';
import 'package:techy_trashker/features/profile/profile_screen.dart';
import 'package:techy_trashker/features/qr/qr_screen.dart';

Future<void> _loadFonts() async {
  final loader = FontLoader('Poppins');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    loader.addFont(rootBundle.load('assets/fonts/Poppins-$weight.ttf'));
  }
  await loader.load();

  final icons = FontLoader('MaterialIcons');
  icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> _precacheImages(WidgetTester tester) async {
  await tester.runAsync(() async {
    for (final asset in const [
      'assets/images/news-1.jpg',
      'assets/images/news-2.jpg',
      'assets/images/news-3.jpg',
      'assets/images/avatar.jpg',
    ]) {
      final stream = AssetImage(asset).resolve(ImageConfiguration.empty);
      final completer = Completer<void>();
      late final ImageStreamListener listener;

      void finish() {
        if (!completer.isCompleted) completer.complete();
      }

      listener = ImageStreamListener(
        (image, synchronousCall) {
          finish();
          stream.removeListener(listener);
        },
        onError: (error, stackTrace) {
          finish();
          stream.removeListener(listener);
        },
      );
      stream.addListener(listener);
      await completer.future;
    }
  });
}

void main() {
  setUpAll(_loadFonts);

  Future<void> capture(
    WidgetTester tester,
    Widget screen,
    String name, {
    int selectedNav = 0,
    bool shell = true,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    await _precacheImages(tester);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final content = shell
        ? Scaffold(
            backgroundColor: AppColors.cream,
            extendBody: true,
            body: screen,
            bottomNavigationBar: AppBottomNav(
              selectedIndex: selectedNav,
              onSelect: (_) {},
            ),
          )
        : screen;

    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('screen'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: content,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('screen')),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('onboarding screenshot', (tester) async {
    await capture(tester, const OnboardingScreen(), 'onboarding', shell: false);
  });

  testWidgets('login screenshot', (tester) async {
    await capture(tester, const LoginScreen(), 'login', shell: false);
  });

  testWidgets('home screenshot', (tester) async {
    await capture(tester, const HomeScreen(), 'home');
  });

  testWidgets('history screenshot', (tester) async {
    await capture(tester, const HistoryScreen(), 'history', selectedNav: 1);
  });

  testWidgets('map screenshot', (tester) async {
    await capture(
      tester,
      const TickerMode(enabled: false, child: MapScreen()),
      'map',
      selectedNav: 3,
    );
  });

  testWidgets('profile screenshot', (tester) async {
    await capture(tester, const ProfileScreen(), 'profile', selectedNav: 4);
  });

  testWidgets('qr screenshot', (tester) async {
    await capture(tester, const QrScreen(), 'qr', shell: false);
  });
}
