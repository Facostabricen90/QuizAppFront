import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

enum AuthStatus { initializing, unauthenticated, authenticating, authenticated }

/// Resultado de la operación de cambio de contraseña.
/// Se usa para distinguir errores de validación (contraseña actual incorrecta,
/// contraseña nueva igual a la actual) de errores genéricos de red.
class ChangePasswordResult {
  const ChangePasswordResult.success()
      : success = true;

  const ChangePasswordResult.failure()
      : success = false;

  final bool success;
}

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AuthStatus status = AuthStatus.initializing;
  AuthUser? currentUser;
  String? errorMessage;
  String? registrationConfirmationEmail;

  Future<void> restoreSession() async {
    try {
      currentUser = await _repository.restoreSession();
      status = currentUser == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
    } catch (error) {
      currentUser = null;
      status = AuthStatus.unauthenticated;
      errorMessage = _messageFor(error);
    }

    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    return _authenticate(() async {
      currentUser = await _repository.login(email: email, password: password);
    });
  }

    Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? invitationCode,
  }) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    registrationConfirmationEmail = null;
    notifyListeners();

    try {
      await _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        invitationCode: invitationCode,
      );

      currentUser = null;
      status = AuthStatus.unauthenticated;
      registrationConfirmationEmail = email;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      currentUser = null;
      status = AuthStatus.unauthenticated;
      errorMessage = _messageFor(error);
      if (kDebugMode) {
        debugPrint('Registration error: $error\n$stackTrace');
      }
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerStaff({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String role = 'Teacher',
  }) {
    return _runRecoveryOperation(
      () => _repository.registerStaff(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
      ),
    );
  }

  /// Cambia la contraseña del usuario autenticado.
  /// No cierra la sesión automáticamente: el backend revocó los refresh tokens
  /// en otros dispositivos, pero el access token actual sigue vivo hasta expirar.
  /// La pantalla decide qué mostrar tras el éxito.
  Future<ChangePasswordResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    errorMessage = null;

    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const ChangePasswordResult.success();
    } catch (error) {
      errorMessage = _messageFor(error);
      return const ChangePasswordResult.failure();
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      currentUser = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> requestPasswordReset({required String email}) {
    return _runRecoveryOperation(
      () => _repository.requestPasswordReset(email: email),
    );
  }

  Future<bool> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) {
    return _runRecoveryOperation(
      () => _repository.resetPassword(
        email: email,
        token: token,
        newPassword: newPassword,
      ),
      messageForError: _resetPasswordMessageFor,
    );
  }

  Future<bool> confirmEmail({required String email, required String token}) {
    return _runRecoveryOperation(
      () => _repository.confirmEmail(email: email, token: token),
    );
  }

  Future<bool> resendConfirmation({required String email}) {
    return _runRecoveryOperation(
      () => _repository.resendConfirmation(email: email),
    );
  }

  Future<void> clearLocalSession() async {
    await _repository.clearLocalSession();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> _authenticate(Future<void> Function() operation) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    registrationConfirmationEmail = null;
    notifyListeners();

    try {
      await operation();
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      status = AuthStatus.unauthenticated;
      currentUser = null;
      errorMessage = _messageFor(error);

      try {
        await _repository.clearLocalSession();
      } catch (_) {
        // No reemplazar el error original por un error de limpieza.
      }

      if (kDebugMode) {
        debugPrint('Auth error: $error\n$stackTrace');
      }

      notifyListeners();
      return false;
    }
  }

  Future<bool> _runRecoveryOperation(
    Future<void> Function() operation, {
    String Function(Object error)? messageForError,
  }) async {
    errorMessage = null;

    try {
      await operation();
      return true;
    } catch (error) {
      errorMessage = messageForError?.call(error) ?? _messageFor(error);
      return false;
    }
  }

  String _resetPasswordMessageFor(Object error) {
    if (error is ApiException) {
      if (error.hasResponseDetails) {
        return 'No se cambió la contraseña.\n${error.message}';
      }

      final statusCode = error.statusCode;
      if (statusCode != null && statusCode >= 500) {
        return 'No se cambió la contraseña. La API respondió con un error '
            'interno ($statusCode), pero no envió un detalle que permita '
            'identificar la causa. Puedes volver a intentarlo o solicitar un '
            'enlace nuevo.';
      }

      return 'No se cambió la contraseña. ${error.message}';
    }

    return _messageFor(error);
  }

  String _messageFor(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is FormatException) {
      return error.message;
    }

    return 'No se pudo completar la operación.';
  }
}