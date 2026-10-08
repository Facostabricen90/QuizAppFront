import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:quizz_application/app/app.dart';
import 'package:quizz_application/app/router/app_routes.dart';
import 'package:quizz_application/app/theme/app_layout.dart';
import 'package:quizz_application/core/auth/auth_controller.dart';
import 'package:quizz_application/core/auth/auth_models.dart';
import 'package:quizz_application/core/auth/auth_repository.dart';
import 'package:quizz_application/core/network/api_client.dart';
import 'package:quizz_application/core/security/token_storage.dart';
import 'package:quizz_application/shared/presentation/widgets/app_gap.dart';

void main() {
  testWidgets('muestra el panel administrativo para un profesor autenticado', (
    WidgetTester tester,
  ) async {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: 'https://localhost:7126',
    );
    final authController =
        AuthController(
            AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
          )
          ..currentUser = _testUser(
            id: 'test-user',
            email: 'usuario@example.com',
            roles: const ['Teacher'],
          )
          ..status = AuthStatus.authenticated;

    await tester.pumpWidget(QuizApp(authController: authController));

    expect(find.text('Resumen docente'), findsOneWidget);
    expect(find.text('Estudiantes activos'), findsOneWidget);
    expect(find.text('Preguntas recientes'), findsOneWidget);
    expect(find.text('usuario@example.com'), findsOneWidget);

    apiClient.dispose();
  });

  testWidgets('el registro exitoso muestra el panel del estudiante', (
    WidgetTester tester,
  ) async {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: 'https://localhost:7126',
    );
    final authController = _SuccessfulAuthController(
      AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
    )..status = AuthStatus.unauthenticated;

    await tester.pumpWidget(QuizApp(authController: authController));
    final openRegister = find.text('Crear cuenta');
    await tester.ensureVisible(openRegister);
    await tester.tap(openRegister);
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ana');
    await tester.enterText(fields.at(1), 'Pérez');
    await tester.enterText(fields.at(2), 'ana@example.com');
    await tester.enterText(fields.at(3), 'Password123');
    await tester.enterText(fields.at(4), 'Password123');
    final termsCheckbox = find.byType(CheckboxListTile);
    await tester.ensureVisible(termsCheckbox);
    await tester.tap(termsCheckbox);

    final submitRegister = find.text('Crear cuenta');
    await tester.ensureVisible(submitRegister);
    await tester.tap(submitRegister);
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso de hoy'), findsOneWidget);
    expect(find.text('Explora por materias'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);

    apiClient.dispose();
  });

  testWidgets('AppGap puede consultarse repetidamente sin estado estático', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(children: [AppGap.w8, AppGap.w8]),
      ),
    );

    expect(find.byType(SizedBox), findsNWidgets(2));
  });

  testWidgets('abre la recuperación de contraseña desde el login', (
    WidgetTester tester,
  ) async {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: 'https://localhost:7126',
    );
    final authController = AuthController(
      AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
    )..status = AuthStatus.unauthenticated;

    await tester.pumpWidget(QuizApp(authController: authController));
    final forgotPassword = find.text('¿Olvidaste tu contraseña?');
    await tester.ensureVisible(forgotPassword);
    await tester.tap(forgotPassword);
    await tester.pumpAndSettle();

    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
    expect(find.text('Enviar instrucciones'), findsOneWidget);

    apiClient.dispose();
  });

  testWidgets('la ruta de recuperación recibe email y token', (
    WidgetTester tester,
  ) async {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: 'https://localhost:7126',
    );
    final authController = AuthController(
      AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
    )..status = AuthStatus.unauthenticated;

    await tester.pumpWidget(QuizApp(authController: authController));
    GoRouter.of(tester.element(find.byType(Scaffold))).go(
      Uri(
        path: AppRoutes.resetPassword,
        queryParameters: const {
          'email': 'ana@example.com',
          'token': 'reset-token',
        },
      ).toString(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crea una nueva contraseña'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);

    apiClient.dispose();
  });

  testWidgets('impide abrir welcome sin una sesión autenticada', (
    WidgetTester tester,
  ) async {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: 'https://localhost:7126',
    );
    final authController = AuthController(
      AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
    )..status = AuthStatus.unauthenticated;

    await tester.pumpWidget(QuizApp(authController: authController));
    GoRouter.of(tester.element(find.byType(Scaffold))).go(AppRoutes.welcome);
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('¡Bienvenido a QuizApp!'), findsNothing);

    apiClient.dispose();
  });

  testWidgets('impide volver al login con una sesión autenticada', (
    WidgetTester tester,
  ) async {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: 'https://localhost:7126',
    );
    final authController =
        AuthController(
            AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
          )
          ..currentUser = _testUser(
            id: 'test-user',
            email: 'usuario@example.com',
            roles: const ['Student'],
          )
          ..status = AuthStatus.authenticated;

    await tester.pumpWidget(QuizApp(authController: authController));
    GoRouter.of(tester.element(find.byType(Scaffold))).go(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso de hoy'), findsOneWidget);
    expect(find.text('usuario@example.com'), findsOneWidget);

    apiClient.dispose();
  });

  testWidgets('impide a un administrador abrir el panel estudiantil', (
    WidgetTester tester,
  ) async {
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: 'https://localhost:7126',
    );
    final authController =
        AuthController(
            AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
          )
          ..currentUser = _testUser(
            id: 'admin-user',
            email: 'admin@example.com',
            roles: const ['Admin'],
          )
          ..status = AuthStatus.authenticated;

    await tester.pumpWidget(QuizApp(authController: authController));
    GoRouter.of(
      tester.element(find.byType(Scaffold)),
    ).go(AppRoutes.studentDashboard);
    await tester.pumpAndSettle();

    expect(find.text('Resumen administrativo'), findsOneWidget);
    expect(find.text('Tu progreso de hoy'), findsNothing);

    apiClient.dispose();
  });

  testWidgets('el panel estudiantil no desborda en una pantalla móvil', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: 'https://localhost:7126',
    );
    final authController =
        AuthController(
            AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
          )
          ..currentUser = _testUser(
            id: 'student-user',
            email: 'estudiante@example.com',
            roles: const ['Student'],
          )
          ..status = AuthStatus.authenticated;

    await tester.pumpWidget(QuizApp(authController: authController));
    await tester.pumpAndSettle();

    expect(find.text('Tu progreso de hoy'), findsOneWidget);
    expect(find.text('Pon a prueba tus conocimientos'), findsOneWidget);
    expect(find.text('Ciencias naturales'), findsOneWidget);
    expect(find.text('Inglés'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
    expect(
      tester.getSize(find.byType(NavigationBar)).height,
      lessThan(AppLayout.maxBottomNavigationHeight),
    );
    expect(
      tester.getTopLeft(find.text('Tu progreso de hoy')).dy,
      lessThan(tester.getTopLeft(find.byType(NavigationBar)).dy),
    );
    expect(tester.takeException(), isNull);

    apiClient.dispose();
  });

  testWidgets('el panel usa navegación lateral en una pantalla web', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: 'https://localhost:7126',
    );
    final authController =
        AuthController(
            AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
          )
          ..currentUser = _testUser(
            id: 'web-student',
            email: 'estudiante@example.com',
            roles: const ['Student'],
          )
          ..status = AuthStatus.authenticated;

    await tester.pumpWidget(QuizApp(authController: authController));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Explora por materias'), findsOneWidget);
    expect(tester.takeException(), isNull);

    apiClient.dispose();
  });
}

class _SuccessfulAuthController extends AuthController {
  _SuccessfulAuthController(super.repository);

  @override
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    currentUser = AuthUser(
      id: 'registered-user',
      email: email,
      firstName: firstName,
      lastName: lastName,
      roles: const ['Student'],
    );
    status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }
}

/// Helper para construir [AuthUser] en tests sin repetir campos obligatorios.
AuthUser _testUser({
  required String id,
  required String email,
  required List<String> roles,
  String firstName = 'Test',
  String lastName = 'User',
  String? schoolId,
}) {
  return AuthUser(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    roles: roles,
    schoolId: schoolId,
  );
}