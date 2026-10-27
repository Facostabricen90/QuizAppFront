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
import '../../../../shared/presentation/widgets/app_logo.dart';
import '../../../content/data/content_models.dart';
import '../../../content/data/content_repository.dart';
import '../widgets/admin_dialogs.dart';

enum _AdminSection {
  overview('Resumen', Icons.dashboard_outlined),
  reports('Reportes', Icons.bar_chart_rounded),
  questions('Preguntas', Icons.quiz_outlined),
  subjects('Materias', Icons.category_outlined),
  staff('Profesores', Icons.badge_outlined, adminOnly: true),
  schools('Instituciones', Icons.apartment_outlined, adminOnly: true),
  invitationCodes('Códigos', Icons.vpn_key_outlined, adminOnly: true),
  account('Mi cuenta', Icons.manage_accounts_outlined);

  const _AdminSection(this.label, this.icon, {this.adminOnly = false});

  final String label;
  final IconData icon;
  final bool adminOnly;
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.authController,
    this.apiClient,
  });

  final AuthController authController;
  final ApiClient? apiClient;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final ContentRepository? _repository;
  _AdminSection _section = _AdminSection.overview;
  List<SubjectModel> _subjects = const [];
  List<QuestionModel> _questions = const [];
  List<SchoolModel> _schools = const [];
  List<InvitationCodeModel> _invitationCodes = const [];
  ReportResponseModel? _studentReports;
  bool _loading = false;
  bool _mutating = false;
  String? _errorMessage;

  bool get _isAdmin =>
      widget.authController.currentUser?.hasRole('Admin') ?? false;

  @override
  void initState() {
    super.initState();
    _repository = widget.apiClient == null
        ? null
        : ContentRepository(widget.apiClient!);
    if (_repository != null) {
      _loadData();
    }
  }

  Future<void> _loadData({bool showProgress = true}) async {
    final repository = _repository;
    if (repository == null) return;
    if (showProgress && mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final subjectsFuture = repository.getSubjects();
      final questionsFuture = repository.getQuestions();
      final schoolsFuture = _isAdmin
          ? repository.getSchools()
          : Future<List<SchoolModel>>.value(const []);
      final codesFuture = _isAdmin
          ? repository.getInvitationCodes()
          : Future<List<InvitationCodeModel>>.value(const []);
      final reportsFuture = repository.getStudentReports();

      final subjects = await subjectsFuture;
      final questions = await questionsFuture;
      final schools = await schoolsFuture;
      final codes = await codesFuture;
      final reports = await reportsFuture;

      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _questions = questions;
        _schools = schools;
        _invitationCodes = codes;
        _studentReports = reports;
        _loading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _messageFor(error);
      });
    }
  }

  String _messageFor(Object error) {
    if (error is ApiException) return error.message;
    if (error is FormatException) return error.message;
    return 'No se pudo completar la operación.';
  }

  void _showMessage(String message, {bool error = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: error ? AppColors.error : AppColors.primary,
        ),
      );
  }

  Future<void> _runMutation(
    Future<void> Function() operation,
    String successMessage,
  ) async {
    if (_mutating) return;
    setState(() => _mutating = true);
    try {
      await operation();
      if (!mounted) return;
      _showMessage(successMessage);
      await _loadData(showProgress: false);
    } catch (error) {
      if (mounted) _showMessage(_messageFor(error), error: true);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<bool> _confirmDelete(String title, String detail) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(detail),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _openQuestion([QuestionModel? question]) async {
    final repository = _repository;
    if (repository == null) {
      _showMessage('Configura API_BASE_URL para conectar el backend.', error: true);
      return;
    }
    if (_subjects.isEmpty) {
      _showMessage(_isAdmin ? 'Primero crea una materia.' : 'Un administrador debe crear al menos una materia.', error: true);
      if (_isAdmin) setState(() => _section = _AdminSection.subjects);
      return;
    }
    final draft = await showQuestionDialog(context, subjects: _subjects, question: question);
    if (draft == null || !mounted) return;
    await _runMutation(() async {
      if (question == null) {
        await repository.createQuestion(draft);
      } else {
        await repository.updateQuestion(question.id, draft);
      }
    }, question == null ? 'Pregunta creada.' : 'Pregunta actualizada.');
  }

  Future<void> _deleteQuestion(QuestionModel question) async {
    final repository = _repository;
    if (repository == null || !await _confirmDelete('Eliminar pregunta', 'Esta acción eliminará “${question.text}”.')) return;
    await _runMutation(() => repository.deleteQuestion(question.id), 'Pregunta eliminada.');
  }

  Future<void> _openSubject([SubjectModel? subject]) async {
    final repository = _repository;
    if (repository == null) return;
    final draft = await showSubjectDialog(context, subject: subject);
    if (draft == null || !mounted) return;
    await _runMutation(() async {
      if (subject == null) {
        await repository.createSubject(name: draft.name, description: draft.description);
      } else {
        await repository.updateSubject(subject.id, name: draft.name, description: draft.description);
      }
    }, subject == null ? 'Materia creada.' : 'Materia actualizada.');
  }

  Future<void> _deleteSubject(SubjectModel subject) async {
    final repository = _repository;
    if (repository == null || !await _confirmDelete('Eliminar materia', 'Se intentará eliminar “${subject.name}”. Si tiene preguntas asociadas, el backend puede impedirlo.')) return;
    await _runMutation(() => repository.deleteSubject(subject.id), 'Materia eliminada.');
  }

  Future<void> _openSchool([SchoolModel? school]) async {
    final repository = _repository;
    if (repository == null) return;
    final draft = await showSchoolDialog(context, school: school);
    if (draft == null || !mounted) return;
    await _runMutation(() async {
      if (school == null) {
        await repository.createSchool(name: draft.name, city: draft.city);
      } else {
        await repository.updateSchool(school.id, name: draft.name, city: draft.city);
      }
    }, school == null ? 'Institución creada.' : 'Institución actualizada.');
  }

  Future<void> _deleteSchool(SchoolModel school) async {
    final repository = _repository;
    if (repository == null || !await _confirmDelete('Eliminar institución', 'Esta acción eliminará “${school.name}”.')) return;
    await _runMutation(() => repository.deleteSchool(school.id), 'Institución eliminada.');
  }

  Future<void> _createTeacher() async {
    final draft = await showStaffDialog(context);
    if (draft == null || !mounted) return;
    setState(() => _mutating = true);
    final success = await widget.authController.registerStaff(
      email: draft.email,
      password: draft.password,
      firstName: draft.firstName,
      lastName: draft.lastName,
    );
    if (!mounted) return;
    setState(() => _mutating = false);
    _showMessage(
      success ? 'Profesor creado. Ya puede iniciar sesión.' : widget.authController.errorMessage ?? 'No se pudo crear el profesor.',
      error: !success,
    );
  }

  Future<void> _openInvitationCode() async {
    final repository = _repository;
    if (repository == null) return;
    if (_schools.isEmpty) {
      _showMessage('Primero debes crear al menos una institución.', error: true);
      setState(() => _section = _AdminSection.schools);
      return;
    }
    final draft = await showInvitationCodeDialog(context, schools: _schools);
    if (draft == null || !mounted) return;
    await _runMutation(() async {
      await repository.createInvitationCode(institutionId: draft.institutionId, code: draft.code, maxUses: draft.maxUses, expiresAtUtc: draft.expiresAtUtc);
    }, 'Código creado.');
  }

  Future<void> _revokeInvitationCode(InvitationCodeModel code) async {
    final repository = _repository;
    if (repository == null) return;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Revocar código'),
            content: Text('El código “${code.code}” dejará de ser válido para nuevos registros. Los estudiantes que ya lo usaron no se verán afectados.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
              FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Revocar')),
            ],
          ),
        ) ?? false;
    if (!confirmed) return;
    await _runMutation(() => repository.revokeInvitationCode(code.id), 'Código revocado.');
  }

  Future<void> _deleteInvitationCode(InvitationCodeModel code) async {
    final repository = _repository;
    if (repository == null || !await _confirmDelete('Eliminar código', 'Esta acción eliminará permanentemente el código “${code.code}”.')) return;
    await _runMutation(() => repository.deleteInvitationCode(code.id), 'Código eliminado.');
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authController.currentUser!;
    final availableSections = _AdminSection.values
        .where((section) => _isAdmin || !section.adminOnly)
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, viewport) {
        final showSidebar = viewport.maxWidth >= AppLayout.adminSidebarBreakpoint;
        return Scaffold(
          backgroundColor: AppColors.adminBackground,
          body: SafeArea(
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showSidebar)
                      _AdminSidebar(
                        isAdmin: _isAdmin,
                        selected: _section,
                        sections: availableSections,
                        onSelect: (section) => setState(() => _section = section),
                        onCreateQuestion: _openQuestion,
                        onLogout: widget.authController.logout,
                      ),
                    Expanded(
                      child: _MainArea(
                        isAdmin: _isAdmin,
                        userEmail: user.email,
                        roles: user.roles,
                        selected: _section,
                        sections: availableSections,
                        showCompactNavigation: !showSidebar,
                        loading: _loading,
                        errorMessage: _errorMessage,
                        questions: _questions,
                        subjects: _subjects,
                        schools: _schools,
                        invitationCodes: _invitationCodes,
                        studentReports: _studentReports,
                        onSelect: (section) => setState(() => _section = section),
                        onRefresh: _loadData,
                        onCreateQuestion: _openQuestion,
                        onEditQuestion: _openQuestion,
                        onDeleteQuestion: _deleteQuestion,
                        onCreateSubject: _openSubject,
                        onEditSubject: _openSubject,
                        onDeleteSubject: _deleteSubject,
                        onCreateTeacher: _createTeacher,
                        onCreateSchool: _openSchool,
                        onEditSchool: _openSchool,
                        onDeleteSchool: _deleteSchool,
                        onCreateInvitationCode: _openInvitationCode,
                        onRevokeInvitationCode: _revokeInvitationCode,
                        onDeleteInvitationCode: _deleteInvitationCode,
                        onLogout: widget.authController.logout,
                      ),
                    ),
                  ],
                ),
                if (_mutating)
                  const Positioned(
                    left: 0, right: 0, top: 0,
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.isAdmin,
    required this.selected,
    required this.sections,
    required this.onSelect,
    required this.onCreateQuestion,
    required this.onLogout,
  });

  final bool isAdmin;
  final _AdminSection selected;
  final List<_AdminSection> sections;
  final ValueChanged<_AdminSection> onSelect;
  final VoidCallback onCreateQuestion;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppLayout.adminSidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BrandLockup(isAdmin: isAdmin),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onCreateQuestion,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Nueva pregunta'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.adminInk, minimumSize: const Size.fromHeight(44)),
          ),
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('NAVEGACIÓN', style: AppTypography.bodySmall.copyWith(fontSize: 10, letterSpacing: .7, fontWeight: FontWeight.w700, color: AppColors.adminMuted)),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final section in sections)
            _SidebarItem(section: section, selected: selected == section, onTap: () => onSelect(section)),
          const Spacer(),
          _SidebarAction(icon: Icons.logout_rounded, label: 'Cerrar sesión', onTap: onLogout),
        ],
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup({required this.isAdmin});
  final bool isAdmin;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogo(size: 42, showText: false),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('QuizApp', style: AppTypography.label.copyWith(fontSize: 17)),
              Text(isAdmin ? 'Panel administrativo' : 'Panel docente', style: AppTypography.bodySmall.copyWith(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({required this.section, required this.selected, required this.onTap});
  final _AdminSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
      child: Material(
        color: selected ? AppColors.adminSelected : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 11),
            child: Row(
              children: [
                Icon(section.icon, size: 19, color: selected ? AppColors.adminInk : AppColors.adminMuted),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  section.label,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.adminInk : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  const _SidebarAction({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary, alignment: Alignment.centerLeft),
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _MainArea extends StatelessWidget {
  const _MainArea({
    required this.isAdmin,
    required this.userEmail,
    required this.roles,
    required this.selected,
    required this.sections,
    required this.showCompactNavigation,
    required this.loading,
    required this.errorMessage,
    required this.questions,
    required this.subjects,
    required this.schools,
    required this.invitationCodes,
    required this.studentReports,
    required this.onSelect,
    required this.onRefresh,
    required this.onCreateQuestion,
    required this.onEditQuestion,
    required this.onDeleteQuestion,
    required this.onCreateSubject,
    required this.onEditSubject,
    required this.onDeleteSubject,
    required this.onCreateTeacher,
    required this.onCreateSchool,
    required this.onEditSchool,
    required this.onDeleteSchool,
    required this.onCreateInvitationCode,
    required this.onRevokeInvitationCode,
    required this.onDeleteInvitationCode,
    required this.onLogout,
  });

  final bool isAdmin;
  final String userEmail;
  final List<String> roles;
  final _AdminSection selected;
  final List<_AdminSection> sections;
  final bool showCompactNavigation;
  final bool loading;
  final String? errorMessage;
  final List<QuestionModel> questions;
  final List<SubjectModel> subjects;
  final List<SchoolModel> schools;
  final List<InvitationCodeModel> invitationCodes;
  final ReportResponseModel? studentReports;
  final ValueChanged<_AdminSection> onSelect;
  final Future<void> Function({bool showProgress}) onRefresh;
  final VoidCallback onCreateQuestion;
  final ValueChanged<QuestionModel> onEditQuestion;
  final ValueChanged<QuestionModel> onDeleteQuestion;
  final VoidCallback onCreateSubject;
  final ValueChanged<SubjectModel> onEditSubject;
  final ValueChanged<SubjectModel> onDeleteSubject;
  final VoidCallback onCreateTeacher;
  final VoidCallback onCreateSchool;
  final ValueChanged<SchoolModel> onEditSchool;
  final ValueChanged<SchoolModel> onDeleteSchool;
  final VoidCallback onCreateInvitationCode;
  final ValueChanged<InvitationCodeModel> onRevokeInvitationCode;
  final ValueChanged<InvitationCodeModel> onDeleteInvitationCode;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padding = constraints.maxWidth < 720 ? AppSpacing.md : constraints.maxWidth < 1100 ? AppSpacing.lg : AppSpacing.xl;
        return RefreshIndicator(
          onRefresh: () => onRefresh(showProgress: false),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(padding, AppSpacing.md, padding, AppSpacing.xxl),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppLayout.adminMaxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(
                      isAdmin: isAdmin, email: userEmail, selected: selected, sections: sections, showCompactNavigation: showCompactNavigation,
                      onSelect: onSelect, onRefresh: () => onRefresh(), onLogout: onLogout,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    if (errorMessage != null) ...[
                      _ErrorBanner(message: errorMessage!, onRetry: () => onRefresh()),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 120),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      _buildSection(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection() {
    return switch (selected) {
      _AdminSection.overview => _OverviewPanel(
        isAdmin: isAdmin, questions: questions, subjects: subjects, schools: schools,
        onCreateQuestion: onCreateQuestion, onCreateTeacher: onCreateTeacher, onOpenQuestions: () => onSelect(_AdminSection.questions),
      ),
      _AdminSection.reports => _ReportsPanel(reportData: studentReports),
      _AdminSection.questions => _QuestionsPanel(
        questions: questions, subjects: subjects, onCreate: onCreateQuestion, onEdit: onEditQuestion, onDelete: onDeleteQuestion,
      ),
      _AdminSection.subjects => _SubjectsPanel(
        isAdmin: isAdmin, subjects: subjects, onCreate: onCreateSubject, onEdit: onEditSubject, onDelete: onDeleteSubject,
      ),
      _AdminSection.staff => _StaffPanel(onCreate: onCreateTeacher),
      _AdminSection.schools => _SchoolsPanel(
        schools: schools, onCreate: onCreateSchool, onEdit: onEditSchool, onDelete: onDeleteSchool,
      ),
      _AdminSection.invitationCodes => _InvitationCodesPanel(
        codes: invitationCodes, onCreate: onCreateInvitationCode, onRevoke: onRevokeInvitationCode, onDelete: onDeleteInvitationCode,
      ),
      _AdminSection.account => _AccountPanel(email: userEmail, roles: roles, onLogout: onLogout),
    };
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.isAdmin, required this.email, required this.selected, required this.sections,
    required this.showCompactNavigation, required this.onSelect, required this.onRefresh, required this.onLogout,
  });

  final bool isAdmin;
  final String email;
  final _AdminSection selected;
  final List<_AdminSection> sections;
  final bool showCompactNavigation;
  final ValueChanged<_AdminSection> onSelect;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showCompactNavigation) ...[
          const AppLogo(size: 36, showText: false),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_AdminSection>(
                value: selected,
                isExpanded: true,
                items: sections.map((section) => DropdownMenuItem(
                  value: section,
                  child: Row(children: [Icon(section.icon, size: 18), const SizedBox(width: AppSpacing.xs), Text(section.label)]),
                )).toList(),
                onChanged: (section) { if (section != null) onSelect(section); },
              ),
            ),
          ),
        ] else ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAdmin ? 'Administración' : 'Espacio docente', style: AppTypography.bodySmall),
                Text(selected.label, style: AppTypography.label),
              ],
            ),
          ),
        ],
        IconButton(tooltip: 'Actualizar datos', onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded)),
        if (MediaQuery.sizeOf(context).width >= 720) ...[
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 150,
            child: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: AppTypography.bodySmall),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        PopupMenuButton<String>(
          tooltip: 'Cuenta',
          onSelected: (value) { 
            if (value == 'logout') {
              onLogout();
            } else if (value == 'account') {
              onSelect(_AdminSection.account); 
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(enabled: false, child: Text(email, overflow: TextOverflow.ellipsis)),
            const PopupMenuDivider(),
            const PopupMenuItem(value: 'account', child: Text('Mi cuenta')),
            const PopupMenuItem(value: 'logout', child: Text('Cerrar sesión')),
          ],
          child: CircleAvatar(
            backgroundColor: AppColors.adminAvatar, foregroundColor: AppColors.primary,
            child: Text(email.isEmpty ? 'A' : email[0].toUpperCase()),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.error.withValues(alpha: .08), borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.error.withValues(alpha: .2))),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(message, style: AppTypography.bodyMedium)),
        TextButton(onPressed: onRetry, child: const Text('Reintentar')),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle, this.actionLabel, this.actionIcon = Icons.add_rounded, this.onAction});
  final String title;
  final String subtitle;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final titleWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(title, style: AppTypography.displayMedium), const SizedBox(height: AppSpacing.xs), Text(subtitle, style: AppTypography.bodyMedium)],
        );
        final action = actionLabel == null || onAction == null ? null : FilledButton.icon(onPressed: onAction, icon: Icon(actionIcon), label: Text(actionLabel!));
        if (constraints.maxWidth < 620) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [titleWidget, if (action != null) ...[const SizedBox(height: AppSpacing.md), action]]);
        if (action == null) return Row(children: [Expanded(child: titleWidget)]);
        return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [Expanded(child: titleWidget), action]);
      },
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({
    required this.isAdmin, required this.questions, required this.subjects, required this.schools,
    required this.onCreateQuestion, required this.onCreateTeacher, required this.onOpenQuestions,
  });

  final bool isAdmin;
  final List<QuestionModel> questions;
  final List<SubjectModel> subjects;
  final List<SchoolModel> schools;
  final VoidCallback onCreateQuestion;
  final VoidCallback onCreateTeacher;
  final VoidCallback onOpenQuestions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: isAdmin ? 'Resumen administrativo' : 'Resumen docente',
          subtitle: isAdmin ? 'Control del contenido y la configuración de QuizApp.' : 'Gestiona las preguntas que resolverán los estudiantes.',
          actionLabel: 'Nueva pregunta', onAction: onCreateQuestion,
        ),
        const SizedBox(height: AppSpacing.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1020 ? 4 : constraints.maxWidth >= 620 ? 2 : 1;
            final width = (constraints.maxWidth - AppSpacing.md * (columns - 1)) / columns;
            final metrics = [
              _MetricData(label: 'Preguntas publicadas', value: '${questions.length}', icon: Icons.quiz_outlined, color: AppColors.primary),
              _MetricData(label: 'Materias disponibles', value: '${subjects.length}', icon: Icons.category_outlined, color: AppColors.adminPurple),
              _MetricData(label: 'Instituciones', value: isAdmin ? '${schools.length}' : '—', icon: Icons.apartment_outlined, color: AppColors.adminOrange),
              const _MetricData(label: 'Estudiantes activos', value: '—', icon: Icons.school_outlined, color: AppColors.adminBlue, note: 'Sin endpoint global'),
            ];
            return Wrap(
              spacing: AppSpacing.md, runSpacing: AppSpacing.md,
              children: [for (final metric in metrics) SizedBox(width: width, child: _MetricCard(data: metric))],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final recent = _RecentQuestions(questions: questions.take(5).toList(growable: false), onOpenAll: onOpenQuestions);
            final quick = _QuickActions(isAdmin: isAdmin, onCreateQuestion: onCreateQuestion, onCreateTeacher: onCreateTeacher);
            if (constraints.maxWidth < 880) return Column(children: [recent, const SizedBox(height: AppSpacing.md), quick]);
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(flex: 3, child: recent), const SizedBox(width: AppSpacing.md), Expanded(flex: 2, child: quick)]);
          },
        ),
      ],
    );
  }
}

class _MetricData {
  const _MetricData({required this.label, required this.value, required this.icon, required this.color, this.note});
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? note;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.data});
  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40, alignment: Alignment.center,
            decoration: BoxDecoration(color: data.color.withValues(alpha: .1), borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(data.value, style: AppTypography.displayMedium.copyWith(fontSize: 30)),
          const SizedBox(height: AppSpacing.xxs),
          Text(data.label, style: AppTypography.bodySmall),
          if (data.note != null) Text(data.note!, style: AppTypography.bodySmall.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(side: const BorderSide(color: AppColors.border), borderRadius: BorderRadius.circular(AppRadius.lg)),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: child),
    );
  }
}

class _RecentQuestions extends StatelessWidget {
  const _RecentQuestions({required this.questions, required this.onOpenAll});
  final List<QuestionModel> questions;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [Expanded(child: Text('Preguntas recientes', style: AppTypography.label.copyWith(fontSize: 15))), TextButton(onPressed: onOpenAll, child: const Text('Ver todas'))]),
          const Divider(),
          if (questions.isEmpty)
            const _EmptyState(icon: Icons.quiz_outlined, title: 'Aún no hay preguntas', detail: 'Crea la primera para comenzar el banco del quiz.')
          else
            for (final question in questions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.quiz_outlined, size: 18)),
                title: Text(question.text, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${question.subjectName} · ${question.difficulty.label}'),
              ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.isAdmin, required this.onCreateQuestion, required this.onCreateTeacher});
  final bool isAdmin;
  final VoidCallback onCreateQuestion;
  final VoidCallback onCreateTeacher;

  @override
  Widget build(BuildContext context) {
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Accesos rápidos', style: AppTypography.label.copyWith(fontSize: 15)),
          const SizedBox(height: AppSpacing.md),
          _QuickActionTile(icon: Icons.add_circle_outline_rounded, title: 'Crear pregunta', subtitle: 'Añadir contenido al banco', onTap: onCreateQuestion),
          if (isAdmin) ...[
            const Divider(),
            _QuickActionTile(icon: Icons.person_add_alt_1_outlined, title: 'Crear profesor', subtitle: 'Provisionar una cuenta docente', onTap: onCreateTeacher),
          ],
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero, onTap: onTap,
      leading: CircleAvatar(child: Icon(icon, size: 19)),
      title: Text(title, style: AppTypography.label), subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
    );
  }
}

class _QuestionsPanel extends StatefulWidget {
  const _QuestionsPanel({required this.questions, required this.subjects, required this.onCreate, required this.onEdit, required this.onDelete});
  final List<QuestionModel> questions;
  final List<SubjectModel> subjects;
  final VoidCallback onCreate;
  final ValueChanged<QuestionModel> onEdit;
  final ValueChanged<QuestionModel> onDelete;

  @override
  State<_QuestionsPanel> createState() => _QuestionsPanelState();
}

class _QuestionsPanelState extends State<_QuestionsPanel> {
  String _search = '';
  String? _subjectId;

  @override
  Widget build(BuildContext context) {
    final normalizedSearch = _search.trim().toLowerCase();
    final filtered = widget.questions.where((question) {
      final matchesSubject = _subjectId == null || question.subjectId == _subjectId;
      final matchesSearch = normalizedSearch.isEmpty || question.text.toLowerCase().contains(normalizedSearch) || question.subjectName.toLowerCase().contains(normalizedSearch);
      return matchesSubject && matchesSearch;
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Banco de preguntas', subtitle: '${widget.questions.length} preguntas disponibles', actionLabel: 'Nueva pregunta', onAction: widget.onCreate),
        const SizedBox(height: AppSpacing.lg),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.md, runSpacing: AppSpacing.md,
                children: [
                  SizedBox(width: 360, child: TextField(decoration: const InputDecoration(labelText: 'Buscar pregunta', prefixIcon: Icon(Icons.search_rounded)), onChanged: (value) => setState(() => _search = value))),
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _subjectId,
                      decoration: const InputDecoration(labelText: 'Materia'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Todas las materias')),
                        ...widget.subjects.map((subject) => DropdownMenuItem(value: subject.id, child: Text(subject.name))),
                      ],
                      onChanged: (value) => setState(() => _subjectId = value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1),
              if (filtered.isEmpty)
                const _EmptyState(icon: Icons.search_off_rounded, title: 'No encontramos preguntas', detail: 'Ajusta los filtros o crea una nueva pregunta.')
              else
                for (var index = 0; index < filtered.length; index++) ...[
                  _QuestionListTile(question: filtered[index], onEdit: () => widget.onEdit(filtered[index]), onDelete: () => widget.onDelete(filtered[index])),
                  if (index != filtered.length - 1) const Divider(height: 1),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _QuestionListTile extends StatelessWidget {
  const _QuestionListTile({required this.question, required this.onEdit, required this.onDelete});
  final QuestionModel question;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      leading: CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: .1), foregroundColor: AppColors.primary, child: Text('${question.options.length}')),
      title: Text(question.text),
      subtitle: Text('${question.subjectName} · ${question.difficulty.label} · ${question.options.length} opciones'),
      trailing: PopupMenuButton<String>(
        onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
        itemBuilder: (context) => const [PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'delete', child: Text('Eliminar'))],
      ),
    );
  }
}

class _SubjectsPanel extends StatelessWidget {
  const _SubjectsPanel({required this.isAdmin, required this.subjects, required this.onCreate, required this.onEdit, required this.onDelete});
  final bool isAdmin;
  final List<SubjectModel> subjects;
  final VoidCallback onCreate;
  final ValueChanged<SubjectModel> onEdit;
  final ValueChanged<SubjectModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Materias', subtitle: isAdmin ? 'Áreas de conocimiento disponibles para los quizzes.' : 'Consulta las materias configuradas por administración.', actionLabel: isAdmin ? 'Nueva materia' : null, onAction: isAdmin ? onCreate : null),
        const SizedBox(height: AppSpacing.lg),
        _Surface(
          child: subjects.isEmpty
              ? const _EmptyState(icon: Icons.category_outlined, title: 'No hay materias', detail: 'Crea una materia antes de agregar preguntas.')
              : Column(
                  children: [
                    for (var index = 0; index < subjects.length; index++) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.menu_book_outlined, size: 19)),
                        title: Text(subjects[index].name),
                        subtitle: Text(subjects[index].description?.trim().isNotEmpty == true ? subjects[index].description! : 'Sin descripción'),
                        trailing: isAdmin ? PopupMenuButton<String>(onSelected: (value) => value == 'edit' ? onEdit(subjects[index]) : onDelete(subjects[index]), itemBuilder: (context) => const [PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'delete', child: Text('Eliminar'))]) : null,
                      ),
                      if (index != subjects.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _StaffPanel extends StatelessWidget {
  const _StaffPanel({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Profesores', subtitle: 'Crea cuentas docentes para gestionar el banco de preguntas.', actionLabel: 'Crear profesor', actionIcon: Icons.person_add_alt_1_outlined, onAction: onCreate),
        const SizedBox(height: AppSpacing.lg),
        _Surface(
          child: Column(
            children: [
              const Icon(Icons.admin_panel_settings_outlined, size: 54, color: AppColors.primary),
              const SizedBox(height: AppSpacing.md),
              Text('Provisionamiento seguro', style: AppTypography.headline, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xs),
              const Text('La cuenta del profesor queda confirmada al crearla. Comparte las credenciales por un canal seguro y pídele cambiar la contraseña desde “Mi cuenta”.', textAlign: TextAlign.center, style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(onPressed: onCreate, icon: const Icon(Icons.person_add_alt_1_outlined), label: const Text('Crear primer profesor')),
              const SizedBox(height: AppSpacing.md),
              Text('El backend actual no expone un listado de usuarios; esta pantalla solo crea cuentas.', textAlign: TextAlign.center, style: AppTypography.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _SchoolsPanel extends StatelessWidget {
  const _SchoolsPanel({required this.schools, required this.onCreate, required this.onEdit, required this.onDelete});
  final List<SchoolModel> schools;
  final VoidCallback onCreate;
  final ValueChanged<SchoolModel> onEdit;
  final ValueChanged<SchoolModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Instituciones', subtitle: 'Colegios registrados en la plataforma.', actionLabel: 'Nueva institución', actionIcon: Icons.add_business_outlined, onAction: onCreate),
        const SizedBox(height: AppSpacing.lg),
        _Surface(
          child: schools.isEmpty
              ? const _EmptyState(icon: Icons.apartment_outlined, title: 'No hay instituciones', detail: 'Registra el primer colegio de la plataforma.')
              : Column(
                  children: [
                    for (var index = 0; index < schools.length; index++) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(child: Icon(Icons.apartment_outlined, size: 19)),
                        title: Text(schools[index].name),
                        subtitle: Text(schools[index].city?.trim().isNotEmpty == true ? schools[index].city! : 'Ciudad sin registrar'),
                        trailing: PopupMenuButton<String>(onSelected: (value) => value == 'edit' ? onEdit(schools[index]) : onDelete(schools[index]), itemBuilder: (context) => const [PopupMenuItem(value: 'edit', child: Text('Editar')), PopupMenuItem(value: 'delete', child: Text('Eliminar'))]),
                      ),
                      if (index != schools.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ReportsPanel extends StatefulWidget {
  const _ReportsPanel({required this.reportData});
  final ReportResponseModel? reportData;

  @override
  State<_ReportsPanel> createState() => _ReportsPanelState();
}

class _ReportsPanelState extends State<_ReportsPanel> {
  bool _sortAscending = false; 

  @override
  Widget build(BuildContext context) {
    final students = widget.reportData?.students ?? [];
    final institutionName = widget.reportData?.institutionName;

    final sortedReports = List<StudentReportModel>.from(students);
    sortedReports.sort((a, b) => _sortAscending
        ? a.scorePercentage.compareTo(b.scorePercentage)
        : b.scorePercentage.compareTo(a.scorePercentage));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(
          title: 'Rendimiento de Estudiantes',
          subtitle: institutionName != null 
              ? 'Institución: $institutionName · ${students.length} estudiantes'
              : '${students.length} estudiantes registrados',
        ),
        const SizedBox(height: AppSpacing.lg),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Listado general',
                    style: AppTypography.label.copyWith(fontSize: 16),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _sortAscending = !_sortAscending);
                    },
                    icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
                    label: Text(_sortAscending ? 'Menor a mayor %' : 'Mayor a menor %'),
                  ),
                ],
              ),
              const Divider(),
              if (students.isEmpty)
                const _EmptyState(
                  icon: Icons.analytics_outlined,
                  title: 'Sin datos de estudiantes',
                  detail: 'Aún no hay estudiantes registrados en tu institución o no han realizado prácticas.',
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.resolveWith((states) => AppColors.surfaceSecondary),
                    columns: const [
                      DataColumn(label: Text('Estudiante')),
                      DataColumn(label: Text('Correo')),
                      DataColumn(label: Text('Respondidas'), numeric: true),
                      DataColumn(label: Text('Correctas'), numeric: true),
                      DataColumn(label: Text('% Acierto')),
                    ],
                    rows: sortedReports.map((report) {
                      final scoreColor = report.scorePercentage >= 70
                          ? AppColors.success
                          : report.scorePercentage >= 40
                              ? AppColors.warning
                              : AppColors.error;

                      return DataRow(
                        cells: [
                          DataCell(Text(report.fullName, style: AppTypography.label)),
                          DataCell(Text(report.email, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary))),
                          DataCell(Text('${report.totalAnswered}')),
                          DataCell(Text('${report.correctAnswers}')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: scoreColor.withValues(alpha: .1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${report.scorePercentage}%',
                                style: AppTypography.label.copyWith(color: scoreColor),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InvitationCodesPanel extends StatelessWidget {
  const _InvitationCodesPanel({required this.codes, required this.onCreate, required this.onRevoke, required this.onDelete});
  final List<InvitationCodeModel> codes;
  final VoidCallback onCreate;
  final ValueChanged<InvitationCodeModel> onRevoke;
  final ValueChanged<InvitationCodeModel> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionHeader(title: 'Códigos de invitación', subtitle: '${codes.length} ${codes.length == 1 ? "código" : "códigos"} generados', actionLabel: 'Nuevo código', actionIcon: Icons.add_rounded, onAction: onCreate),
        const SizedBox(height: AppSpacing.lg),
        _Surface(
          child: codes.isEmpty
              ? const _EmptyState(icon: Icons.vpn_key_outlined, title: 'Aún no hay códigos', detail: 'Genera un código para invitar a estudiantes de una institución.')
              : Column(
                  children: [
                    for (var index = 0; index < codes.length; index++) ...[
                      _InvitationCodeTile(code: codes[index], onRevoke: () => onRevoke(codes[index]), onDelete: () => onDelete(codes[index])),
                      if (index != codes.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _InvitationCodeTile extends StatelessWidget {
  const _InvitationCodeTile({required this.code, required this.onRevoke, required this.onDelete});
  final InvitationCodeModel code;
  final VoidCallback onRevoke;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = !code.isActive ? AppColors.adminMuted : code.isUsable ? AppColors.success : AppColors.warning;
    final statusLabel = !code.isActive ? 'Revocado' : code.isUsable ? 'Activo' : 'No usable';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: .12),
        foregroundColor: statusColor,
        child: Icon(code.isActive ? Icons.vpn_key_outlined : Icons.lock_outline, size: 19),
      ),
      title: Row(
        children: [
          Expanded(child: Text(code.code, style: AppTypography.label.copyWith(letterSpacing: .5))),
          _StatusChip(label: statusLabel, color: statusColor),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(code.institutionName),
            const SizedBox(height: 2),
            Text(_subtitleFor(code), style: AppTypography.bodySmall),
          ],
        ),
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (value) { 
          if (value == 'revoke') {
            onRevoke();
          } else if (value == 'delete') {
            onDelete(); 
          }
        },
        itemBuilder: (context) => [
          if (code.isActive) const PopupMenuItem(value: 'revoke', child: Text('Revocar')),
          const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
        ],
      ),
    );
  }

  String _subtitleFor(InvitationCodeModel code) {
    final parts = <String>[code.usesLabel];
    if (code.expiresAtUtc != null) {
      final date = code.expiresAtUtc!.toLocal();
      parts.add('expira ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}');
    } else {
      parts.add('sin expiración');
    }
    return parts.join(' · ');
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: AppTypography.bodySmall.copyWith(color: color, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}

class _AccountPanel extends StatelessWidget {
  const _AccountPanel({required this.email, required this.roles, required this.onLogout});
  final String email;
  final List<String> roles;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: 'Mi cuenta', subtitle: 'Consulta tu sesión y protege el acceso a la plataforma.'),
        const SizedBox(height: AppSpacing.lg),
        _Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: AppColors.adminAvatar, child: Text(email.isEmpty ? 'A' : email[0].toUpperCase())),
                title: Text(email), subtitle: Text(roles.isEmpty ? 'Usuario' : roles.join(', ')),
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text('Cambiar contraseña', style: AppTypography.label.copyWith(fontSize: 15)),
              const SizedBox(height: AppSpacing.xs),
              const Text('Actualiza tu contraseña confirmando la actual. Se cerrarán las demás sesiones activas por seguridad.', style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(onPressed: () => context.pushNamed(AppRoutes.changePasswordName), icon: const Icon(Icons.lock_reset_rounded), label: const Text('Cambiar contraseña')),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Divider(),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(onPressed: onLogout, icon: const Icon(Icons.logout_rounded), label: const Text('Cerrar sesión')),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Icon(icon, size: 46, color: AppColors.adminMuted),
          const SizedBox(height: AppSpacing.sm),
          Text(title, style: AppTypography.label),
          const SizedBox(height: AppSpacing.xxs),
          Text(detail, textAlign: TextAlign.center, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}