import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_models.dart';
import '../config/app_config.dart';
import '../security/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({required this._tokenStorage, String? baseUrl, http.Client? client})
    : _client = client ?? http.Client(),
      baseUrl = (baseUrl ?? AppConfig.apiBaseUrl).replaceFirst(
        RegExp(r'/$'),
        '',
      );

  final TokenStorage _tokenStorage;
  final http.Client _client;
  final String baseUrl;

  /// Refresh request in progress, shared so parallel 401s trigger a single refresh.
  Future<AuthUser?>? _refreshInFlight;

  Future<http.Response> get(String path, {bool authenticated = false}) {
    return _request(method: 'GET', path: path, authenticated: authenticated);
  }

  Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _request(
      method: 'POST',
      path: path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _request(
      method: 'PUT',
      path: path,
      body: body,
      authenticated: authenticated,
    );
  }

  Future<http.Response> delete(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _request(
      method: 'DELETE',
      path: path,
      body: body,
      authenticated: authenticated,
    );
  }

  /// Renews the session with the stored refresh token.
  /// Returns the up-to-date user (the refresh response includes it), or null if the session could not be renewed.
  Future<AuthUser?> tryRefreshSession() => _refreshTokens();

  Future<http.Response> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    var response = await _send(
      method: method,
      path: path,
      body: body,
      authenticated: authenticated,
    );

    if (response.statusCode == 401 && authenticated) {
      final refreshedUser = await _refreshTokens();
      if (refreshedUser != null) {
        response = await _send(
          method: method,
          path: path,
          body: body,
          authenticated: true,
        );
      }
    }

    return response;
  }

  Future<http.Response> _send({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    required bool authenticated,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final accessToken = await _tokenStorage.readAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers.addAll(headers)
      ..body = body == null ? '' : jsonEncode(body);

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      return await http.Response.fromStream(streamedResponse);
    } on TimeoutException {
      throw const ApiException(
        message: 'El servidor tardó demasiado en responder.',
      );
    } on http.ClientException {
      throw const ApiException(message: 'No se pudo conectar con el servidor.');
    }
  }

  Future<AuthUser?> _refreshTokens() {
    final currentRefresh = _refreshInFlight;
    if (currentRefresh != null) {
      return currentRefresh;
    }

    final refreshOperation = _performRefresh();
    _refreshInFlight = refreshOperation;
    refreshOperation.whenComplete(() {
      if (identical(_refreshInFlight, refreshOperation)) {
        _refreshInFlight = null;
      }
    });

    return refreshOperation;
  }

  Future<AuthUser?> _performRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final response = await _send(
      method: 'POST',
      path: '/api/auth/refresh-token',
      body: {'refreshToken': refreshToken},
      authenticated: false,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 400 || response.statusCode == 401) {
        await _tokenStorage.clear();
      }
      return null;
    }

    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final authResponse = AuthResponse.fromJson(json);
      await _tokenStorage.saveSession(authResponse.session);
      return authResponse.user;
    } on FormatException {
      await _tokenStorage.clear();
      return null;
    }
  }

  void dispose() {
    _client.close();
  }
}
