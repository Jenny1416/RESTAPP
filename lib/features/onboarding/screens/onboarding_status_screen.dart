import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/onboarding_models.dart';
import '../services/onboarding_service.dart';
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
      if (!mounted) return;
      setState(() => _status = status);
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
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.brightness == Brightness.dark
          ? colors.surface
          : const Color(0xFFF5F7FF),
      appBar: AppBar(
        automaticallyImplyLeading: widget.destinationBuilder == null,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Tu bienestar',
          style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(
                message: _error!,
                onRetry: _load,
                onContinue: () => _continueToApp(false),
              )
            : _StatusContent(
                completed: _status?.completado ?? false,
                onStart: _startSurvey,
                onContinue: () => _continueToApp(_status?.completado ?? false),
              ),
      ),
    );
  }
}

class _StatusContent extends StatelessWidget {
  final bool completed;
  final VoidCallback onStart;
  final VoidCallback onContinue;

  const _StatusContent({
    required this.completed,
    required this.onStart,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = completed
        ? const Color(0xFF20A779)
        : const Color(0xFF326FB6);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 28.h),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(22.w, 28.h, 22.w, 26.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: completed
                        ? const [Color(0xFF25B49C), Color(0xFF278BC4)]
                        : const [Color(0xFF5D67E8), Color(0xFF2D9BC1)],
                  ),
                  borderRadius: BorderRadius.circular(30.r),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 88.w,
                      height: 88.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.42),
                        ),
                      ),
                      child: Icon(
                        completed
                            ? Icons.check_rounded
                            : Icons.psychology_alt_rounded,
                        size: 48.sp,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    Text(
                      completed
                          ? '¡Tu línea base está lista!'
                          : 'Conozcámonos un poco mejor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 27.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 9.h),
                    Text(
                      completed
                          ? 'Completaste tu encuesta inicial de bienestar.'
                          : 'Una encuesta breve para personalizar tu experiencia con NOA.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(22.r),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          child: _MetricPill(
                            icon: Icons.help_outline_rounded,
                            value: '18',
                            label: 'preguntas',
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _MetricPill(
                            icon: Icons.hub_outlined,
                            value: '7',
                            label: 'dimensiones',
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _MetricPill(
                            icon: Icons.schedule_rounded,
                            value: '3–4',
                            label: 'minutos',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      completed
                          ? 'Tus respuestas ayudarán a NOA a ofrecerte un acompañamiento más cercano y personalizado.'
                          : 'Exploraremos cómo te sientes en áreas como ansiedad, descanso, relaciones, autoestima y motivación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        height: 1.45,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
              if (!completed)
                Container(
                  padding: EdgeInsets.all(15.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4DD),
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Color(0xFFB56700)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No es un diagnóstico. Puedes pausarla y completarla después desde Inicio.',
                          style: TextStyle(color: Color(0xFF704300)),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 22.h),
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: FilledButton.icon(
                  onPressed: completed ? onContinue : onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.r),
                    ),
                  ),
                  icon: Icon(
                    completed
                        ? Icons.arrow_forward_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    completed ? 'Continuar' : 'Comenzar mi encuesta',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (!completed) ...[
                SizedBox(height: 10.h),
                TextButton(
                  onPressed: onContinue,
                  child: const Text('Ahora no, continuar a la app'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF326FB6)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Fredoka',
              fontWeight: FontWeight.bold,
              color: Color(0xFF22314D),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: const TextStyle(fontSize: 10, color: Color(0xFF58647A)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onContinue;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 54),
            const SizedBox(height: 16),
            const Text(
              'No pudimos consultar el onboarding',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
            TextButton(
              onPressed: onContinue,
              child: const Text('Continuar sin bloquear la app'),
            ),
          ],
        ),
      ),
    );
  }
}
