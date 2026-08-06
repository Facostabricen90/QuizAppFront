import 'dart:async';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/auth/auth_controller.dart';
import 'core/auth/auth_repository.dart';
import 'core/network/api_client.dart';
import 'core/security/token_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authRepository = AuthRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );
  final authController = AuthController(authRepository);

  runApp(QuizApp(authController: authController));
  unawaited(authController.restoreSession());
}
