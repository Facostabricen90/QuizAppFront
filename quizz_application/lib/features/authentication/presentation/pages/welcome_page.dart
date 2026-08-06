import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/auth_controller.dart';
import '../../../../shared/presentation/widgets/app_button.dart';
import '../../../../shared/presentation/widgets/app_card.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../../../../shared/presentation/widgets/app_logo.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    final user = authController.currentUser!;
    final roles = user.roles.isEmpty ? const ['Usuario'] : user.roles;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('QuizApp', style: AppTypography.headline),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: authController.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  children: [
                    const AppLogo(size: 80, showText: false),

                    AppGap.h24,

                    Text(
                      '¡Bienvenido a QuizApp!',
                      textAlign: TextAlign.center,
                      style: AppTypography.displayMedium,
                    ),

                    AppGap.h12,

                    Text(
                      user.email,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),

                    AppGap.h16,

                    Text(
                      'Tu sesión está activa. Estamos preparando tu espacio de práctica para que puedas avanzar con confianza.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyLarge,
                    ),

                    AppGap.h16,

                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: roles
                          .map(
                            (role) => Chip(
                              avatar: const Icon(
                                Icons.verified_user_outlined,
                                size: 18,
                              ),
                              label: Text(role),
                              backgroundColor: AppColors.surfaceSecondary,
                              side: BorderSide.none,
                            ),
                          )
                          .toList(growable: false),
                    ),

                    AppGap.h32,

                    LayoutBuilder(
                      builder: (context, constraints) {
                        final cardWidth = constraints.maxWidth >= 760
                            ? 235.0
                            : constraints.maxWidth;

                        return Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.md,
                          runSpacing: AppSpacing.md,
                          children: [
                            SizedBox(
                              width: cardWidth,
                              child: const _WelcomeFeature(
                                icon: Icons.menu_book_outlined,
                                title: 'Practica',
                                description:
                                    'Entrena tus conocimientos con cuestionarios.',
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: const _WelcomeFeature(
                                icon: Icons.insights_outlined,
                                title: 'Mide tu avance',
                                description:
                                    'Consulta tus resultados y descubre oportunidades.',
                              ),
                            ),
                            SizedBox(
                              width: cardWidth,
                              child: const _WelcomeFeature(
                                icon: Icons.flag_outlined,
                                title: 'Alcanza tus metas',
                                description:
                                    'Construye un hábito de estudio constante.',
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    AppGap.h32,

                    AppButton(
                      text: 'Explorar plataforma',
                      icon: Icons.arrow_forward_rounded,
                      expand: false,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Esta sección estará disponible próximamente.',
                            ),
                          ),
                        );
                      },
                    ),
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

class _WelcomeFeature extends StatelessWidget {
  const _WelcomeFeature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          AppGap.h12,
          Text(title, textAlign: TextAlign.center, style: AppTypography.label),
          AppGap.h8,
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ],
      ),
    );
  }
}
