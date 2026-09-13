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
    // Algunos backends de almacenamiento seguro (especialmente en Web)
    // no se inicializan de forma segura cuando reciben varias escrituras
    // simultáneas. Guardar la sesión en orden evita que el primer login
    // falle antes de que AuthRepository pueda llamar a /api/auth/me.
    try {
      await _storage.write(key: _accessTokenKey, value: session.accessToken);
      await _storage.write(key: _refreshTokenKey, value: session.refreshToken);
      await _storage.write(
        key: _accessExpiresAtKey,
        value: session.accessTokenExpiresAtUtc.toIso8601String(),
      );
      await _storage.write(
        key: _refreshExpiresAtKey,
        value: session.refreshTokenExpiresAtUtc.toIso8601String(),
      );
      await _storage.write(key: _rolesKey, value: jsonEncode(session.roles));
    } catch (_) {
      // Evita dejar una sesión incompleta si una de las escrituras falla.
      await _clearBestEffort();
      rethrow;
    }
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshTokenKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _accessExpiresAtKey);
    await _storage.delete(key: _refreshExpiresAtKey);
    await _storage.delete(key: _rolesKey);
  }

  Future<void> _clearBestEffort() async {
    for (final key in [
      _accessTokenKey,
      _refreshTokenKey,
      _accessExpiresAtKey,
      _refreshExpiresAtKey,
      _rolesKey,
    ]) {
      try {
        await _storage.delete(key: key);
      } catch (_) {
        // Conserva la excepción original de saveSession().
      }
    }
  }
}
