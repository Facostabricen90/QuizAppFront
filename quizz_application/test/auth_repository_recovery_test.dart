import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:quizz_application/core/auth/auth_repository.dart';
import 'package:quizz_application/core/network/api_client.dart';
import 'package:quizz_application/core/security/token_storage.dart';

void main() {
  test('solicita el correo de recuperación al endpoint correcto', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({'message': 'Solicitud recibida.'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: 'https://localhost:7126',
      client: client,
    );
    final repository = AuthRepository(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );

    await repository.requestPasswordReset(email: 'ana@example.com');

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/auth/forgot-password');
    expect(jsonDecode(capturedRequest.body), {'email': 'ana@example.com'});

    apiClient.dispose();
  });

  test('envía correo, token y contraseña al restablecer', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({'message': 'Contraseña actualizada correctamente.'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: 'https://localhost:7126',
      client: client,
    );
    final repository = AuthRepository(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );

    await repository.resetPassword(
      email: 'ana@example.com',
      token: 'reset-token',
      newPassword: 'NuevaPassword123',
    );

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/auth/reset-password');
    expect(jsonDecode(capturedRequest.body), {
      'email': 'ana@example.com',
      'token': 'reset-token',
      'newPassword': 'NuevaPassword123',
    });

    apiClient.dispose();
  });

  test('confirma el correo usando los datos del enlace', () async {
    late http.Request capturedRequest;
    final client = MockClient((request) async {
      capturedRequest = request;
      return http.Response(
        jsonEncode({'message': 'Correo confirmado correctamente.'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final tokenStorage = TokenStorage();
    final apiClient = ApiClient(
      tokenStorage: tokenStorage,
      baseUrl: 'https://localhost:7126',
      client: client,
    );
    final repository = AuthRepository(
      apiClient: apiClient,
      tokenStorage: tokenStorage,
    );

    await repository.confirmEmail(
      email: 'ana@example.com',
      token: 'confirmation-token',
    );

    expect(capturedRequest.url.path, '/api/auth/confirm-email');
    expect(jsonDecode(capturedRequest.body), {
      'email': 'ana@example.com',
      'token': 'confirmation-token',
    });
    apiClient.dispose();
  });
}
