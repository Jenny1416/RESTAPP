import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rest/core/services/progress_service.dart';

Future<bool?> showActivityCompletionSheet(
  BuildContext context,
  DailyActivity activity,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _ActivityCompletionSheet(activity: activity),
  );
}

class _ActivityCompletionSheet extends StatefulWidget {
  const _ActivityCompletionSheet({required this.activity});

  final DailyActivity activity;

  @override
  State<_ActivityCompletionSheet> createState() =>
      _ActivityCompletionSheetState();
}

class _ActivityCompletionSheetState extends State<_ActivityCompletionSheet> {
  Timer? _timer;
  late final int? _durationSeconds;
  late int _remainingSeconds;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _durationSeconds = _findDurationSeconds(widget.activity);
    _remainingSeconds = _durationSeconds ?? 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }

    if (_remainingSeconds == 0) {
      _remainingSeconds = _durationSeconds!;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds <= 1) {
        timer.cancel();
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _remainingSeconds--);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final timed = _durationSeconds != null;
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timerText =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.activity.nombre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Fredoka',
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.activity.descripcion.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                widget.activity.descripcion,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.35),
              ),
            ],
            const SizedBox(height: 22),
            if (timed) ...[
              Text(
                timerText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _running
                    ? 'Al terminar se registrará automáticamente.'
                    : 'Inicia el temporizador cuando vayas a comenzar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _toggleTimer,
                icon: Icon(
                  _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(_running ? 'Pausar' : 'Iniciar temporizador'),
              ),
            ] else ...[
              Text(
                'Cuando termines, confirma para sumar esta actividad al progreso.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.35),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Confirmar actividad realizada'),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }
}

int? _findDurationSeconds(DailyActivity activity) {
  final text = '${activity.nombre} ${activity.descripcion}'.toLowerCase();
  final match = RegExp(
    r'(\d{1,2})(?:\s*(?:-|a)\s*\d{1,2})?\s*min',
  ).firstMatch(text);
  if (match == null) return null;
  final minutes = int.tryParse(match.group(1) ?? '');
  return minutes == null || minutes <= 0 ? null : minutes * 60;
}
