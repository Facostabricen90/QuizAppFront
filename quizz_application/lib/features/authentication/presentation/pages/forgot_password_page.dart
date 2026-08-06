import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/auth_controller.dart';
import '../../../../shared/presentation/widgets/app_card.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../../../../shared/presentation/widgets/app_logo.dart';
import '../widgets/forgot_password_form.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(size: 64, showText: false),
                    AppGap.h24,
                    const Text(
                      '¿Olvidaste tu contraseña?',
                      textAlign: TextAlign.center,
                      style: AppTypography.displayMedium,
                    ),
                    AppGap.h12,
                    const Text(
                      'Escribe el correo de tu cuenta y te enviaremos un enlace seguro para crear una nueva contraseña.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    AppGap.h32,
                    ForgotPasswordForm(authController: authController),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
