import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/network/api_client.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/authentication/presentation/pages/confirm_email_page.dart';
import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/reset_password_page.dart';
import '../../features/authentication/presentation/pages/welcome_page.dart';
import '../../features/student/presentation/pages/student_dashboard_page.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter({required AuthController authController, ApiClient? apiClient})
    : router = GoRouter(
        refreshListenable: authController,
        routes: [
          GoRoute(
            path: AppRoutes.splash,
            name: AppRoutes.splashName,
            builder: (context, state) => const _AuthSplashPage(),
          ),
          GoRoute(
            path: AppRoutes.login,
            name: AppRoutes.loginName,
            builder: (context, state) =>
                LoginPage(authController: authController),
          ),
          GoRoute(
            path: AppRoutes.register,
            name: AppRoutes.registerName,
            builder: (context, state) =>
                RegisterPage(authController: authController),
          ),
          GoRoute(
            path: AppRoutes.forgotPassword,
            name: AppRoutes.forgotPasswordName,
            builder: (context, state) =>
                ForgotPasswordPage(authController: authController),
          ),
          GoRoute(
            path: AppRoutes.resetPassword,
            name: AppRoutes.resetPasswordName,
            builder: (context, state) => ResetPasswordPage(
              authController: authController,
              email: state.uri.queryParameters['email'] ?? '',
              token: state.uri.queryParameters['token'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.confirmEmail,
            name: AppRoutes.confirmEmailName,
            builder: (context, state) => ConfirmEmailPage(
              authController: authController,
              email: state.uri.queryParameters['email'] ?? '',
              token: state.uri.queryParameters['token'] ?? '',
            ),
          ),
          GoRoute(
            path: AppRoutes.welcome,
            name: AppRoutes.welcomeName,
            builder: (context, state) =>
                WelcomePage(authController: authController),
          ),
          GoRoute(
            path: AppRoutes.studentDashboard,
            name: AppRoutes.studentDashboardName,
            builder: (context, state) => StudentDashboardPage(
              authController: authController,
              apiClient: apiClient,
            ),
          ),
          GoRoute(
            path: AppRoutes.adminDashboard,
            name: AppRoutes.adminDashboardName,
            builder: (context, state) => AdminDashboardPage(
              authController: authController,
              apiClient: apiClient,
            ),
          ),
        ],
        redirect: (context, state) {
          final location = state.matchedLocation;
          final status = authController.status;
          final isSplash = location == AppRoutes.splash;
          final isWelcome = location == AppRoutes.welcome;
          final isStudentDashboard = location == AppRoutes.studentDashboard;
          final isAdminDashboard = location == AppRoutes.adminDashboard;
          final isEntryRoute =
              location == AppRoutes.login || location == AppRoutes.register;
          final isRecoveryRoute =
              location == AppRoutes.forgotPassword ||
              location == AppRoutes.resetPassword ||
              location == AppRoutes.confirmEmail;
          final isProtectedRoute =
              isWelcome || isStudentDashboard || isAdminDashboard;

          if (status == AuthStatus.initializing) {
            if (isEntryRoute || isRecoveryRoute) {
              return null;
            }

            return isSplash ? null : AppRoutes.splash;
          }

          if (status == AuthStatus.authenticated) {
            final isStudent =
                authController.currentUser?.hasRole('Student') ?? false;
            final authenticatedHome = isStudent
                ? AppRoutes.studentDashboard
                : AppRoutes.adminDashboard;

            if (isSplash || isEntryRoute) {
              return authenticatedHome;
            }

            if (isStudent && (isWelcome || isAdminDashboard)) {
              return AppRoutes.studentDashboard;
            }

            if (!isStudent && (isStudentDashboard || isWelcome)) {
              return AppRoutes.adminDashboard;
            }

            return null;
          }

          return isSplash || isProtectedRoute ? AppRoutes.login : null;
        },
      );

  final GoRouter router;

  void dispose() => router.dispose();
}

class _AuthSplashPage extends StatelessWidget {
  const _AuthSplashPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
