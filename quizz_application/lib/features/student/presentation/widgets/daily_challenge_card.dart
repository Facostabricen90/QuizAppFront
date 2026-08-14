import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/presentation/widgets/app_button.dart';

class DailyChallengeCard extends StatelessWidget {
  const DailyChallengeCard({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: ColoredBox(
        color: AppColors.challenge,
        child: Stack(
          children: [
            const Positioned.fill(
              child: Align(
                alignment: Alignment.topRight,
                child: FractionalTranslation(
                  translation: Offset(.35, -.35),
                  child: FractionallySizedBox(
                    widthFactor: AppLayout.challengeCircleWidthFactor,
                    child: _DecorativeCircle(),
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: Align(
                alignment: Alignment.bottomRight,
                child: FractionalTranslation(
                  translation: Offset(-.45, .45),
                  child: FractionallySizedBox(
                    widthFactor: AppLayout.challengeCircleWidthFactor,
                    child: _DecorativeCircle(),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'RETO DIARIO',
                      style: AppTypography.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Pon a prueba tus conocimientos',
                    style: AppTypography.headline.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '10 preguntas · +150 XP',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.surface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    text: 'Comenzar',
                    icon: Icons.arrow_forward_rounded,
                    expand: false,
                    variant: AppButtonVariant.light,
                    onPressed: onStart,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: .06),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
