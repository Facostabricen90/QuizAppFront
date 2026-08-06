import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../../../../shared/presentation/widgets/app_logo.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppLogo(),

        AppGap.h32,

        const Text(
          'Bienvenido nuevamente',
          style: AppTypography.displayMedium,
          textAlign: TextAlign.center,
        ),

        AppGap.h8,

        const Text(
          'Inicia sesión para continuar\ncon tu experiencia de aprendizaje.',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
