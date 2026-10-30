import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_layout.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/auth/auth_controller.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../../../content/data/content_models.dart';
import '../../../content/data/content_repository.dart';
import '../../../practice/data/practice_models.dart';
import '../../../practice/data/practice_repository.dart';
import '../../../practice/presentation/pages/practice_session_page.dart';
import '../widgets/daily_challenge_card.dart';
import '../widgets/student_bottom_navigation.dart';
import '../widgets/student_dashboard_header.dart';
import '../widgets/student_metric_card.dart';
import '../widgets/student_navigation_rail.dart';
import '../widgets/subject_card.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({
    super.key,
    required this.authController,
    this.apiClient,
  });

  final AuthController authController;
  final ApiClient? apiClient;

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  static const _fallbackSubjects = [
    SubjectModel(
      id: 'science',
      name: 'Ciencias naturales',
      description: 'Explora el mundo natural.',
    ),
    SubjectModel(
      id: 'mathematics',
      name: 'Matemáticas',
      description: 'Fortalece tu razonamiento.',
    ),
    SubjectModel(
      id: 'reading',
      name: 'Lectura crítica',
      description: 'Comprende y analiza textos.',
    ),
    SubjectModel(
      id: 'social',
      name: 'Sociales y ciudadanas',
      description: 'Entiende tu entorno.',
    ),
    SubjectModel(
      id: 'english',
      name: 'Inglés',
      description: 'Practica otro idioma.',
    ),
  ];

  ContentRepository? _contentRepository;
  PracticeRepository? _practiceRepository;
  List<SubjectModel> _subjects = const [];
  List<PracticeSessionSummaryModel> _sessions = const [];
  bool _loading = false;
  String? _errorMessage;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    final apiClient = widget.apiClient;
    if (apiClient == null) {
      _subjects = _fallbackSubjects;
    } else {
      _contentRepository = ContentRepository(apiClient);
      _practiceRepository = PracticeRepository(apiClient);
      _loadData();
    }
  }

  String _messageFor(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return error.message;
    }
    return 'No se pudo cargar tu espacio de práctica.';
  }

  Future<void> _loadData() async {
    final contentRepository = _contentRepository;
    final practiceRepository = _practiceRepository;
    if (contentRepository == null || practiceRepository == null) {
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final subjectsFuture = contentRepository.getSubjects();
      final sessionsFuture = practiceRepository.getHistory();
      final subjects = await subjectsFuture;
      final sessions = await sessionsFuture;
      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _sessions = sessions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _messageFor(error);
      });
    }
  }

  Future<void> _startPractice(
    SubjectModel subject, {
    int? questionCount,
  }) async {
    final apiClient = widget.apiClient;
    if (apiClient == null) {
      _showMessage(
        'Conecta el backend para iniciar una práctica.',
        error: true,
      );
      return;
    }
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PracticeSessionPage(
          apiClient: apiClient,
          subject: subject,
          questionCount: questionCount,
        ),
      ),
    );
    if (completed == true && mounted) {
      await _loadData();
    }
  }

  void _startDailyChallenge() {
    if (_subjects.isEmpty) {
      _showMessage(
        'Todavía no hay materias disponibles para practicar.',
        error: true,
      );
      return;
    }
    _startPractice(_subjects.first, questionCount: 10);
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : AppColors.primary,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authController.currentUser!;
    return LayoutBuilder(
      builder: (context, viewport) {
        final useNavigationRail =
            viewport.maxWidth >= AppLayout.expandedBreakpoint;
        return Scaffold(
          backgroundColor: AppColors.background,
          bottomNavigationBar: useNavigationRail
              ? null
              : StudentBottomNavigation(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                ),
          body: SafeArea(
            bottom: useNavigationRail,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (useNavigationRail) ...[
                  StudentNavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) =>
                        setState(() => _selectedIndex = index),
                  ),
                  const VerticalDivider(width: 1),
                ],
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        viewport.maxWidth < AppLayout.compactBreakpoint
                            ? AppSpacing.md
                            : AppSpacing.xl,
                        AppSpacing.lg,
                        viewport.maxWidth < AppLayout.compactBreakpoint
                            ? AppSpacing.md
                            : AppSpacing.xl,
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
                              StudentDashboardHeader(
                                email: user.email,
                                onLogout: widget.authController.logout,
                              ),
                              AppGap.h32,
                              if (_errorMessage != null) ...[
                                _StudentErrorBanner(
                                  message: _errorMessage!,
                                  onRetry: _loadData,
                                ),
                                AppGap.h24,
                              ],
                              if (_loading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 120),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else
                                _buildSelectedView(user.email),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedView(String email) {
    return switch (_selectedIndex) {
      1 => _SubjectsView(subjects: _subjects, onStart: _startPractice),
      2 => _ProgressView(sessions: _sessions),
      3 => _ProfileView(
        email: email,
        onLogout: widget.authController.logout,
      ),
      _ => _HomeView(
        subjects: _subjects,
        sessions: _sessions,
        onDailyChallenge: _startDailyChallenge,
        onStartSubject: _startPractice,
        onViewAllSubjects: () => setState(() => _selectedIndex = 1),
      ),
    };
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView({
    required this.subjects,
    required this.sessions,
    required this.onDailyChallenge,
    required this.onStartSubject,
    required this.onViewAllSubjects,
  });

  final List<SubjectModel> subjects;
  final List<PracticeSessionSummaryModel> sessions;
  final VoidCallback onDailyChallenge;
  final void Function(SubjectModel subject, {int? questionCount})
  onStartSubject;
  final VoidCallback onViewAllSubjects;

  @override
  Widget build(BuildContext context) {
    final completed = sessions.where((session) => session.isCompleted).length;
    final answered = sessions.fold<int>(
      0,
      (total, session) => total + session.answeredQuestions,
    );
    final lastSubject = sessions.isEmpty
        ? 'Sin iniciar'
        : sessions.first.subjectName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tu progreso de hoy', style: AppTypography.headline),
        AppGap.h16,
        LayoutBuilder(
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
              children: [
                StudentMetricCard(
                  icon: Icons.task_alt_outlined,
                  value: '$completed',
                  label: 'Prácticas completas',
                  iconColor: AppColors.success,
                ),
                StudentMetricCard(
                  icon: Icons.fact_check_outlined,
                  value: '$answered',
                  label: 'Respuestas enviadas',
                  iconColor: AppColors.primaryLight,
                ),
                StudentMetricCard(
                  icon: Icons.menu_book_outlined,
                  value: lastSubject,
                  label: 'Última materia',
                  iconColor: AppColors.warning,
                ),
              ],
            );
          },
        ),
        AppGap.h24,
        DailyChallengeCard(onStart: onDailyChallenge),
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
              onPressed: onViewAllSubjects,
              child: const Text('Ver todas'),
            ),
          ],
        ),
        AppGap.h16,
        _SubjectsGrid(subjects: subjects, onStart: onStartSubject),
      ],
    );
  }
}

class _SubjectsView extends StatelessWidget {
  const _SubjectsView({required this.subjects, required this.onStart});

  final List<SubjectModel> subjects;
  final void Function(SubjectModel subject, {int? questionCount}) onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Materias disponibles', style: AppTypography.displayMedium),
        AppGap.h8,
        Text(
          'Selecciona un área para comenzar una práctica con sus preguntas.',
          style: AppTypography.bodyMedium,
        ),
        AppGap.h24,
        _SubjectsGrid(subjects: subjects, onStart: onStart),
      ],
    );
  }
}

class _SubjectsGrid extends StatelessWidget {
  const _SubjectsGrid({required this.subjects, required this.onStart});

  final List<SubjectModel> subjects;
  final void Function(SubjectModel subject, {int? questionCount}) onStart;

  @override
  Widget build(BuildContext context) {
    if (subjects.isEmpty) {
      return const _StudentEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'Aún no hay materias',
        detail: 'Espera a que un administrador configure el contenido.',
      );
    }
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
            final style = _styleForSubject(subject.name, index);
            return SubjectCard(
              title: subject.name,
              subtitle: subject.description?.trim().isNotEmpty == true
                  ? subject.description!
                  : 'Comenzar práctica',
              icon: style.icon,
              backgroundColor: style.background,
              iconColor: style.iconColor,
              onTap: () => onStart(subject),
            );
          },
        );
      },
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.sessions});

  final List<PracticeSessionSummaryModel> sessions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tu progreso', style: AppTypography.displayMedium),
        AppGap.h8,
        Text(
          'Historial de sesiones realizadas en la plataforma.',
          style: AppTypography.bodyMedium,
        ),
        AppGap.h24,
        if (sessions.isEmpty)
          const _StudentEmptyState(
            icon: Icons.history_rounded,
            title: 'Todavía no tienes prácticas',
            detail: 'Selecciona una materia y completa tu primera sesión.',
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var index = 0; index < sessions.length; index++) ...[
                  _SessionTile(session: sessions[index]),
                  if (index != sessions.length - 1) const Divider(height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final PracticeSessionSummaryModel session;

  @override
  Widget build(BuildContext context) {
    final answered = session.answeredQuestions;
    final date = session.startedAtUtc?.toLocal();
    final dateLabel = date == null
        ? 'Fecha no disponible'
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      leading: CircleAvatar(
        backgroundColor: session.isCompleted
            ? AppColors.success.withValues(alpha: .12)
            : AppColors.warning.withValues(alpha: .12),
        child: Icon(
          session.isCompleted ? Icons.check_rounded : Icons.timelapse_rounded,
          color: session.isCompleted ? AppColors.success : AppColors.warning,
        ),
      ),
      title: Text(session.subjectName),
      subtitle: Text(
        '$answered/${session.totalQuestions} respondidas · $dateLabel',
      ),
      trailing: Text(
        session.isCompleted ? 'Completada' : 'En progreso',
        style: AppTypography.label.copyWith(
          color: session.isCompleted ? AppColors.success : AppColors.warning,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.email,
    required this.onLogout,
  });

  final String email;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tu perfil', style: AppTypography.displayMedium),
        AppGap.h24,
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: AppColors.surfaceSecondary,
                  child: Text(email.isEmpty ? 'E' : email[0].toUpperCase()),
                ),
                title: const Text('Estudiante'),
                subtitle: Text(email),
              ),
              const Divider(),
              AppGap.h16,
              Text('Suscripción', style: AppTypography.headline),
              AppGap.h8,
              const Text(
                'Consulta tu plan actual, los días restantes y las opciones de mejora.',
                style: AppTypography.bodyMedium,
              ),
              AppGap.h16,
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.pushNamed(AppRoutes.mySubscriptionName),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Ver mi suscripción'),
                ),
              ),
              AppGap.h24,
              const Divider(),
              AppGap.h16,
              Text('Seguridad', style: AppTypography.headline),
              AppGap.h8,
              const Text(
                'Actualiza tu contraseña confirmando la actual. Se cerrarán las demás sesiones activas por seguridad.',
                style: AppTypography.bodyMedium,
              ),
              AppGap.h16,
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: () =>
                      context.pushNamed(AppRoutes.changePasswordName),
                  icon: const Icon(Icons.lock_reset_rounded),
                  label: const Text('Cambiar contraseña'),
                ),
              ),
              AppGap.h24,
              const Divider(),
              AppGap.h12,
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Cerrar sesión'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudentErrorBanner extends StatelessWidget {
  const _StudentErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Reintentar')),
        ],
      ),
    );
  }
}

class _StudentEmptyState extends StatelessWidget {
  const _StudentEmptyState({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.primary),
          AppGap.h12,
          Text(
            title,
            style: AppTypography.headline,
            textAlign: TextAlign.center,
          ),
          AppGap.h8,
          Text(
            detail,
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

_SubjectStyle _styleForSubject(String name, int index) {
  final normalized = name.toLowerCase();
  if (normalized.contains('ciencia')) {
    return const _SubjectStyle(
      icon: Icons.science_outlined,
      background: AppColors.scienceSurface,
      iconColor: AppColors.warning,
    );
  }
  if (normalized.contains('matem')) {
    return const _SubjectStyle(
      icon: Icons.calculate_outlined,
      background: AppColors.mathematicsSurface,
      iconColor: AppColors.primaryLight,
    );
  }
  if (normalized.contains('lectura')) {
    return const _SubjectStyle(
      icon: Icons.auto_stories_outlined,
      background: AppColors.readingSurface,
      iconColor: AppColors.error,
    );
  }
  if (normalized.contains('social')) {
    return const _SubjectStyle(
      icon: Icons.public_outlined,
      background: AppColors.socialSurface,
      iconColor: AppColors.success,
    );
  }
  if (normalized.contains('ingl')) {
    return const _SubjectStyle(
      icon: Icons.translate_rounded,
      background: AppColors.englishSurface,
      iconColor: AppColors.primary,
    );
  }
  const styles = [
    _SubjectStyle(
      icon: Icons.menu_book_outlined,
      background: AppColors.scienceSurface,
      iconColor: AppColors.warning,
    ),
    _SubjectStyle(
      icon: Icons.psychology_outlined,
      background: AppColors.mathematicsSurface,
      iconColor: AppColors.adminBlue,
    ),
    _SubjectStyle(
      icon: Icons.lightbulb_outline_rounded,
      background: AppColors.englishSurface,
      iconColor: AppColors.adminPurple,
    ),
  ];
  return styles[index % styles.length];
}

class _SubjectStyle {
  const _SubjectStyle({
    required this.icon,
    required this.background,
    required this.iconColor,
  });

  final IconData icon;
  final Color background;
  final Color iconColor;
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