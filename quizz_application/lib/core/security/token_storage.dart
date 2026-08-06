import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/auth_models.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? FlutterSecureStorage();

  static const _accessTokenKey = 'auth.accessToken';
  static const _refreshTokenKey = 'auth.refreshToken';
  static const _accessExpiresAtKey = 'auth.accessExpiresAtUtc';
  static const _refreshExpiresAtKey = 'auth.refreshExpiresAtUtc';
  static const _rolesKey = 'auth.roles';

  final FlutterSecureStorage _storage;

  Future<void> saveSession(AuthSession session) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: session.accessToken),
      _storage.write(key: _refreshTokenKey, value: session.refreshToken),
      _storage.write(
        key: _accessExpiresAtKey,
        value: session.accessTokenExpiresAtUtc.toIso8601String(),
      ),
      _storage.write(
        key: _refreshExpiresAtKey,
        value: session.refreshTokenExpiresAtUtc.toIso8601String(),
      ),
      _storage.write(key: _rolesKey, value: jsonEncode(session.roles)),
    ]);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _accessExpiresAtKey),
      _storage.delete(key: _refreshExpiresAtKey),
      _storage.delete(key: _rolesKey),
    ]);
  }
}
