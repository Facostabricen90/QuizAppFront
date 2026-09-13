import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../content/data/content_models.dart';
import '../../data/practice_models.dart';
import '../../data/practice_repository.dart';

class PracticeSessionPage extends StatefulWidget {
  const PracticeSessionPage({
    super.key,
    required this.apiClient,
    required this.subject,
    this.questionCount,
  });

  final ApiClient apiClient;
  final SubjectModel subject;
  final int? questionCount;

  @override
  State<PracticeSessionPage> createState() => _PracticeSessionPageState();
}

class _PracticeSessionPageState extends State<PracticeSessionPage> {
  late final PracticeRepository _repository;
  PracticeSessionModel? _session;
  PracticeSessionResultModel? _result;
  AnswerResultModel? _answerResult;
  String? _selectedOptionId;
  String? _errorMessage;
  int _currentIndex = 0;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _repository = PracticeRepository(widget.apiClient);
    _start();
  }

  String _messageFor(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is FormatException) {
      return error.message;
    }
    return 'No se pudo completar la práctica.';
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final session = await _repository.startSession(
        subjectId: widget.subject.id,
        questionCount: widget.questionCount,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _session = session;
        _loading = false;
        _currentIndex = 0;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = _messageFor(error);
      });
    }
  }

  Future<void> _submitAnswer() async {
    final session = _session;
    final optionId = _selectedOptionId;
    if (session == null || optionId == null || _submitting) {
      return;
    }
    final question = session.questions[_currentIndex];
    setState(() => _submitting = true);
    try {
      final result = await _repository.submitAnswer(
        sessionId: session.id,
        questionId: question.id,
        selectedOptionId: optionId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _answerResult = result;
        _submitting = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      _showError(_messageFor(error));
    }
  }

  Future<void> _continue() async {
    final session = _session;
    if (session == null || _answerResult == null || _submitting) {
      return;
    }
    if (_currentIndex < session.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionId = null;
        _answerResult = null;
      });
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await _repository.finishSession(session.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _submitting = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _submitting = false);
      _showError(_messageFor(error));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(widget.subject.name),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return _PracticeError(message: _errorMessage!, onRetry: _start);
    }
    if (_result != null) {
      return _ResultView(
        result: _result!,
        session: _session!,
        onFinish: () => Navigator.of(context).pop(true),
      );
    }
    final session = _session;
    if (session == null || session.questions.isEmpty) {
      return _PracticeError(
        message: 'No hay preguntas disponibles para esta materia.',
        onRetry: _start,
      );
    }
    final question = session.questions[_currentIndex];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProgressHeader(
                current: _currentIndex + 1,
                total: session.questions.length,
              ),
              const SizedBox(height: AppSpacing.lg),
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
                    Text(
                      'Pregunta ${_currentIndex + 1}',
                      style: AppTypography.label.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(question.text, style: AppTypography.headline),
                    const SizedBox(height: AppSpacing.lg),
                    for (
                      var index = 0;
                      index < question.options.length;
                      index++
                    ) ...[
                      _OptionTile(
                        letter: String.fromCharCode(65 + index),
                        option: question.options[index],
                        selected:
                            _selectedOptionId == question.options[index].id,
                        answerResult: _answerResult,
                        onTap: _answerResult == null
                            ? () => setState(
                                () => _selectedOptionId =
                                    question.options[index].id,
                              )
                            : null,
                      ),
                      if (index != question.options.length - 1)
                        const SizedBox(height: AppSpacing.sm),
                    ],
                    if (_answerResult != null) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _FeedbackCard(result: _answerResult!),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: _submitting
                          ? null
                          : _answerResult == null
                          ? _selectedOptionId == null
                                ? null
                                : _submitAnswer
                          : _continue,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _answerResult == null
                                  ? Icons.check_rounded
                                  : _currentIndex ==
                                        session.questions.length - 1
                                  ? Icons.flag_outlined
                                  : Icons.arrow_forward_rounded,
                            ),
                      label: Text(
                        _answerResult == null
                            ? 'Responder'
                            : _currentIndex == session.questions.length - 1
                            ? 'Finalizar práctica'
                            : 'Siguiente pregunta',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('Progreso', style: AppTypography.label)),
            Text('$current de $total', style: AppTypography.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: total == 0 ? 0 : current / total,
          minHeight: 8,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.option,
    required this.selected,
    required this.answerResult,
    required this.onTap,
  });

  final String letter;
  final PracticeQuestionOptionModel option;
  final bool selected;
  final AnswerResultModel? answerResult;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCorrect = answerResult?.correctOptionId == option.id;
    final isWrongSelection =
        answerResult != null && selected && !answerResult!.isCorrect;
    final color = isCorrect
        ? AppColors.success
        : isWrongSelection
        ? AppColors.error
        : selected
        ? AppColors.primary
        : AppColors.border;
    final background = isCorrect || isWrongSelection || selected
        ? color.withValues(alpha: .08)
        : AppColors.surface;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: color,
              width: selected || isCorrect ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: .12),
                foregroundColor: color == AppColors.border
                    ? AppColors.textSecondary
                    : color,
                child: Text(letter),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(option.text, style: AppTypography.bodyLarge),
              ),
              if (isCorrect)
                const Icon(Icons.check_circle_rounded, color: AppColors.success)
              else if (isWrongSelection)
                const Icon(Icons.cancel_rounded, color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.result});

  final AnswerResultModel result;

  @override
  Widget build(BuildContext context) {
    final color = result.isCorrect ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            result.isCorrect
                ? Icons.check_circle_outline_rounded
                : Icons.lightbulb_outline_rounded,
            color: color,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.isCorrect
                      ? '¡Respuesta correcta!'
                      : 'Sigue aprendiendo',
                  style: AppTypography.label.copyWith(color: color),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(result.justification, style: AppTypography.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.result,
    required this.session,
    required this.onFinish,
  });

  final PracticeSessionResultModel result;
  final PracticeSessionModel session;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events_outlined,
                      size: 60,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Text(
                      'Práctica completada',
                      style: AppTypography.displayMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      '${result.scorePercentage.toStringAsFixed(0)}%',
                      style: AppTypography.displayLarge.copyWith(
                        color: AppColors.primary,
                        fontSize: 54,
                      ),
                    ),
                    Text(
                      '${result.correctAnswers} de ${result.totalQuestions} respuestas correctas',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: onFinish,
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Volver al inicio'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Revisión', style: AppTypography.headline),
              const SizedBox(height: AppSpacing.md),
              for (var index = 0; index < result.answers.length; index++) ...[
                _ReviewCard(
                  index: index,
                  review: result.answers[index],
                  session: session,
                ),
                if (index != result.answers.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.index,
    required this.review,
    required this.session,
  });

  final int index;
  final AnswerReviewModel review;
  final PracticeSessionModel session;

  String _optionText(String? id) {
    final question = session.questions.firstWhere(
      (item) => item.id == review.questionId,
      orElse: () => const PracticeQuestionModel(
        id: '',
        text: '',
        options: [],
        answered: false,
      ),
    );
    for (final option in question.options) {
      if (option.id == id) {
        return option.text;
      }
    }
    return 'Sin respuesta';
  }

  @override
  Widget build(BuildContext context) {
    final color = review.isCorrect ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                review.isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: color,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  '${index + 1}. ${review.questionText}',
                  style: AppTypography.label,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tu respuesta: ${_optionText(review.selectedOptionId)}',
            style: AppTypography.bodyMedium,
          ),
          if (!review.isCorrect)
            Text(
              'Respuesta correcta: ${_optionText(review.correctOptionId)}',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.success,
              ),
            ),
          const SizedBox(height: AppSpacing.xs),
          Text(review.justification, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}

class _PracticeError extends StatelessWidget {
  const _PracticeError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sentiment_dissatisfied_outlined,
              size: 58,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Intentar de nuevo'),
            ),
          ],
        ),
      ),
    );
  }
}
