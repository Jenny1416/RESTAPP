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
      backgroundColor: colors.surface,
      appBar: AppBar(
        automaticallyImplyLeading: widget.destinationBuilder == null,
        title: const Text('Estado del onboarding'),
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
        : const Color(0xFF3973D1);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Container(
                width: 104.w,
                height: 104.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.12),
                ),
                child: Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.assignment_outlined,
                  size: 60.sp,
                  color: primary,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                completed
                    ? 'Onboarding completado'
                    : 'Tu onboarding está pendiente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 27.sp,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                completed
                    ? 'Tu línea base de bienestar ya está lista. NOA podrá ofrecerte acompañamiento más personalizado.'
                    : 'Son 18 preguntas breves sobre siete dimensiones de bienestar. Tus respuestas mejoran el contexto de NOA y no constituyen un diagnóstico.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  height: 1.45,
                  color: colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 24.h),
              if (!completed)
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4DD),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFFB56700),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Puedes hacerlo ahora o continuar y completarlo después desde el recordatorio de inicio.',
                          style: TextStyle(color: Color(0xFF704300)),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 30.h),
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: FilledButton.icon(
                  onPressed: completed ? onContinue : onStart,
                  icon: Icon(
                    completed
                        ? Icons.home_outlined
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    completed ? 'Continuar a la app' : 'Comenzar encuesta',
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
