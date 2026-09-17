import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/onboarding_models.dart';
import '../services/onboarding_service.dart';
import '../widgets/onboarding_visuals.dart';
import 'onboarding_survey_screen.dart';

class OnboardingStatusScreen extends StatefulWidget {
  final WidgetBuilder? destinationBuilder;

  const OnboardingStatusScreen({super.key, this.destinationBuilder});

  @override
  State<OnboardingStatusScreen> createState() => _OnboardingStatusScreenState();
}

class _OnboardingStatusScreenState extends State<OnboardingStatusScreen> {
  final OnboardingService _service = OnboardingService();
  OnboardingStatus? _status;
  int? _questionCount;
  int? _dimensionCount;
  String? _error;
  bool _loading = true;

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
      final status = await _service.getEstado();
      int? questionCount;
      int? dimensionCount;

      if (!status.completado) {
        try {
          final survey = await _service.getPreguntas();
          questionCount = survey.preguntas.length;
          dimensionCount = survey.preguntas
              .map((question) => question.categoria)
              .where((category) => category.isNotEmpty)
              .toSet()
              .length;
        } catch (_) {
          // La encuesta hará su propia carga si el resumen no está disponible.
        }
      }

      if (!mounted) return;
      setState(() {
        _status = status;
        _questionCount = questionCount;
        _dimensionCount = dimensionCount;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _continueToApp([bool completed = false]) {
    final destination = widget.destinationBuilder;
    if (destination != null) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: destination));
    } else {
      Navigator.of(context).pop(completed);
    }
  }

  Future<void> _startSurvey() async {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const OnboardingSurveyScreen()),
    );
    if (!mounted || completed != true) return;
    _continueToApp(true);
  }

  @override
  Widget build(BuildContext context) {
    final completed = _status?.completado ?? false;
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: OnboardingBackdrop(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _OnboardingError(
                  message: _error!,
                  onRetry: _load,
                  onContinue: () => _continueToApp(false),
                )
              : _OnboardingContent(
                  completed: completed,
                  questionCount: _questionCount,
                  dimensionCount: _dimensionCount,
                  canGoBack: widget.destinationBuilder == null,
                  onBack: () => Navigator.of(context).maybePop(),
                  onStart: _startSurvey,
                  onContinue: () => _continueToApp(completed),
                ),
        ),
      ),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  const _OnboardingContent({
    required this.completed,
    required this.questionCount,
    required this.dimensionCount,
    required this.canGoBack,
    required this.onBack,
    required this.onStart,
    required this.onContinue,
  });

  final bool completed;
  final int? questionCount;
  final int? dimensionCount;
  final bool canGoBack;
  final VoidCallback onBack;
  final VoidCallback onStart;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = completed
        ? '¡Tu perfil de bienestar está listo!'
        : 'Conozcámonos un poco mejor';
    final description = completed
        ? 'NOA ya puede acompañarte con un contexto más cercano a cómo te sientes.'
        : 'Esta encuesta inicial ayudará a NOA a personalizar tu experiencia desde el primer día.';

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              Row(
                children: [
                  if (canGoBack)
                    _HeaderButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: onBack,
                    )
                  else
                    SizedBox(width: 42.w),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'TU BIENESTAR',
                          style: GoogleFonts.fredoka(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                            color: onboardingPurple,
                          ),
                        ),
                        Text(
                          completed ? 'Todo preparado' : 'Encuesta inicial',
                          style: GoogleFonts.fredoka(
                            fontSize: 21.sp,
                            fontWeight: FontWeight.bold,
                            color: colors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 42.w),
                ],
              ),
              SizedBox(height: 22.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 22.h),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(28.r),
                  border: Border.all(
                    color: onboardingPurple.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: onboardingPurple.withValues(alpha: 0.1),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    OnboardingNoaBadge(completed: completed),
                    SizedBox(height: 22.h),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 27.sp,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                        color: colors.onSurface,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 14.sp,
                        height: 1.45,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (!completed) ...[
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Expanded(
                            child: _Metric(
                              icon: Icons.quiz_outlined,
                              value: questionCount?.toString() ?? '—',
                              label: 'preguntas',
                              color: onboardingPurple,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: _Metric(
                              icon: Icons.bubble_chart_outlined,
                              value: dimensionCount?.toString() ?? '—',
                              label: 'dimensiones',
                              color: onboardingBlue,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          const Expanded(
                            child: _Metric(
                              icon: Icons.schedule_rounded,
                              value: 'A tu',
                              label: 'ritmo',
                              color: Color(0xFF8C4EFF),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18.h),
                      const _PrivacyNote(),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 22.h),
              OnboardingPrimaryButton(
                label: completed ? 'Continuar a la app' : 'Comenzar encuesta',
                onPressed: completed ? onContinue : onStart,
              ),
              if (!completed) ...[
                SizedBox(height: 8.h),
                TextButton(
                  onPressed: onContinue,
                  child: Text(
                    'Ahora no, continuar a la app',
                    style: GoogleFonts.fredoka(
                      color: onboardingBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
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
          border: Border.all(color: onboardingPurple.withValues(alpha: 0.14)),
        ),
        child: Icon(icon, color: onboardingPurple, size: 18),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 21.sp),
          SizedBox(height: 5.h),
          Text(
            value,
            maxLines: 1,
            style: GoogleFonts.fredoka(
              color: colorsForText(context),
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: GoogleFonts.fredoka(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Color colorsForText(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DC),
        borderRadius: BorderRadius.circular(17.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34.w,
            height: 34.w,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE7B5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              size: 19,
              color: Color(0xFFB76A00),
            ),
          ),
          SizedBox(width: 11.w),
          Expanded(
            child: Text(
              'No es un diagnóstico. Puedes pausarla y retomarla después desde Inicio.',
              style: GoogleFonts.fredoka(
                fontSize: 12.sp,
                height: 1.35,
                color: const Color(0xFF704300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingError extends StatelessWidget {
  const _OnboardingError({
    required this.message,
    required this.onRetry,
    required this.onContinue,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
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
                'No pudimos consultar el onboarding',
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 21.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(message, textAlign: TextAlign.center),
              SizedBox(height: 20.h),
              OnboardingPrimaryButton(label: 'Reintentar', onPressed: onRetry),
              TextButton(
                onPressed: onContinue,
                child: const Text('Continuar sin bloquear la app'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
