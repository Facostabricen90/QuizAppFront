import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:quizz_application/core/auth/auth_controller.dart';
import 'package:quizz_application/core/auth/auth_repository.dart';
import 'package:quizz_application/core/network/api_client.dart';
import 'package:quizz_application/core/security/token_storage.dart';
import 'package:quizz_application/features/authentication/presentation/widgets/reset_password_form.dart';
import 'package:quizz_application/shared/presentation/widgets/app_password_field.dart';

void main() {
  testWidgets(
    'mantiene editables las contraseñas y explica un error 500 sin detalle',
    (WidgetTester tester) async {
      final client = MockClient((_) async => http.Response('', 500));
      final tokenStorage = TokenStorage();
      final apiClient = ApiClient(
        tokenStorage: tokenStorage,
        baseUrl: 'https://localhost:7126',
        client: client,
      );
      addTearDown(apiClient.dispose);

      final authController = AuthController(
        AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ResetPasswordForm(
                authController: authController,
                email: 'ana@example.com',
                token: 'reset-token',
              ),
            ),
          ),
        ),
      );

      var fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), 'Password123');
      await tester.enterText(fields.at(2), 'Password123');
      await tester.tap(find.text('Cambiar contraseña'));
      await tester.pumpAndSettle();

      expect(find.textContaining('error interno (500)'), findsOneWidget);
      expect(find.textContaining('no envió un detalle'), findsOneWidget);

      fields = find.byType(TextFormField);
      final passwordFields = find.byType(AppPasswordField);
      final passwordField = tester.widget<AppPasswordField>(
        passwordFields.at(0),
      );
      final confirmationField = tester.widget<AppPasswordField>(
        passwordFields.at(1),
      );

      expect(passwordField.enabled, isTrue);
      expect(confirmationField.enabled, isTrue);
      expect(passwordField.focusNode?.hasFocus, isTrue);
      expect(passwordField.autofillHints, [AutofillHints.newPassword]);
      expect(confirmationField.autofillHints, isEmpty);

      await tester.enterText(fields.at(1), 'OtraPassword456');
      await tester.enterText(fields.at(2), 'OtraPassword456');
      await tester.pump();

      fields = find.byType(TextFormField);
      expect(
        tester.widget<TextFormField>(fields.at(1)).controller?.text,
        'OtraPassword456',
      );
      expect(
        tester.widget<TextFormField>(fields.at(2)).controller?.text,
        'OtraPassword456',
      );
      expect(find.byKey(const ValueKey('reset-password-error')), findsNothing);
    },
  );

  testWidgets('muestra el detalle enviado por la API al fallar', (
    WidgetTester tester,
  ) async {
    final client = MockClient(
      (_) async => http.Response(
        '{"errors":["El token de recuperación no es válido."]}',
        400,
        headers: {'content-type': 'application/json'},
      ),
    );
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: 'https://localhost:7126',
      client: client,
    );
    addTearDown(apiClient.dispose);

    final authController = AuthController(
      AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ResetPasswordForm(
              authController: authController,
              email: 'ana@example.com',
              token: 'reset-token',
            ),
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'Password123');
    await tester.enterText(fields.at(2), 'Password123');
    await tester.tap(find.text('Cambiar contraseña'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se cambió la contraseña.'), findsOneWidget);
    expect(
      find.textContaining('El token de recuperación no es válido.'),
      findsOneWidget,
    );
  });
}
