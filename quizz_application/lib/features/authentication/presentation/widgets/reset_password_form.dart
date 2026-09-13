import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/auth_controller.dart';
import '../../../../shared/presentation/widgets/app_button.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../../../../shared/presentation/widgets/app_password_field.dart';
import '../../../../shared/presentation/widgets/app_text_field.dart';

class ResetPasswordForm extends StatefulWidget {
  const ResetPasswordForm({
    super.key,
    required this.authController,
    required this.email,
    required this.token,
  });

  final AuthController authController;
  final String email;
  final String token;

  @override
  State<ResetPasswordForm> createState() => _ResetPasswordFormState();
}

class _ResetPasswordFormState extends State<ResetPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _passwordChanged = false;
  int _fieldGeneration = 0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
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

    var success = false;
    String? failureMessage;

    try {
      success = await widget.authController.resetPassword(
        email: widget.email,
        token: widget.token,
        newPassword: _passwordController.text,
      );

      if (success) {
        try {
          await widget.authController.clearLocalSession();
        } catch (_) {
          // La contraseña ya fue cambiada en el servidor. Un fallo al limpiar
          // el almacenamiento local no debe dejar bloqueado el formulario.
        }
      } else {
        failureMessage =
            widget.authController.errorMessage ??
            'No se pudo actualizar la contraseña y la API no indicó la causa.';
      }
    } catch (_) {
      failureMessage =
          'No se cambió la contraseña por un error inesperado. Los campos '
          'siguen disponibles para corregirlos e intentarlo nuevamente.';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _passwordChanged = success;
      _errorMessage = success ? null : failureMessage;
      if (!success) {
        // Fuerza la recreación de los elementos HTML que algunos gestores de
        // contraseñas dejan asociados entre sí después de una respuesta fallida.
        _fieldGeneration++;
      }
    });

    if (!success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        _passwordFocusNode.requestFocus();
        _passwordController.selection = TextSelection.collapsed(
          offset: _passwordController.text.length,
        );
      });
    }
  }

  void _clearErrorOnEdit(String _) {
    if (_errorMessage == null) {
      return;
    }

    setState(() {
      _errorMessage = null;
    });
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una nueva contraseña.';
    }

    if (value.length < 8) {
      return 'Utiliza al menos 8 caracteres.';
    }

    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma la nueva contraseña.';
    }

    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_passwordChanged) {
      return Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 56,
            color: AppColors.success,
          ),
          AppGap.h16,
          const Text(
            'Contraseña actualizada',
            textAlign: TextAlign.center,
            style: AppTypography.headline,
          ),
          AppGap.h8,
          const Text(
            'Ya puedes iniciar sesión utilizando tu nueva contraseña.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          AppGap.h24,
          AppButton(
            text: 'Ir al inicio de sesión',
            expand: false,
            onPressed: () => context.goNamed(AppRoutes.loginName),
          ),
        ],
      );
    }

    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Cuenta a recuperar',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              readOnly: true,
            ),
            AppGap.h16,
            AppPasswordField(
              key: ValueKey('new-password-$_fieldGeneration'),
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              enabled: !_isLoading,
              label: 'Nueva contraseña',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: _validatePassword,
              onChanged: _clearErrorOnEdit,
            ),
            AppGap.h16,
            AppPasswordField(
              key: ValueKey('confirm-password-$_fieldGeneration'),
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              enabled: !_isLoading,
              label: 'Confirmar nueva contraseña',
              textInputAction: TextInputAction.done,
              // Un segundo newPassword hace que algunos navegadores vinculen
              // ambos inputs y no permitan editarlos por separado tras fallar.
              autofillHints: const <String>[],
              validator: _validateConfirmation,
              onChanged: _clearErrorOnEdit,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_errorMessage != null) ...[
              AppGap.h12,
              Text(
                _errorMessage!,
                key: const ValueKey('reset-password-error'),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ],
            AppGap.h24,
            AppButton(
              text: 'Cambiar contraseña',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
