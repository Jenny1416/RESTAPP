import 'package:flutter/material.dart';

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
          // La pantalla conserva el acceso a la encuesta, que hará su propia
          // carga, aunque no se pueda mostrar el conteo todavía.
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: widget.destinationBuilder == null,
        title: const Text(
          'Estado del onboarding',
          style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
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
                onStart: _startSurvey,
                onContinue: () => _continueToApp(completed),
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
    required this.onStart,
    required this.onContinue,
  });

  final bool completed;
  final int? questionCount;
  final int? dimensionCount;
  final VoidCallback onStart;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final countDescription = questionCount == null
        ? 'Es una encuesta breve para conocer mejor tu bienestar.'
        : 'Son $questionCount preguntas breves${dimensionCount == null ? '' : ' sobre $dimensionCount dimensiones'} de bienestar.';

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            children: [
              const SizedBox(height: 48),
              Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  color: completed
                      ? const Color(0xFFE0F6EB)
                      : const Color(0xFFE2ECFF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  completed
                      ? Icons.task_alt_rounded
                      : Icons.assignment_outlined,
                  size: 58,
                  color: completed
                      ? const Color(0xFF248458)
                      : const Color(0xFF3475D1),
                ),
              ),
              const SizedBox(height: 34),
              Text(
                completed
                    ? 'Tu onboarding está completo'
                    : 'Tu onboarding está pendiente',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF20242D),
                  height: 1.28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                completed
                    ? 'Tu información inicial ya está lista para personalizar la experiencia con NOA.'
                    : '$countDescription Tus respuestas mejoran el contexto de NOA y no constituyen un diagnóstico.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.55,
                  color: Color(0xFF4C5260),
                ),
              ),
              if (!completed) ...[
                const SizedBox(height: 28),
                const _ReminderNote(),
              ],
              const SizedBox(height: 34),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: FilledButton.icon(
                  onPressed: completed ? onContinue : onStart,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    completed ? 'Continuar a la app' : 'Comenzar encuesta',
                    style: const TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF326FA3),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
              if (!completed) ...[
                const SizedBox(height: 10),
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

class _ReminderNote extends StatelessWidget {
  const _ReminderNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2D7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.notifications_none_rounded, color: Color(0xFFB56700)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Puedes hacerlo ahora o continuarlo después desde el recordatorio de Inicio.',
              style: TextStyle(color: Color(0xFF764900), height: 1.4),
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
