import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../content/data/content_models.dart';

class StaffDraft {
  const StaffDraft({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String password;
}

class SubjectDraft {
  const SubjectDraft({required this.name, this.description});

  final String name;
  final String? description;
}

class SchoolDraft {
  const SchoolDraft({required this.name, this.city});

  final String name;
  final String? city;
}

Future<StaffDraft?> showStaffDialog(BuildContext context) {
  return showDialog<StaffDraft>(
    context: context,
    builder: (context) => const _StaffDialog(),
  );
}

Future<SubjectDraft?> showSubjectDialog(
  BuildContext context, {
  SubjectModel? subject,
}) {
  return showDialog<SubjectDraft>(
    context: context,
    builder: (context) => _SubjectDialog(subject: subject),
  );
}

Future<SchoolDraft?> showSchoolDialog(
  BuildContext context, {
  SchoolModel? school,
}) {
  return showDialog<SchoolDraft>(
    context: context,
    builder: (context) => _SchoolDialog(school: school),
  );
}

Future<QuestionDraft?> showQuestionDialog(
  BuildContext context, {
  required List<SubjectModel> subjects,
  QuestionModel? question,
}) {
  return showDialog<QuestionDraft>(
    context: context,
    builder: (context) =>
        _QuestionDialog(subjects: subjects, question: question),
  );
}

class _DialogFrame extends StatelessWidget {
  const _DialogFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppTypography.headline),
              const SizedBox(height: AppSpacing.xxs),
              Text(subtitle, style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions({required this.submitLabel, required this.onSubmit});

  final String submitLabel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: onSubmit, child: Text(submitLabel)),
      ],
    );
  }
}

class _StaffDialog extends StatefulWidget {
  const _StaffDialog();

  @override
  State<_StaffDialog> createState() => _StaffDialogState();
}

class _StaffDialogState extends State<_StaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _hidePassword = true;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      StaffDraft(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      ),
    );
  }

  String? _required(String? value, String label) {
    return value == null || value.trim().isEmpty ? 'Ingresa $label.' : null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Ingresa el correo del profesor.';
    }
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
        ? null
        : 'Ingresa un correo válido.';
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) {
      return 'Usa al menos 8 caracteres.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password)) {
      return 'Incluye mayúscula, minúscula y número.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _DialogFrame(
      title: 'Crear profesor',
      subtitle: 'La cuenta quedará confirmada y podrá ingresar inmediatamente.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ResponsiveFields(
              children: [
                TextFormField(
                  controller: _firstName,
                  decoration: const InputDecoration(labelText: 'Nombres'),
                  validator: (value) => _required(value, 'los nombres'),
                ),
                TextFormField(
                  controller: _lastName,
                  decoration: const InputDecoration(labelText: 'Apellidos'),
                  validator: (value) => _required(value, 'los apellidos'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: _validateEmail,
            ),
            const SizedBox(height: AppSpacing.md),
            _ResponsiveFields(
              children: [
                TextFormField(
                  controller: _password,
                  obscureText: _hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña temporal',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                TextFormField(
                  controller: _confirmPassword,
                  obscureText: _hidePassword,
                  decoration: const InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  validator: (value) => value == _password.text
                      ? null
                      : 'Las contraseñas no coinciden.',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _DialogActions(submitLabel: 'Crear profesor', onSubmit: _submit),
          ],
        ),
      ),
    );
  }
}

class _SubjectDialog extends StatefulWidget {
  const _SubjectDialog({this.subject});

  final SubjectModel? subject;

  @override
  State<_SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<_SubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.subject?.name);
    _description = TextEditingController(text: widget.subject?.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      SubjectDraft(
        name: _name.text.trim(),
        description: _description.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.subject != null;
    return _DialogFrame(
      title: editing ? 'Editar materia' : 'Nueva materia',
      subtitle: 'Organiza el banco de preguntas por área de conocimiento.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre'),
              maxLength: 150,
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa el nombre de la materia.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Descripción'),
              minLines: 2,
              maxLines: 4,
              maxLength: 500,
            ),
            const SizedBox(height: AppSpacing.lg),
            _DialogActions(
              submitLabel: editing ? 'Guardar cambios' : 'Crear materia',
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _SchoolDialog extends StatefulWidget {
  const _SchoolDialog({this.school});

  final SchoolModel? school;

  @override
  State<_SchoolDialog> createState() => _SchoolDialogState();
}

class _SchoolDialogState extends State<_SchoolDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _city;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.school?.name);
    _city = TextEditingController(text: widget.school?.city);
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(
      context,
    ).pop(SchoolDraft(name: _name.text.trim(), city: _city.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.school != null;
    return _DialogFrame(
      title: editing ? 'Editar institución' : 'Nueva institución',
      subtitle: 'Registra los colegios que harán parte de la plataforma.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _name,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Nombre de la institución',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa el nombre de la institución.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _city,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Ciudad'),
            ),
            const SizedBox(height: AppSpacing.lg),
            _DialogActions(
              submitLabel: editing ? 'Guardar cambios' : 'Crear institución',
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionDialog extends StatefulWidget {
  const _QuestionDialog({required this.subjects, this.question});

  final List<SubjectModel> subjects;
  final QuestionModel? question;

  @override
  State<_QuestionDialog> createState() => _QuestionDialogState();
}

class _QuestionDialogState extends State<_QuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _text;
  late final TextEditingController _justification;
  late final List<TextEditingController> _options;
  late String _subjectId;
  late QuestionDifficulty _difficulty;
  late int _correctIndex;

  @override
  void initState() {
    super.initState();
    final question = widget.question;
    _text = TextEditingController(text: question?.text);
    _justification = TextEditingController(text: question?.justification);
    _subjectId = question?.subjectId ?? widget.subjects.first.id;
    _difficulty = question?.difficulty ?? QuestionDifficulty.medium;
    final existingOptions = question?.options ?? const [];
    _options = existingOptions
        .map((option) => TextEditingController(text: option.text))
        .toList();
    while (_options.length < 4) {
      _options.add(TextEditingController());
    }
    final existingCorrect = existingOptions.indexWhere(
      (option) => option.isCorrect,
    );
    _correctIndex = existingCorrect < 0 ? 0 : existingCorrect;
  }

  @override
  void dispose() {
    _text.dispose();
    _justification.dispose();
    for (final controller in _options) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_options.length >= 6) {
      return;
    }
    setState(() => _options.add(TextEditingController()));
  }

  void _removeOption(int index) {
    if (_options.length <= 2) {
      return;
    }
    final removed = _options.removeAt(index);
    removed.dispose();
    if (_correctIndex == index) {
      _correctIndex = 0;
    } else if (_correctIndex > index) {
      _correctIndex--;
    }
    setState(() {});
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    Navigator.of(context).pop(
      QuestionDraft(
        text: _text.text.trim(),
        justification: _justification.text.trim(),
        difficulty: _difficulty,
        subjectId: _subjectId,
        options: [
          for (var index = 0; index < _options.length; index++)
            QuestionOptionDraft(
              text: _options[index].text.trim(),
              isCorrect: index == _correctIndex,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.question != null;
    return _DialogFrame(
      title: editing ? 'Editar pregunta' : 'Nueva pregunta',
      subtitle:
          'Define el enunciado, las opciones y la explicación que verá el estudiante.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _text,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Enunciado de la pregunta',
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Escribe el enunciado.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _ResponsiveFields(
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _subjectId,
                  decoration: const InputDecoration(labelText: 'Materia'),
                  items: widget.subjects
                      .map(
                        (subject) => DropdownMenuItem(
                          value: subject.id,
                          child: Text(
                            subject.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _subjectId = value);
                    }
                  },
                ),
                DropdownButtonFormField<QuestionDifficulty>(
                  initialValue: _difficulty,
                  decoration: const InputDecoration(labelText: 'Dificultad'),
                  items: QuestionDifficulty.values
                      .map(
                        (difficulty) => DropdownMenuItem(
                          value: difficulty,
                          child: Text(difficulty.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _difficulty = value);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _justification,
              minLines: 2,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Justificación de la respuesta',
                helperText: 'Se mostrará después de responder.',
                alignLabelWithHint: true,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Explica por qué la respuesta es correcta.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Opciones de respuesta',
                    style: AppTypography.label,
                  ),
                ),
                TextButton.icon(
                  onPressed: _options.length >= 6 ? null : _addOption,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Agregar opción'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var index = 0; index < _options.length; index++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: CircleAvatar(
                      radius: 14,
                      child: Text(String.fromCharCode(65 + index)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextFormField(
                      controller: _options[index],
                      decoration: InputDecoration(
                        labelText: 'Opción ${String.fromCharCode(65 + index)}',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Escribe esta opción.'
                          : null,
                    ),
                  ),
                  if (_options.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: IconButton(
                        tooltip: 'Eliminar opción',
                        onPressed: () => _removeOption(index),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            DropdownButtonFormField<int>(
              initialValue: _correctIndex,
              decoration: const InputDecoration(
                labelText: 'Respuesta correcta',
                prefixIcon: Icon(Icons.check_circle_outline),
              ),
              items: [
                for (var index = 0; index < _options.length; index++)
                  DropdownMenuItem(
                    value: index,
                    child: Text('Opción ${String.fromCharCode(65 + index)}'),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _correctIndex = value);
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _DialogActions(
              submitLabel: editing ? 'Guardar cambios' : 'Crear pregunta',
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1)
                const SizedBox(width: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}
