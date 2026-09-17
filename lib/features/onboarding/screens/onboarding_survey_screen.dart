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

  static const _scoreIcons = <int, IconData>{
    0: Icons.sentiment_very_dissatisfied_rounded,
    1: Icons.sentiment_dissatisfied_rounded,
    2: Icons.sentiment_neutral_rounded,
    3: Icons.sentiment_satisfied_rounded,
    4: Icons.sentiment_very_satisfied_rounded,
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
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.brightness == Brightness.dark
          ? colors.surface
          : const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Tu línea base',
          style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _CategoryChip(category: question.categoria),
                          const Spacer(),
                          Text(
                            '${_index + 1}/${survey.preguntas.length}',
                            style: const TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF326FB6),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8.h,
                          color: const Color(0xFF326FB6),
                          backgroundColor: const Color(0xFFDCE7F7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 18.h),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RESPONDE CON SINCERIDAD',
                          style: TextStyle(
                            fontSize: 11.sp,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF71819B),
                          ),
                        ),
                        SizedBox(height: 9.h),
                        Text(
                          question.texto,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 25.sp,
                            fontWeight: FontWeight.bold,
                            height: 1.18,
                            color: colors.onSurface,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Elige la opción que mejor refleje cómo te has sentido.',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 20.h),
                        ..._scoreLabels.entries.map((entry) {
                          final selected = _answers[question.id] == entry.key;
                          final scoreColor = _scoreColor(entry.key);
                          return Padding(
                            padding: EdgeInsets.only(bottom: 10.h),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16.r),
                              onTap: () => setState(
                                () => _answers[question.id] = entry.key,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 14.h,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  color: selected
                                      ? scoreColor.withValues(alpha: 0.14)
                                      : colors.surface,
                                  border: Border.all(
                                    color: selected
                                        ? scoreColor
                                        : colors.outlineVariant,
                                    width: selected ? 2 : 1,
                                  ),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: scoreColor.withValues(
                                              alpha: 0.12,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 5),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42.w,
                                      height: 42.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: scoreColor.withValues(
                                          alpha: 0.14,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        _scoreIcons[entry.key],
                                        color: scoreColor,
                                        size: 25.sp,
                                      ),
                                    ),
                                    SizedBox(width: 14.w),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w700,
                                          color: colors.onSurface,
                                        ),
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      width: 24.w,
                                      height: 24.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: selected
                                            ? scoreColor
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: selected
                                              ? scoreColor
                                              : colors.outline,
                                        ),
                                      ),
                                      child: selected
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
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
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
              decoration: BoxDecoration(
                color: colors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Row(
                    children: [
                      if (_index > 0)
                        SizedBox(
                          height: 52.h,
                          child: OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () => setState(() => _index--),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: const Icon(Icons.arrow_back_rounded),
                          ),
                        ),
                      if (_index > 0) SizedBox(width: 12.w),
                      Expanded(
                        child: SizedBox(
                          height: 52.h,
                          child: FilledButton(
                            onPressed: _submitting ? null : _next,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF326FB6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _index == survey.preguntas.length - 1
                                            ? 'Guardar y finalizar'
                                            : 'Continuar',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(int score) {
    return switch (score) {
      0 => const Color(0xFFE45B68),
      1 => const Color(0xFFE88749),
      2 => const Color(0xFFD5A521),
      3 => const Color(0xFF3BAF91),
      _ => const Color(0xFF278BC4),
    };
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F7F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.psychology_alt_outlined,
            size: 17,
            color: Color(0xFF167E76),
          ),
          const SizedBox(width: 5),
          Text(
            _dimensionLabel(category),
            style: const TextStyle(
              color: Color(0xFF167E76),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  final VoidCallback onContinue;

  const _CompletedView({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.brightness == Brightness.dark
          ? colors.surface
          : const Color(0xFFF5F7FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF27B39A), Color(0xFF278BC4)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF278BC4,
                          ).withValues(alpha: 0.22),
                          blurRadius: 26,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.2),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.favorite_rounded,
                            size: 54,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          '¡Excelente trabajo!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Fredoka',
                            fontSize: 29,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tu línea base de bienestar quedó guardada correctamente.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            height: 1.4,
                            color: Colors.white.withValues(alpha: 0.92),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2D6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.traffic_rounded,
                            color: Color(0xFFE28A18),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Siguiente paso: semáforo emocional',
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Si aún no hiciste tu registro de hoy, responderás una evaluación breve para generar tu semáforo.',
                                style: TextStyle(
                                  height: 1.35,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton.icon(
                      onPressed: onContinue,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF326FB6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text(
                        'Continuar al siguiente paso',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
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
