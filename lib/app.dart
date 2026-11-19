import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router.dart';
import 'core/theme/app_theme.dart';

class TechyTrashkerApp extends StatefulWidget {
  const TechyTrashkerApp({super.key});

  @override
  State<TechyTrashkerApp> createState() => _TechyTrashkerAppState();
}

class _TechyTrashkerAppState extends State<TechyTrashkerApp> {
  late final GoRouter _router = AppRouter.createRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Techy Trashker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
