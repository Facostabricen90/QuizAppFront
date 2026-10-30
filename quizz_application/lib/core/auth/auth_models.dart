/// Tokens de sesión. No contiene datos del usuario — esos viven en [AuthUser].
class AuthSession {
  const AuthSession({
    required this.tokenType,
    required this.accessToken,
    required this.accessTokenExpiresAtUtc,
    required this.refreshToken,
    required this.refreshTokenExpiresAtUtc,
  });

  final String tokenType;
  final String accessToken;
  final DateTime accessTokenExpiresAtUtc;
  final String refreshToken;
  final DateTime refreshTokenExpiresAtUtc;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken'];
    final refreshToken = json['refreshToken'];
    final expiresAt = json['expiresAtUtc'];
    final refreshExpiresAt = json['refreshTokenExpiresAtUtc'];

    if (accessToken is! String ||
        refreshToken is! String ||
        expiresAt is! String ||
        refreshExpiresAt is! String) {
      throw const FormatException('La respuesta de autenticación es inválida.');
    }

    return AuthSession(
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      accessToken: accessToken,
      accessTokenExpiresAtUtc: DateTime.parse(expiresAt).toUtc(),
      refreshToken: refreshToken,
      refreshTokenExpiresAtUtc: DateTime.parse(refreshExpiresAt).toUtc(),
    );
  }
}

/// Datos públicos del usuario autenticado.
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.roles,
    required this.type,
    this.schoolId,
  });

  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final List<String> roles;

  /// "Particular" o "Institutional".
  /// Determina si el usuario accede por pago individual o por institución.
  final String type;

  final String? schoolId;

  String get fullName => '$firstName $lastName'.trim();

  bool get isParticular => type == 'Particular';
  bool get isInstitutional => type == 'Institutional';

  bool hasRole(String role) {
    final normalized = role.toLowerCase();
    return roles.any((r) => r.toLowerCase() == normalized);
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((r) => r.toString())
          .toList(growable: false),
      type: json['type']?.toString() ?? 'Particular',
      schoolId: json['schoolId']?.toString(),
    );
  }
}

/// Response of every endpoint that issues a session (login, google-login, 2fa/verify-login, refresh-token).
/// Always includes [session] and [user].
class AuthResponse {
  const AuthResponse({required this.session, required this.user});

  final AuthSession session;
  final AuthUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map) {
      throw const FormatException('La respuesta de autenticación es inválida.');
    }

    return AuthResponse(
      session: AuthSession.fromJson(json),
      user: AuthUser.fromJson(Map<String, dynamic>.from(userJson)),
    );
  }
}

/// Respuesta de endpoints que no emiten sesión y solo reportan un estado pendiente
/// (ej: registro que requiere confirmar correo).
class RegistrationPendingResponse {
  const RegistrationPendingResponse({required this.message});

  final String message;

  factory RegistrationPendingResponse.fromJson(Map<String, dynamic> json) {
    return RegistrationPendingResponse(
      message: json['message']?.toString() ?? '',
    );
  }
}