import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/auth/auth_controller.dart';
import '../../../../shared/presentation/widgets/app_card.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../widgets/register_form.dart';
import '../widgets/register_header.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AppCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const RegisterHeader(),

                    AppGap.h32,

                    RegisterForm(authController: authController),
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
