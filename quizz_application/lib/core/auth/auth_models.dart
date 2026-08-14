class AuthSession {
  const AuthSession({
    required this.tokenType,
    required this.accessToken,
    required this.accessTokenExpiresAtUtc,
    required this.refreshToken,
    required this.refreshTokenExpiresAtUtc,
    required this.roles,
  });

  final String tokenType;
  final String accessToken;
  final DateTime accessTokenExpiresAtUtc;
  final String refreshToken;
  final DateTime refreshTokenExpiresAtUtc;
  final List<String> roles;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final accessExpiresAt = json['expiresAtUtc'];
    final refreshExpiresAt = json['refreshTokenExpiresAtUtc'];

    if (accessToken is! String ||
        refreshToken is! String ||
        accessExpiresAt is! String ||
        refreshExpiresAt is! String) {
      throw const FormatException('La respuesta de autenticación es inválida.');
    }

    final roles = (json['roles'] as List<dynamic>? ?? const [])
        .map((role) => role.toString())
        .toList(growable: false);

    return AuthSession(
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      accessToken: accessToken,
      accessTokenExpiresAtUtc: DateTime.parse(accessExpiresAt).toUtc(),
      refreshToken: refreshToken,
      refreshTokenExpiresAtUtc: DateTime.parse(refreshExpiresAt).toUtc(),
      roles: roles,
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.userId,
    required this.email,
    required this.roles,
  });

  final String userId;
  final String email;
  final List<String> roles;

  bool hasRole(String role) {
    final normalizedRole = role.toLowerCase();
    return roles.any(
      (currentRole) => currentRole.toLowerCase() == normalizedRole,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((role) => role.toString())
          .toList(growable: false),
    );
  }
}
