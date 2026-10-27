import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../../../content/data/content_models.dart';
import '../../../content/data/content_repository.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late final ContentRepository _repository;
  SubscriptionModel? _subscription;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = ContentRepository(widget.apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final subscription = await _repository.getMySubscription();
      if (!mounted) return;
      setState(() {
        _subscription = subscription;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'No se pudo cargar tu suscripción.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi suscripción'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: _buildContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 120),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _MessageCard(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.error,
        title: 'Algo salió mal',
        message: _errorMessage!,
      );
    }

    final subscription = _subscription;

    if (subscription == null) {
      return _MessageCard(
        icon: Icons.rocket_launch_outlined,
        iconColor: AppColors.primary,
        title: 'Aún no tienes un plan',
        message:
            'Elige un plan para desbloquear simulacros ilimitados y acceder a todo el contenido.',
        actionLabel: 'Ver planes disponibles',
        onAction: () => context.pushNamed(AppRoutes.plansName),
      );
    }

    return _SubscriptionDetails(subscription: subscription);
  }
}

class _SubscriptionDetails extends StatelessWidget {
  const _SubscriptionDetails({required this.subscription});

  final SubscriptionModel subscription;

  @override
  Widget build(BuildContext context) {
    final statusColor = subscription.isCurrentlyActive
        ? AppColors.success
        : subscription.isExpired
            ? AppColors.warning
            : AppColors.adminMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: statusColor.withValues(alpha: .3)),
          ),
          child: Column(
            children: [
              Icon(
                subscription.isCurrentlyActive
                    ? Icons.check_circle_rounded
                    : Icons.hourglass_empty_rounded,
                color: statusColor,
                size: 48,
              ),
              AppGap.h12,
              Text(
                subscription.planName,
                style: AppTypography.headline,
                textAlign: TextAlign.center,
              ),
              AppGap.h4,
              Text(
                subscription.isCurrentlyActive
                    ? subscription.remainingLabel
                    : subscription.statusLabel,
                style: AppTypography.bodyMedium.copyWith(color: statusColor),
              ),
            ],
          ),
        ),
        AppGap.h24,
        _DetailCard(
          rows: [
            _DetailRow(label: 'Plan', value: subscription.planCode),
            _DetailRow(label: 'Estado', value: subscription.statusLabel),
            _DetailRow(
              label: 'Inicio',
              value: _formatDate(subscription.startedAtUtc),
            ),
            _DetailRow(
              label: 'Vence',
              value: _formatDate(subscription.expiresAtUtc),
            ),
            _DetailRow(
              label: 'Tipo',
              value: subscription.isInstitutional
                  ? 'Institucional'
                  : 'Particular',
            ),
            if (subscription.isInstitutional &&
                subscription.institutionName != null)
              _DetailRow(
                label: 'Institución',
                value: subscription.institutionName!,
              ),
            _DetailRow(
              label: 'Renovación automática',
              value: subscription.autoRenew ? 'Sí' : 'No',
            ),
          ],
        ),
        AppGap.h24,
        if (subscription.isCurrentlyActive &&
            subscription.isParticular &&
            subscription.planCode == 'FREE') ...[
          FilledButton.icon(
            onPressed: () => context.pushNamed(AppRoutes.plansName),
            icon: const Icon(Icons.upgrade_rounded),
            label: const Text('Mejorar plan'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
          AppGap.h12,
        ],
        if (!subscription.isCurrentlyActive && subscription.isParticular) ...[
          FilledButton.icon(
            onPressed: () => context.pushNamed(AppRoutes.plansName),
            icon: const Icon(Icons.rocket_launch_outlined),
            label: const Text('Reactivar con un plan'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
          AppGap.h12,
        ],
        if (subscription.isInstitutional) ...[
          Text(
            'Tu acceso es gestionado por tu institución. '
            'Si tu licencia expira, contacta al administrador del colegio.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ],
      ],
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.rows});

  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].value,
                    style: AppTypography.label.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            if (i != rows.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _DetailRow {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          Icon(icon, color: iconColor, size: 56),
          AppGap.h16,
          Text(title,
              textAlign: TextAlign.center, style: AppTypography.headline),
          AppGap.h8,
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium,
          ),
          if (actionLabel != null && onAction != null) ...[
            AppGap.h24,
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}