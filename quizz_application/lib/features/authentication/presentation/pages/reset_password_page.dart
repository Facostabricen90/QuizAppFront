import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/auth_controller.dart';
import '../../../../shared/presentation/widgets/app_card.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../../../../shared/presentation/widgets/app_logo.dart';
import '../widgets/reset_password_form.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({
    super.key,
    required this.authController,
    required this.email,
    required this.token,
  });

  final AuthController authController;
  final String email;
  final String token;

  @override
  Widget build(BuildContext context) {
    final linkIsValid = email.isNotEmpty && token.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva contraseña')),
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
                    Text(
                      linkIsValid
                          ? 'Crea una nueva contraseña'
                          : 'Enlace de recuperación inválido',
                      textAlign: TextAlign.center,
                      style: AppTypography.displayMedium,
                    ),
                    AppGap.h12,
                    Text(
                      linkIsValid
                          ? 'La contraseña se cambiará para la cuenta indicada en el correo.'
                          : 'El enlace no contiene el correo o token necesario. Solicita uno nuevo desde el inicio de sesión.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    AppGap.h32,
                    if (linkIsValid)
                      ResetPasswordForm(
                        authController: authController,
                        email: email,
                        token: token,
                      )
                    else
                      TextButton(
                        onPressed: () => Navigator.of(
                          context,
                        ).popUntil((route) => route.isFirst),
                        child: const Text('Volver al inicio de sesión'),
                      ),
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
