import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/presentation/widgets/app_gap.dart';
import '../../../../shared/presentation/widgets/app_logo.dart';
import '../../../content/data/content_models.dart';
import '../../../content/data/content_repository.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  late final ContentRepository _repository;
  List<PlanModel> _plans = const [];
  SubscriptionModel? _currentSubscription;
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
      final plans = await _repository.getPlans(target: 'Particular');
      SubscriptionModel? subscription;
      try {
        subscription = await _repository.getMySubscription();
      } catch (_) {
        // Silencioso
      }

      // Regla de negocio: el trial FREE es único por usuario.
      // Si ya tuvo uno (activo o expirado), ocultamos ese plan.
      final visiblePlans = plans.where((plan) {
        if (plan.code == 'FREE' &&
            subscription != null &&
            subscription.planCode == 'FREE') {
          return false;
        }
        return true;
      }).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _plans = visiblePlans;
        _currentSubscription = subscription;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'No se pudieron cargar los planes.';
      });
    }
  }

  void _selectPlan(PlanModel plan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Próximamente podrás suscribirte al ${plan.name}. '
            'La pasarela de pagos estará disponible en los próximos días.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Planes disponibles'),
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
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AppLogo(size: 64, showText: false),
                    AppGap.h24,
                    Text(
                      'Elige tu plan',
                      textAlign: TextAlign.center,
                      style: AppTypography.displayMedium,
                    ),
                    AppGap.h8,
                    Text(
                      'Accede a simulacros ilimitados, banco de preguntas completo y análisis de tu progreso.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium,
                    ),
                    AppGap.h32,

                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_errorMessage != null)
                      _ErrorBox(message: _errorMessage!)
                    else ...[
                      if (_currentSubscription != null &&
                          _currentSubscription!.isCurrentlyActive) ...[
                        _CurrentSubscriptionBanner(
                          subscription: _currentSubscription!,
                        ),
                        AppGap.h24,
                      ],
                      _PlansGrid(
                        plans: _plans,
                        currentPlanId:
                            _currentSubscription?.isCurrentlyActive == true
                                ? _currentSubscription!.planId
                                : null,
                        onSelect: _selectPlan,
                      ),
                    ],
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

class _PlansGrid extends StatelessWidget {
  const _PlansGrid({
    required this.plans,
    required this.currentPlanId,
    required this.onSelect,
  });

  final List<PlanModel> plans;
  final String? currentPlanId;
  final ValueChanged<PlanModel> onSelect;

  @override
  Widget build(BuildContext context) {
    if (plans.isEmpty) {
      return const _ErrorBox(message: 'No hay planes disponibles por ahora.');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        // Columnas máximas según ancho de pantalla
        final maxColumns = width >= 1024
            ? 3
            : width >= 720
                ? 2
                : 1;

        // Si hay menos planes que columnas, ajustamos para aprovechar el espacio
        final effectiveColumns =
            plans.length < maxColumns ? plans.length : maxColumns;

        final spacing = AppSpacing.lg;
        final totalSpacing = spacing * (effectiveColumns - 1);
        final itemWidth = (width - totalSpacing) / effectiveColumns;

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final plan in plans)
              SizedBox(
                width: itemWidth,
                child: _PlanCard(
                  plan: plan,
                  isCurrent: currentPlanId == plan.id,
                  onSelect: () => onSelect(plan),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.onSelect,
  });

  final PlanModel plan;
  final bool isCurrent;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = plan.code == 'SEMESTRAL';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isHighlighted ? AppColors.primary : AppColors.border,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isHighlighted) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'MÁS POPULAR',
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 0.5,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      AppGap.h8,
                    ],
                    Text(plan.name, style: AppTypography.headline),
                  ],
                ),
              ),
            ],
          ),
          AppGap.h16,
          Text(
            plan.priceLabel,
            style: AppTypography.headline.copyWith(
              color: AppColors.primary,
              fontSize: 28,
            ),
          ),
          AppGap.h4,
          Text(plan.durationLabel, style: AppTypography.bodySmall),

          if (plan.description != null) ...[
            AppGap.h12,
            Text(
              plan.description!,
              style: AppTypography.bodyMedium,
            ),
          ],

          AppGap.h16,
          const Divider(),
          AppGap.h16,

          _PlanFeatures(plan: plan),

          AppGap.h24,

          FilledButton(
            onPressed: isCurrent ? null : onSelect,
            style: FilledButton.styleFrom(
              backgroundColor:
                  isHighlighted ? AppColors.primary : AppColors.primaryLight,
              minimumSize: const Size.fromHeight(46),
            ),
            child: Text(isCurrent ? 'Plan actual' : 'Elegir plan'),
          ),
        ],
      ),
    );
  }
}

class _PlanFeatures extends StatelessWidget {
  const _PlanFeatures({required this.plan});

  final PlanModel plan;

  @override
  Widget build(BuildContext context) {
    final features = <String>[
      'Acceso a las 5 materias del ICFES',
      'Banco completo de preguntas',
      'Simulacros cronometrados',
      'Historial de resultados',
      if (plan.code == 'SEMESTRAL' || plan.code == 'INSTITUTIONAL')
        'Analítica avanzada de tu progreso',
      if (plan.code == 'INSTITUTIONAL')
        'Cuentas para hasta 200 estudiantes',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final feature in features)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(feature, style: AppTypography.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CurrentSubscriptionBanner extends StatelessWidget {
  const _CurrentSubscriptionBanner({required this.subscription});

  final SubscriptionModel subscription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: .3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tienes el plan ${subscription.planName} activo',
                  style: AppTypography.label,
                ),
                Text(subscription.remainingLabel,
                    style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.error.withValues(alpha: .2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 40),
          AppGap.h12,
          Text(message,
              textAlign: TextAlign.center, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}