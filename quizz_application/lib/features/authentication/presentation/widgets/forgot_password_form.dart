import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/auth_controller.dart';
import '../../../../shared/presentation/widgets/app_button.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../../../../shared/presentation/widgets/app_text_field.dart';

class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await widget.authController.requestPasswordReset(
      email: _emailController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _emailSent = success;
      _errorMessage = success
          ? null
          : widget.authController.errorMessage ??
                'No se pudo enviar la solicitud.';
    });
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Ingresa tu correo electrónico.';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Ingresa un correo electrónico válido.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_emailSent) {
      return Column(
        children: [
          const Icon(
            Icons.mark_email_read_outlined,
            size: 56,
            color: AppColors.success,
          ),
          AppGap.h16,
          const Text('Revisa tu correo', style: AppTypography.headline),
          AppGap.h8,
          const Text(
            'Si el correo pertenece a una cuenta, recibirás las instrucciones para restablecer la contraseña.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          AppGap.h24,
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver al inicio de sesión'),
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            label: 'Correo electrónico',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            validator: _validateEmail,
          ),
          if (_errorMessage != null) ...[
            AppGap.h12,
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          AppGap.h24,
          AppButton(
            text: 'Enviar instrucciones',
            icon: Icons.send_outlined,
            isLoading: _isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
