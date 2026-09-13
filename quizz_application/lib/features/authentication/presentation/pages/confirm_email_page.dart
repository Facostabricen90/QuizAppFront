import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/auth_controller.dart';
import '../../../../shared/presentation/widgets/app_button.dart';
import '../../../../shared/presentation/widgets/app_card.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../../../../shared/presentation/widgets/app_logo.dart';

class ConfirmEmailPage extends StatefulWidget {
  const ConfirmEmailPage({
    super.key,
    required this.authController,
    required this.email,
    required this.token,
  });

  final AuthController authController;
  final String email;
  final String token;

  @override
  State<ConfirmEmailPage> createState() => _ConfirmEmailPageState();
}

class _ConfirmEmailPageState extends State<ConfirmEmailPage> {
  bool _isLoading = true;
  bool _confirmed = false;
  bool _resending = false;
  String? _errorMessage;

  bool get _linkIsValid => widget.email.isNotEmpty && widget.token.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_linkIsValid) {
      _confirm();
    } else {
      _isLoading = false;
      _errorMessage = 'El enlace no contiene el correo o token necesario.';
    }
  }

  Future<void> _confirm() async {
    final success = await widget.authController.confirmEmail(
      email: widget.email,
      token: widget.token,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _confirmed = success;
      _errorMessage = success
          ? null
          : widget.authController.errorMessage ??
                'No se pudo confirmar el correo.';
    });
  }

  Future<void> _resend() async {
    if (widget.email.isEmpty) {
      return;
    }
    setState(() {
      _resending = true;
      _errorMessage = null;
    });
    final success = await widget.authController.resendConfirmation(
      email: widget.email,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _resending = false;
      _errorMessage = success
          ? 'Enviamos un enlace nuevo. Revisa tu correo.'
          : widget.authController.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AppLogo(size: 64, showText: false),
                    AppGap.h24,
                    if (_isLoading) ...[
                      const CircularProgressIndicator(),
                      AppGap.h24,
                      const Text(
                        'Confirmando tu correo…',
                        style: AppTypography.headline,
                      ),
                    ] else if (_confirmed) ...[
                      const Icon(
                        Icons.verified_outlined,
                        size: 58,
                        color: AppColors.success,
                      ),
                      AppGap.h16,
                      const Text(
                        'Correo confirmado',
                        textAlign: TextAlign.center,
                        style: AppTypography.displayMedium,
                      ),
                      AppGap.h12,
                      const Text(
                        'Tu cuenta ya está activa. Ahora puedes iniciar sesión.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium,
                      ),
                      AppGap.h24,
                      AppButton(
                        text: 'Iniciar sesión',
                        onPressed: () => context.goNamed(AppRoutes.loginName),
                      ),
                    ] else ...[
                      const Icon(
                        Icons.link_off_rounded,
                        size: 58,
                        color: AppColors.error,
                      ),
                      AppGap.h16,
                      const Text(
                        'No pudimos confirmar el correo',
                        textAlign: TextAlign.center,
                        style: AppTypography.headline,
                      ),
                      AppGap.h12,
                      Text(
                        _errorMessage ?? 'El enlace es inválido o expiró.',
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyMedium,
                      ),
                      AppGap.h24,
                      if (widget.email.isNotEmpty)
                        AppButton(
                          text: 'Enviar un enlace nuevo',
                          isLoading: _resending,
                          onPressed: _resend,
                        ),
                      AppGap.h12,
                      TextButton(
                        onPressed: () => context.goNamed(AppRoutes.loginName),
                        child: const Text('Volver al inicio de sesión'),
                      ),
                    ],
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
