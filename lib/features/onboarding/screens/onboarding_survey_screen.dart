import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:rest/core/theme/app_colors.dart';
import 'package:rest/core/utils/app_toast.dart';

import '../models/onboarding_models.dart';
import '../services/onboarding_service.dart';
import '../widgets/onboarding_visuals.dart';

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
      if (mounted) setState(() => _loading = false);
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

  void _goBack() {
    if (_index == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _index--);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: OnboardingBackdrop(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      return _SurveyError(message: _error!, onRetry: _load);
    }
    if (_completed) {
      return _CompletedView(onContinue: () => Navigator.pop(context, true));
    }

    final survey = _survey!;
    final question = survey.preguntas[_index];
    final progress = (_index + 1) / survey.preguntas.length;
    final percentage = (progress * 100).round();
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: OnboardingBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 10.h),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Row(
                    children: [
                      _SurveyBackButton(onTap: _goBack),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pregunta ${_index + 1} de ${survey.preguntas.length}',
                              style: GoogleFonts.fredoka(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 7.h,
                                backgroundColor: appColors.progressTrackCool,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  appColors.accentBlue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 11.w,
                          vertical: 7.h,
                        ),
                        decoration: BoxDecoration(
                          color: appColors.accentBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$percentage%',
                          style: GoogleFonts.fredoka(
                            color: appColors.accentBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.035, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey(question.id),
                    padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20.w),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(26.r),
                            border: Border.all(
                              color: appColors.accentBlue.withValues(alpha: 0.12),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: appColors.accentBlue.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _CategoryChip(category: question.categoria),
                                  const Spacer(),
                                  Image.asset(
                                    'assets/images/NoaBase.png',
                                    width: 48.w,
                                    height: 48.w,
                                  ),
                                ],
                              ),
                              SizedBox(height: 13.h),
                              Text(
                                question.texto,
                                style: GoogleFonts.fredoka(
                                  fontSize: 25.sp,
                                  fontWeight: FontWeight.bold,
                                  height: 1.18,
                                  color: colors.onSurface,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Elige la opción que mejor describa cómo te has sentido.',
                                style: GoogleFonts.fredoka(
                                  fontSize: 13.sp,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              SizedBox(height: 20.h),
                              for (final entry in _scoreLabels.entries)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 10.h),
                                  child: _ScoreOption(
                                    score: entry.key,
                                    label: entry.value,
                                    icon: _scoreIcons[entry.key]!,
                                    selected:
                                        _answers[question.id] == entry.key,
                                    onTap: () => setState(
                                      () => _answers[question.id] = entry.key,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 16.h),
                decoration: BoxDecoration(
                  color: colors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: OnboardingPrimaryButton(
                      label: _index == survey.preguntas.length - 1
                          ? 'Guardar y finalizar'
                          : 'Continuar',
                      onPressed: _submitting ? null : _next,
                      loading: _submitting,
                      icon: _index == survey.preguntas.length - 1
                          ? Icons.check_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SurveyBackButton extends StatelessWidget {
  const _SurveyBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13.r),
      child: Ink(
        width: 42.w,
        height: 42.w,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(13.r),
          border: Border.all(
            color: context.appColors.accentBlue.withValues(alpha: 0.14),
          ),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: context.appColors.accentBlue,
          size: 18,
        ),
      ),
    );
  }
}

class _ScoreOption extends StatelessWidget {
  const _ScoreOption({
    required this.score,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final int score;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final scoreColor = _scoreColor(context, score);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: selected
              ? scoreColor.withValues(alpha: 0.1)
              : colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(17.r),
          border: Border.all(
            color: selected
                ? scoreColor
                : colors.outlineVariant.withValues(alpha: 0.8),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 43.w,
              height: 43.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scoreColor.withValues(alpha: selected ? 0.18 : 0.1),
              ),
              child: Icon(icon, color: scoreColor, size: 25.sp),
            ),
            SizedBox(width: 13.w),
            Container(
              width: 26.w,
              height: 26.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? scoreColor : colors.surfaceContainerHighest,
              ),
              child: Text(
                '$score',
                style: GoogleFonts.fredoka(
                  color: selected
                      ? context.appColors.overlayOnGradient
                      : colors.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.fredoka(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? scoreColor : colors.outline,
              size: 23.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.appColors.infoBadgeBg,
            context.appColors.heroGradientLavenderStart,
          ],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology_alt_outlined,
            size: 18,
            color: context.appColors.brandBorder,
          ),
          SizedBox(width: 6.w),
          Text(
            _dimensionLabel(category),
            style: GoogleFonts.fredoka(
              color: context.appColors.brandBorder,
              fontWeight: FontWeight.w700,
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedView extends StatelessWidget {
  const _CompletedView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return Scaffold(
      backgroundColor: colors.surface,
      body: OnboardingBackdrop(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(22.w),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(24.w, 30.h, 24.w, 24.h),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: appColors.accentPurple.withValues(alpha: 0.12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: appColors.accentPurple.withValues(alpha: 0.12),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const OnboardingNoaBadge(completed: true, size: 150),
                      SizedBox(height: 24.h),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [appColors.accentBlue, appColors.accentPurple],
                        ).createShader(bounds),
                        child: Text(
                          '¡Excelente trabajo!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 29.sp,
                            fontWeight: FontWeight.bold,
                            color: appColors.overlayOnGradient,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        'Tu línea base de bienestar quedó guardada. NOA ahora tiene mejor contexto para acompañarte.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          fontSize: 15.sp,
                          height: 1.45,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(15.w),
                        decoration: BoxDecoration(
                          color: appColors.successBg,
                          borderRadius: BorderRadius.circular(18.r),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_outline_rounded,
                              color: appColors.successFg,
                            ),
                            SizedBox(width: 11.w),
                            Expanded(
                              child: Text(
                                'Tus respuestas se usan para personalizar tu experiencia de bienestar.',
                                style: GoogleFonts.fredoka(
                                  fontSize: 12.sp,
                                  height: 1.35,
                                  color: appColors.successFg,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24.h),
                      OnboardingPrimaryButton(
                        label: 'Continuar a la app',
                        onPressed: onContinue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurveyError extends StatelessWidget {
  const _SurveyError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
      body: OnboardingBackdrop(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 430),
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const OnboardingNoaBadge(size: 100),
                    SizedBox(height: 16.h),
                    Text(
                      'No pudimos cargar la encuesta',
                      style: GoogleFonts.fredoka(
                        fontSize: 21.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(message, textAlign: TextAlign.center),
                    SizedBox(height: 20.h),
                    OnboardingPrimaryButton(
                      label: 'Reintentar',
                      onPressed: onRetry,
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Volver'),
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

Color _scoreColor(BuildContext context, int score) {
  final appColors = context.appColors;
  return switch (score) {
    0 => appColors.dangerFg,
    1 => appColors.goldEnd,
    2 => appColors.goldStart,
    3 => appColors.successFg,
    _ => appColors.brandBorder,
  };
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
