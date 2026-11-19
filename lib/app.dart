import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/auth/session_controller.dart';
import 'core/router.dart';
import 'core/theme/app_theme.dart';

class TechyTrashkerApp extends StatefulWidget {
  const TechyTrashkerApp({super.key, this.session});

  final SessionController? session;

  @override
  State<TechyTrashkerApp> createState() => _TechyTrashkerAppState();
}

class _TechyTrashkerAppState extends State<TechyTrashkerApp> {
  late final SessionController _session = widget.session ?? SessionController();
  late final GoRouter _router = AppRouter.createRouter(_session);

  @override
  void initState() {
    super.initState();
    _session.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Techy Trashker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    if (widget.session == null) _session.dispose();
    super.dispose();
  }
}
