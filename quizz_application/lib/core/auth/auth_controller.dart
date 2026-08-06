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
    return _authenticate(() async {
      await _repository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      );
    });
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
    notifyListeners();

    try {
      await operation();
      currentUser = await _repository.currentUser();
      status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } catch (error) {
      status = AuthStatus.unauthenticated;
      errorMessage = _messageFor(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> _runRecoveryOperation(Future<void> Function() operation) async {
    errorMessage = null;

    try {
      await operation();
      return true;
    } catch (error) {
      errorMessage = _messageFor(error);
      return false;
    }
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
