import 'package:flutter/material.dart';

import '../core/auth/auth_controller.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class QuizApp extends StatefulWidget {
  const QuizApp({super.key, required this.authController});

  final AuthController authController;

  @override
  State<QuizApp> createState() => _QuizAppState();
}

class _QuizAppState extends State<QuizApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(authController: widget.authController);
  }

  @override
  void dispose() {
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'QuizApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _appRouter.router,
    );
  }
}
