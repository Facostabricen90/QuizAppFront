import 'dart:convert';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../security/token_storage.dart';
import 'auth_models.dart';

class AuthRepository {
  const AuthRepository({required this._apiClient, required this._tokenStorage});

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      body: {'email': email, 'password': password},
    );
    return _persistAndReturnUser(response);
  }

  Future<RegistrationPendingResponse> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? invitationCode,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/register-student',
      body: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (invitationCode != null && invitationCode.trim().isNotEmpty)
          'invitationCode': invitationCode.trim(),
      },
    );
    _ensureSuccess(response.statusCode, response);
    return RegistrationPendingResponse.fromJson(_decodeObject(response.body));
  }

  Future<void> registerStaff({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'Teacher',
  }) async {
    final response = await _apiClient.post(
      '/api/auth/register-staff',
      authenticated: true,
      body: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
      },
    );
    _ensureSuccess(response.statusCode, response);
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

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/change-password',
      authenticated: true,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    _ensureSuccess(response.statusCode, response);
  }

  Future<void> confirmEmail({
    required String email,
    required String token,
  }) async {
    final response = await _apiClient.post(
      '/api/auth/confirm-email',
      body: {'email': email, 'token': token},
    );
    _ensureSuccess(response.statusCode, response);
  }

  Future<void> resendConfirmation({required String email}) async {
    final response = await _apiClient.post(
      '/api/auth/resend-confirmation-email',
      body: {'email': email},
    );
    _ensureSuccess(response.statusCode, response);
  }

  /// Restores the session when the app starts. A single request: the refresh-token
  /// response already includes the up-to-date user.
  Future<AuthUser?> restoreSession() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    return _apiClient.tryRefreshSession();
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _apiClient.post(
          '/api/auth/logout',
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

  Future<AuthUser> _persistAndReturnUser(dynamic response) async {
    _ensureSuccess(response.statusCode, response);
    final body = _decodeObject(response.body);
    final authResponse = AuthResponse.fromJson(body);

    await _tokenStorage.saveSession(authResponse.session);
    return authResponse.user;
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