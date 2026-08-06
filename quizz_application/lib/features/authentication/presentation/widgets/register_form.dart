import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/auth_controller.dart';
import '../../../../shared/presentation/widgets/app_button.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../../../../shared/presentation/widgets/app_password_field.dart';
import '../../../../shared/presentation/widgets/app_text_field.dart';
import '../pages/login_page.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key, required this.authController});

  final AuthController authController;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;
  bool _showTermsError = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final isFormValid = _formKey.currentState?.validate() ?? false;

    setState(() {
      _showTermsError = !_acceptTerms;
    });

    if (!isFormValid || !_acceptTerms) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final success = await widget.authController.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() {
      _isLoading = false;
      _errorMessage =
          widget.authController.errorMessage ?? 'No se pudo crear la cuenta.';
    });
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(authController: widget.authController),
      ),
    );
  }

  String? _validateRequired(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa $fieldName.';
    }

    return null;
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una contraseña.';
    }

    if (value.length < 8) {
      return 'Utiliza al menos 8 caracteres.';
    }

    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña.';
    }

    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Nombres',
              controller: _firstNameController,
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  _validateRequired(value, fieldName: 'tus nombres'),
            ),

            AppGap.h16,

            AppTextField(
              label: 'Apellidos',
              controller: _lastNameController,
              prefixIcon: Icons.person_outline,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              validator: (value) =>
                  _validateRequired(value, fieldName: 'tus apellidos'),
            ),

            AppGap.h16,

            AppTextField(
              label: 'Correo electrónico',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
            ),

            AppGap.h16,

            AppPasswordField(
              controller: _passwordController,
              textInputAction: TextInputAction.next,
              validator: _validatePassword,
            ),

            AppGap.h16,

            AppPasswordField(
              controller: _confirmPasswordController,
              label: 'Confirmar contraseña',
              textInputAction: TextInputAction.done,
              validator: _validatePasswordConfirmation,
              onFieldSubmitted: (_) => _submit(),
            ),

            AppGap.h16,

            CheckboxListTile(
              value: _acceptTerms,
              onChanged: _isLoading
                  ? null
                  : (value) {
                      setState(() {
                        _acceptTerms = value ?? false;
                        if (_acceptTerms) {
                          _showTermsError = false;
                        }
                      });
                    },
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
              title: Text.rich(
                TextSpan(
                  style: AppTypography.bodySmall,
                  children: const [
                    TextSpan(text: 'Acepto los '),
                    TextSpan(
                      text: 'términos y condiciones',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(text: ' y el tratamiento de mis datos.'),
                  ],
                ),
              ),
            ),

            if (_showTermsError) ...[
              AppGap.h4,
              Text(
                'Debes aceptar los términos para continuar.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ],

            if (_errorMessage != null) ...[
              AppGap.h12,
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],

            AppGap.h24,

            AppButton(
              text: 'Crear cuenta',
              onPressed: _submit,
              isLoading: _isLoading,
            ),

            AppGap.h16,

            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('¿Ya tienes una cuenta?'),
                TextButton(
                  onPressed: _isLoading ? null : _goToLogin,
                  child: const Text('Iniciar sesión'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
