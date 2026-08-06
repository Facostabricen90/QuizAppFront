import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizz_application/app/app.dart';
import 'package:quizz_application/core/auth/auth_controller.dart';
import 'package:quizz_application/core/auth/auth_models.dart';
import 'package:quizz_application/core/auth/auth_repository.dart';
import 'package:quizz_application/core/network/api_client.dart';
import 'package:quizz_application/core/security/token_storage.dart';
import 'package:quizz_application/shared/presentation/widgets/app_gap.dart';

void main() {
  testWidgets('muestra la bienvenida con la sesión activa', (
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
          ..currentUser = const AuthUser(
            userId: 'test-user',
            email: 'usuario@example.com',
            roles: ['Student'],
          )
          ..status = AuthStatus.authenticated;

    await tester.pumpWidget(QuizApp(authController: authController));

    expect(find.text('¡Bienvenido a QuizApp!'), findsOneWidget);
    expect(find.text('usuario@example.com'), findsOneWidget);

    apiClient.dispose();
  });

  testWidgets('el registro exitoso limpia la ruta y muestra la bienvenida', (
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

    expect(find.text('¡Bienvenido a QuizApp!'), findsOneWidget);
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
    Navigator.of(
      tester.element(find.byType(Scaffold)),
    ).pushNamed('/reset-password?email=ana%40example.com&token=reset-token');
    await tester.pumpAndSettle();

    expect(find.text('Crea una nueva contraseña'), findsOneWidget);
    expect(find.text('ana@example.com'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);

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
      userId: 'registered-user',
      email: email,
      roles: const ['Student'],
    );
    status = AuthStatus.authenticated;
    notifyListeners();
    return true;
  }
}
