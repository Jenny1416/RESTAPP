import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/utils/app_toast.dart';

import '../models/onboarding_models.dart';
import '../services/onboarding_service.dart';

class OnboardingSurveyScreen extends StatefulWidget {
  const OnboardingSurveyScreen({super.key});

  @override
  State<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends State<OnboardingSurveyScreen> {
  final OnboardingService _service = OnboardingService();
  final Map<String, int> _answers = {};
  OnboardingSurvey? _survey;
  String? _error;
  bool _loading = true;
  bool _submitting = false;
  bool _completed = false;
  int _index = 0;

  static const _scoreLabels = <int, String>{
    0: 'Muy mal',
    1: 'Mal',
    2: 'Normal',
    3: 'Bien',
    4: 'Excelente',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final survey = await _service.getPreguntas();
      if (!mounted) return;
      setState(() {
        _survey = survey;
        _completed = survey.completado;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _next() async {
    final questions = _survey?.preguntas ?? const <OnboardingQuestion>[];
    if (questions.isEmpty) return;
    final question = questions[_index];
    if (!_answers.containsKey(question.id)) {
      AppToast.warning(context, 'Selecciona una respuesta para continuar.');
      return;
    }
    if (_index < questions.length - 1) {
      setState(() => _index++);
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    final questions = _survey?.preguntas ?? const <OnboardingQuestion>[];
    if (_answers.length != questions.length) {
      AppToast.warning(context, 'Responde todas las preguntas.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _service.enviarRespuestas(_answers);
      if (mounted) setState(() => _completed = true);
    } on OnboardingAlreadyCompletedException {
      if (mounted) setState(() => _completed = true);
    } catch (error) {
      if (mounted) AppToast.error(context, error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Encuesta inicial')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Reintentar')),
              ],
            ),
          ),
        ),
      );
    }
    if (_completed) {
      return _CompletedView(onContinue: () => Navigator.pop(context, true));
    }

    final survey = _survey!;
    final question = survey.preguntas[_index];
    final progress = (_index + 1) / survey.preguntas.length;
    return Scaffold(
      appBar: AppBar(title: Text(survey.titulo)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pregunta ${_index + 1} de ${survey.preguntas.length}'),
                  SizedBox(height: 8.h),
                  LinearProgressIndicator(value: progress, minHeight: 7.h),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryChip(category: question.categoria),
                      SizedBox(height: 20.h),
                      Text(
                        question.texto,
                        style: TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      ..._scoreLabels.entries.map((entry) {
                        final selected = _answers[question.id] == entry.key;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16.r),
                            onTap: () => setState(
                              () => _answers[question.id] = entry.key,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16.r),
                                color: selected
                                    ? const Color(0xFF3973D1)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerLow,
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF3973D1)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.outlineVariant,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 15.r,
                                    backgroundColor: selected
                                        ? Colors.white
                                        : const Color(
                                            0xFF3973D1,
                                          ).withValues(alpha: 0.12),
                                    child: Text(
                                      '${entry.key}',
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xFF3973D1)
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 14.w),
                                  Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
              child: Row(
                children: [
                  if (_index > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(() => _index--),
                        child: const Text('Anterior'),
                      ),
                    ),
                  if (_index > 0) SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submitting ? null : _next,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _index == survey.preguntas.length - 1
                                  ? 'Finalizar'
                                  : 'Siguiente',
                            ),
                    ),
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

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.psychology_alt_outlined, size: 18),
      label: Text(_dimensionLabel(category)),
      backgroundColor: const Color(0xFF5CCFC0).withValues(alpha: 0.15),
    );
  }
}

class _CompletedView extends StatelessWidget {
  final VoidCallback onContinue;

  const _CompletedView({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 110,
                  color: Color(0xFF20A779),
                ),
                const SizedBox(height: 24),
                const Text(
                  '¡Encuesta completada!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tu línea base de bienestar quedó guardada. Esto ayudará a personalizar el acompañamiento de NOA.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continuar a la app'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _dimensionLabel(String value) {
  const labels = {
    'ansiedad': 'Ansiedad',
    'estres_academico': 'Estrés académico',
    'humor_depresivo': 'Estado de ánimo',
    'sueno': 'Sueño',
    'relaciones_sociales': 'Relaciones sociales',
    'autoestima_autocuidado': 'Autoestima y autocuidado',
    'energia_motivacion': 'Energía y motivación',
  };
  return labels[value] ?? value.replaceAll('_', ' ');
}
