import 'package:flutter/foundation.dart';

import '../network/api_exception.dart';
import 'auth_models.dart';
import 'auth_repository.dart';

enum AuthStatus { initializing, unauthenticated, authenticating, authenticated }

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
      await _repository.login(email: email, password: password);
    });
  }

  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    status = AuthStatus.authenticating;
    errorMessage = null;
    registrationConfirmationEmail = null;
    notifyListeners();

    try {
      final result = await _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );

      if (result.requiresEmailConfirmation) {
        currentUser = null;
        status = AuthStatus.unauthenticated;
        registrationConfirmationEmail = email;
        notifyListeners();
        return true;
      }

      currentUser = await _repository.currentUser();
      status = AuthStatus.authenticated;
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
      currentUser = await _repository.currentUser();
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (error, stackTrace) {
      status = AuthStatus.unauthenticated;
      errorMessage = _messageFor(error);

      // Si el login recibió tokens pero falló al validar /me, elimina
      // cualquier sesión parcial para que el siguiente intento empiece limpio.
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
