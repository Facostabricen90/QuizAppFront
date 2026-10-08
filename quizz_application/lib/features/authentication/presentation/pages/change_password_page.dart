import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/auth_controller.dart';
import '../../../../shared/presentation/widgets/app_button.dart';
import '../../../../shared/presentation/widgets/app_card.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../../../../shared/presentation/widgets/app_logo.dart';
import '../../../../shared/presentation/widgets/app_password_field.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;
  bool _passwordChanged = false;
  int _fieldGeneration = 0;
  String? _errorMessage;
  String? _currentPasswordError;
  String? _newPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
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
      _currentPasswordError = null;
      _newPasswordError = null;
    });

    final result = await widget.authController.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _passwordChanged = result.success;
      if (!result.success) {
        // Enrutamos el mensaje al campo específico cuando podemos.
        final message = widget.authController.errorMessage ??
            'No se pudo cambiar la contraseña.';
        if (message.toLowerCase().contains('actual')) {
          _currentPasswordError = message;
        } else if (message.toLowerCase().contains('diferente')) {
          _newPasswordError = message;
        } else {
          _errorMessage = message;
        }
        // Fuerza recreación de inputs para evitar autofill pegajoso en web.
        _fieldGeneration++;
      }
    });

    if (!result.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _currentPasswordFocusSafe();
      });
    }
  }

  void _currentPasswordFocusSafe() {
    if (_currentPasswordError != null) {
      _newPasswordFocusNode.requestFocus();
    } else if (_newPasswordError != null) {
      _confirmPasswordFocusNode.requestFocus();
    }
  }

  void _clearErrorsOnEdit(String _) {
    if (_errorMessage == null &&
        _currentPasswordError == null &&
        _newPasswordError == null) {
      return;
    }
    setState(() {
      _errorMessage = null;
      _currentPasswordError = null;
      _newPasswordError = null;
    });
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña actual.';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa la nueva contraseña.';
    }
    if (value.length < 8) {
      return 'Utiliza al menos 8 caracteres.';
    }
    if (value == _currentPasswordController.text) {
      return 'La nueva contraseña debe ser diferente a la actual.';
    }
    return null;
  }

  String? _validateConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma la nueva contraseña.';
    }
    if (value != _newPasswordController.text) {
      return 'Las contraseñas no coinciden.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambiar contraseña')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: AppCard(
                child: _passwordChanged
                    ? _buildSuccessState()
                    : _buildFormState(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 58,
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
          'Por seguridad, cerramos las demás sesiones activas. Deberás iniciar sesión de nuevo en otros dispositivos.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium,
        ),
        AppGap.h24,
        AppButton(
          text: 'Volver al inicio',
          expand: false,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }

  Widget _buildFormState() {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 64, showText: false),
            AppGap.h24,
            const Text(
              'Cambiar contraseña',
              textAlign: TextAlign.center,
              style: AppTypography.displayMedium,
            ),
            AppGap.h12,
            const Text(
              'Por tu seguridad, necesitamos que confirmes tu contraseña actual antes de cambiarla.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium,
            ),
            AppGap.h32,

            AppPasswordField(
              key: ValueKey('current-password-$_fieldGeneration'),
              controller: _currentPasswordController,
              enabled: !_isLoading,
              label: 'Contraseña actual',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.password],
              validator: _validateCurrentPassword,
              onChanged: _clearErrorsOnEdit,
            ),
            if (_currentPasswordError != null) ...[
              AppGap.h8,
              _InlineError(message: _currentPasswordError!),
            ],
            AppGap.h16,

            AppPasswordField(
              key: ValueKey('new-password-$_fieldGeneration'),
              controller: _newPasswordController,
              focusNode: _newPasswordFocusNode,
              enabled: !_isLoading,
              label: 'Nueva contraseña',
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
              validator: _validateNewPassword,
              onChanged: _clearErrorsOnEdit,
            ),
            if (_newPasswordError != null) ...[
              AppGap.h8,
              _InlineError(message: _newPasswordError!),
            ],
            AppGap.h16,

            AppPasswordField(
              key: ValueKey('confirm-password-$_fieldGeneration'),
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              enabled: !_isLoading,
              label: 'Confirmar nueva contraseña',
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[],
              validator: _validateConfirmation,
              onChanged: _clearErrorsOnEdit,
              onFieldSubmitted: (_) => _submit(),
            ),

            if (_errorMessage != null) ...[
              AppGap.h12,
              _InlineError(message: _errorMessage!),
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

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.error),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySmall.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }
}