import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72, this.showText = true});

  final double size;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              "Q",
              style: AppTypography.displayMedium.copyWith(color: Colors.white),
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 16),
          Text("QuizApp", style: AppTypography.headline),
        ],
      ],
    );
  }
}
