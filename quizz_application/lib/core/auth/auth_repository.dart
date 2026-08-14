import 'dart:convert';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../security/token_storage.dart';
import 'auth_models.dart';

class AuthRepository {
  const AuthRepository({required this._apiClient, required this._tokenStorage});

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );

    return _saveSessionFromResponse(response);
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/register',
      body: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      },
    );

    return _saveSessionFromResponse(response);
  }

  Future<AuthUser> currentUser() async {
    final response = await _apiClient.get('/api/auth/me', authenticated: true);
    _ensureSuccess(response.statusCode, response);
    return AuthUser.fromJson(_decodeObject(response.body));
  }

  Future<void> requestPasswordReset({required String email}) async {
    final response = await _apiClient.post(
      '/api/auth/forgot-password',
      body: {'email': email},
    );
    _ensureSuccess(response.statusCode, response);
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/reset-password',
      body: {'email': email, 'token': token, 'newPassword': newPassword},
    );
    _ensureSuccess(response.statusCode, response);
  }

  Future<AuthUser?> restoreSession() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final refreshed = await _apiClient.tryRefreshSession();
    if (!refreshed) {
      return null;
    }

    try {
      return await currentUser();
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _tokenStorage.clear();
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.post(
          '/api/auth/revoke',
          body: {'refreshToken': refreshToken},
          authenticated: true,
        );
      }
    } finally {
      await _tokenStorage.clear();
    }
  }

  Future<void> clearLocalSession() {
    return _tokenStorage.clear();
  }

  Future<AuthSession> _saveSessionFromResponse(dynamic response) async {
    _ensureSuccess(response.statusCode, response);
    final session = AuthSession.fromJson(_decodeObject(response.body));
    await _tokenStorage.saveSession(session);
    return session;
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('La respuesta de la API es inválida.');
    }

    return Map<String, dynamic>.from(decoded);
  }

  void _ensureSuccess(int statusCode, dynamic response) {
    if (statusCode < 200 || statusCode >= 300) {
      throw ApiException.fromResponse(response);
    }
  }
}
