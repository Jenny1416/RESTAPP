import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/services/progress_service.dart';

class ActivityPracticeResult {
  final String? observations;

  const ActivityPracticeResult({this.observations});
}

class ActivityPracticeScreen extends StatefulWidget {
  final DailyActivity activity;

  const ActivityPracticeScreen({super.key, required this.activity});

  @override
  State<ActivityPracticeScreen> createState() => _ActivityPracticeScreenState();
}

class _ActivityPracticeScreenState extends State<ActivityPracticeScreen> {
  final _notesController = TextEditingController();
  Timer? _timer;
  late final int _suggestedSeconds;
  late int _remainingSeconds;
  bool _timerRunning = false;
  bool _performed = false;

  @override
  void initState() {
    super.initState();
    _suggestedSeconds = _durationMinutes(widget.activity) * 60;
    _remainingSeconds = _suggestedSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _toggleTimer() {
    if (_timerRunning) {
      _timer?.cancel();
      setState(() => _timerRunning = false);
      return;
    }
    if (_remainingSeconds == 0) {
      _remainingSeconds = _suggestedSeconds;
    }
    setState(() => _timerRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _timerRunning = false;
          _performed = true;
        });
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timerRunning = false;
      _remainingSeconds = _suggestedSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timerText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final steps = _stepsFor(widget.activity);

    return Scaffold(
      backgroundColor: colors.brightness == Brightness.dark
          ? colors.surface
          : const Color(0xFFF5F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Realizar actividad',
          style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(22.w),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF31B8A7), Color(0xFF347BC2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(26.r),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 72.w,
                                height: 72.w,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _iconFor(widget.activity),
                                  color: Colors.white,
                                  size: 38.sp,
                                ),
                              ),
                              SizedBox(height: 14.h),
                              Text(
                                widget.activity.nombre,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Fredoka',
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (widget.activity.descripcion.isNotEmpty) ...[
                                SizedBox(height: 8.h),
                                Text(
                                  widget.activity.descripcion,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 18.h),
                        _SectionCard(
                          title: 'Guía para realizarla',
                          icon: Icons.format_list_numbered_rounded,
                          child: Column(
                            children: [
                              for (var index = 0; index < steps.length; index++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    bottom: index == steps.length - 1 ? 0 : 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 13,
                                        backgroundColor: const Color(
                                          0xFFE5F1FF,
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Color(0xFF326FB6),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          steps[index],
                                          style: TextStyle(
                                            height: 1.35,
                                            color: colors.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),
                        _SectionCard(
                          title: 'Temporizador sugerido',
                          icon: Icons.timer_outlined,
                          child: Column(
                            children: [
                              Text(
                                timerText,
                                style: TextStyle(
                                  fontFamily: 'Fredoka',
                                  fontSize: 38.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF326FB6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FilledButton.icon(
                                    onPressed: _toggleTimer,
                                    icon: Icon(
                                      _timerRunning
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                    ),
                                    label: Text(
                                      _timerRunning ? 'Pausar' : 'Iniciar',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton.outlined(
                                    onPressed: _resetTimer,
                                    tooltip: 'Reiniciar',
                                    icon: const Icon(Icons.refresh_rounded),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),
                        _SectionCard(
                          title: '¿Cómo te fue?',
                          icon: Icons.edit_note_rounded,
                          child: TextField(
                            controller: _notesController,
                            minLines: 3,
                            maxLines: 5,
                            maxLength: 300,
                            decoration: InputDecoration(
                              hintText: 'Escribe una reflexión opcional…',
                              filled: true,
                              fillColor: colors.surfaceContainerLow,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        CheckboxListTile(
                          value: _performed,
                          onChanged: (value) =>
                              setState(() => _performed = value ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          title: const Text(
                            'Confirmo que realicé esta actividad',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: const Text(
                            'Solo se sumará al progreso después de confirmarla.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
              color: colors.surface,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54.h,
                    child: FilledButton.icon(
                      onPressed: _performed
                          ? () => Navigator.pop(
                              context,
                              ActivityPracticeResult(
                                observations:
                                    _notesController.text.trim().isEmpty
                                    ? null
                                    : _notesController.text.trim(),
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text(
                        'Finalizar y sumar al progreso',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF326FB6), size: 21),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

int _durationMinutes(DailyActivity activity) {
  final text = '${activity.nombre} ${activity.descripcion}'.toLowerCase();
  final match = RegExp(
    r'(\d{1,2})(?:\s*(?:-|a)\s*\d{1,2})?\s*min',
  ).firstMatch(text);
  if (match != null) return int.tryParse(match.group(1) ?? '') ?? 5;
  if (text.contains('respira')) return 3;
  if (text.contains('diario') || text.contains('escrib')) return 10;
  if (text.contains('ejercicio') || text.contains('camina')) return 15;
  return 5;
}

IconData _iconFor(DailyActivity activity) {
  final text = '${activity.nombre} ${activity.descripcion}'.toLowerCase();
  if (text.contains('respira')) return Icons.air_rounded;
  if (text.contains('diario') || text.contains('escrib')) {
    return Icons.menu_book_rounded;
  }
  if (text.contains('ejercicio') || text.contains('camina')) {
    return Icons.directions_walk_rounded;
  }
  if (text.contains('medita')) return Icons.self_improvement_rounded;
  return Icons.auto_awesome_rounded;
}

List<String> _stepsFor(DailyActivity activity) {
  final text = '${activity.nombre} ${activity.descripcion}'.toLowerCase();
  if (text.contains('respira')) {
    return const [
      'Busca una postura cómoda y relaja los hombros.',
      'Inhala por la nariz durante 4 segundos y sostén 2 segundos.',
      'Exhala lentamente durante 6 segundos. Repite sin forzarte.',
    ];
  }
  if (text.contains('diario') || text.contains('escrib')) {
    return const [
      'Busca un lugar tranquilo y piensa en cómo transcurrió tu día.',
      'Escribe qué emoción apareció, qué la provocó y qué necesitabas.',
      'Cierra con una acción pequeña de autocuidado para mañana.',
    ];
  }
  if (text.contains('ejercicio') || text.contains('camina')) {
    return const [
      'Elige un espacio seguro y realiza un calentamiento suave.',
      'Muévete a un ritmo cómodo; debes poder hablar sin quedarte sin aire.',
      'Termina bajando el ritmo y tomando agua.',
    ];
  }
  if (text.contains('medita')) {
    return const [
      'Siéntate cómodamente y reduce las distracciones.',
      'Lleva la atención a tu respiración, sin intentar cambiarla.',
      'Cuando tu mente se distraiga, vuelve con amabilidad al presente.',
    ];
  }
  return [
    activity.descripcion.isEmpty
        ? 'Lee el propósito de la actividad y prepara lo necesario.'
        : activity.descripcion,
    'Realízala con calma y presta atención a cómo te sientes.',
    'Al terminar, escribe una reflexión breve y confirma la actividad.',
  ];
}
