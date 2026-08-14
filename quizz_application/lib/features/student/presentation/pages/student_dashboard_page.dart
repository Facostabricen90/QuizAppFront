import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/auth_controller.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../widgets/daily_challenge_card.dart';
import '../widgets/student_bottom_navigation.dart';
import '../widgets/student_dashboard_header.dart';
import '../widgets/student_metric_card.dart';
import '../widgets/student_navigation_rail.dart';
import '../widgets/subject_card.dart';

class StudentDashboardPage extends StatelessWidget {
  const StudentDashboardPage({super.key, required this.authController});

  final AuthController authController;

  static const _subjects = [
    _SubjectItem(
      title: 'Ciencias naturales',
      icon: Icons.science_outlined,
      backgroundColor: AppColors.scienceSurface,
      iconColor: AppColors.warning,
    ),
    _SubjectItem(
      title: 'Matemáticas',
      icon: Icons.calculate_outlined,
      backgroundColor: AppColors.mathematicsSurface,
      iconColor: AppColors.primaryLight,
    ),
    _SubjectItem(
      title: 'Lectura crítica',
      icon: Icons.auto_stories_outlined,
      backgroundColor: AppColors.readingSurface,
      iconColor: AppColors.error,
    ),
    _SubjectItem(
      title: 'Sociales y ciudadanas',
      icon: Icons.public_outlined,
      backgroundColor: AppColors.socialSurface,
      iconColor: AppColors.success,
    ),
    _SubjectItem(
      title: 'Inglés',
      icon: Icons.translate_rounded,
      backgroundColor: AppColors.englishSurface,
      iconColor: AppColors.primary,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final user = authController.currentUser!;

    return LayoutBuilder(
      builder: (context, viewport) {
        final useNavigationRail =
            viewport.maxWidth >= AppLayout.expandedBreakpoint;

        void onDestinationSelected(int index) {
          if (index != 0) {
            _showComingSoon(context);
          }
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: useNavigationRail
              ? null
              : StudentBottomNavigation(
                  onDestinationSelected: onDestinationSelected,
                ),
          body: SafeArea(
            bottom: useNavigationRail,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (useNavigationRail) ...[
                  StudentNavigationRail(
                    onDestinationSelected: onDestinationSelected,
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: _DashboardContent(
                    email: user.email,
                    onLogout: authController.logout,
                    onComingSoon: () => _showComingSoon(context),
                    subjects: _subjects,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Esta sección estará disponible próximamente.'),
        ),
      );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.email,
    required this.onLogout,
    required this.onComingSoon,
    required this.subjects,
  });

  final String email;
  final VoidCallback onLogout;
  final VoidCallback onComingSoon;
  final List<_SubjectItem> subjects;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding =
            constraints.maxWidth < AppLayout.compactBreakpoint
            ? AppSpacing.md
            : AppSpacing.xl;

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.lg,
            horizontalPadding,
            AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppLayout.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StudentDashboardHeader(email: email, onLogout: onLogout),
                  AppGap.h32,
                  Text('Tu progreso de hoy', style: AppTypography.headline),
                  AppGap.h16,
                  const _MetricsSection(),
                  AppGap.h24,
                  DailyChallengeCard(onStart: onComingSoon),
                  AppGap.h32,
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Explora por materias',
                          style: AppTypography.headline,
                        ),
                      ),
                      TextButton(
                        onPressed: onComingSoon,
                        child: const Text('Ver todas'),
                      ),
                    ],
                  ),
                  AppGap.h16,
                  _SubjectsGrid(
                    subjects: subjects,
                    onSubjectSelected: onComingSoon,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MetricsSection extends StatelessWidget {
  const _MetricsSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _responsiveColumnCount(
          availableWidth: constraints.maxWidth,
          minimumItemWidth: AppLayout.minMetricCardWidth,
          maximumColumns: AppLayout.maxMetricColumns,
          spacing: AppSpacing.xs,
        );

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.xs,
          mainAxisSpacing: AppSpacing.xs,
          mainAxisExtent: AppSpacing.xxxl + AppSpacing.xxl,
          children: const [
            StudentMetricCard(
              icon: Icons.local_fire_department_outlined,
              value: '0',
              label: 'Días seguidos',
              iconColor: AppColors.warning,
            ),
            StudentMetricCard(
              icon: Icons.auto_awesome_outlined,
              value: '0 XP',
              label: 'Experiencia total',
              iconColor: AppColors.primaryLight,
            ),
            StudentMetricCard(
              icon: Icons.emoji_events_outlined,
              value: 'Nivel 1',
              label: 'Nivel actual',
              iconColor: AppColors.success,
            ),
          ],
        );
      },
    );
  }
}

class _SubjectsGrid extends StatelessWidget {
  const _SubjectsGrid({
    required this.subjects,
    required this.onSubjectSelected,
  });

  final List<_SubjectItem> subjects;
  final VoidCallback onSubjectSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _responsiveColumnCount(
          availableWidth: constraints.maxWidth,
          minimumItemWidth: AppLayout.minSubjectCardWidth,
          maximumColumns: AppLayout.maxSubjectColumns,
          spacing: AppSpacing.sm,
        );
        final totalSpacing = AppSpacing.sm * (columns - 1);
        final itemWidth = (constraints.maxWidth - totalSpacing) / columns;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subjects.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            mainAxisExtent: itemWidth * AppLayout.subjectCardHeightFactor,
          ),
          itemBuilder: (context, index) {
            final subject = subjects[index];
            return SubjectCard(
              title: subject.title,
              subtitle: 'Próximamente',
              icon: subject.icon,
              backgroundColor: subject.backgroundColor,
              iconColor: subject.iconColor,
              onTap: onSubjectSelected,
            );
          },
        );
      },
    );
  }
}

int _responsiveColumnCount({
  required double availableWidth,
  required double minimumItemWidth,
  required int maximumColumns,
  required double spacing,
}) {
  final columns = ((availableWidth + spacing) / (minimumItemWidth + spacing))
      .floor();
  return columns.clamp(1, maximumColumns).toInt();
}

class _SubjectItem {
  const _SubjectItem({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
}
