import 'package:flutter/material.dart';

import '../core/auth/auth_controller.dart';
import '../features/authentication/presentation/pages/forgot_password_page.dart';
import '../features/authentication/presentation/pages/login_page.dart';
import '../features/authentication/presentation/pages/reset_password_page.dart';
import '../features/authentication/presentation/pages/welcome_page.dart';
import 'theme/app_theme.dart';

class QuizApp extends StatelessWidget {
  const QuizApp({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuizApp',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.light,

      onGenerateRoute: _onGenerateRoute,

      home: AnimatedBuilder(
        animation: authController,
        builder: (context, child) {
          switch (authController.status) {
            case AuthStatus.initializing:
              return const _AuthSplashPage();
            case AuthStatus.authenticated:
              return WelcomePage(authController: authController);
            case AuthStatus.authenticating:
            case AuthStatus.unauthenticated:
              return LoginPage(authController: authController);
          }
        },
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final uri = Uri.tryParse(settings.name ?? '/');
    if (uri == null) {
      return null;
    }

    switch (uri.path) {
      case '/forgot-password':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ForgotPasswordPage(authController: authController),
        );
      case '/reset-password':
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ResetPasswordPage(
            authController: authController,
            email: uri.queryParameters['email'] ?? '',
            token: uri.queryParameters['token'] ?? '',
          ),
        );
    }

    return null;
  }
}

class _AuthSplashPage extends StatelessWidget {
  const _AuthSplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
