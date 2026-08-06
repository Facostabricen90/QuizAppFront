import 'package:flutter/material.dart';

import '../../../../app/theme/app_typography.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../../../../shared/presentation/widgets/app_logo.dart';

class RegisterHeader extends StatelessWidget {
  const RegisterHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppLogo(),

        AppGap.h24,

        const Text(
          'Crea tu cuenta',
          style: AppTypography.displayMedium,
          textAlign: TextAlign.center,
        ),

        AppGap.h8,

        const Text(
          'Regístrate como estudiante y comienza\ntu experiencia de aprendizaje.',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
