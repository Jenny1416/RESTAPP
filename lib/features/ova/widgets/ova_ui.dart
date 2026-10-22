import 'package:flutter/material.dart';
import 'package:rest/core/theme/app_colors.dart';

import '../models/ova_models.dart';

IconData ovaTipoIcon(OvaTipo tipo) {
  switch (tipo) {
    case OvaTipo.video:
      return Icons.play_circle_outline_rounded;
    case OvaTipo.respiracion:
      return Icons.air_rounded;
    case OvaTipo.ejercicioPractico:
      return Icons.self_improvement_rounded;
    case OvaTipo.otro:
      return Icons.spa_outlined;
  }
}

String ovaTipoLabel(OvaTipo tipo) {
  switch (tipo) {
    case OvaTipo.video:
      return 'Video';
    case OvaTipo.respiracion:
      return 'Respiración';
    case OvaTipo.ejercicioPractico:
      return 'Ejercicio práctico';
    case OvaTipo.otro:
      return 'Actividad';
  }
}

Color ovaTipoColor(BuildContext context, OvaTipo tipo) {
  final colors = context.appColors;
  switch (tipo) {
    case OvaTipo.video:
      return colors.accentBlue;
    case OvaTipo.respiracion:
      return colors.accentTeal;
    case OvaTipo.ejercicioPractico:
      return colors.accentPurple;
    case OvaTipo.otro:
      return colors.accentBlue;
  }
}

/// Texto breve y amable sobre por qué se recomienda la actividad. No muestra
/// niveles de semáforo ni puntajes.
String ovaMotivo(OvaAsignacion asignacion) {
  const temas = {
    'ansiedad': 'la ansiedad',
    'estres_academico': 'el estrés académico',
    'humor_depresivo': 'tu estado de ánimo',
    'sueno': 'el sueño',
    'relaciones_sociales': 'tus relaciones',
    'autoestima_autocuidado': 'tu autoestima',
    'energia_motivacion': 'tu energía',
  };
  final tema = temas[asignacion.dimension];
  return tema == null
      ? 'Recomendada según cómo te has sentido'
      : 'Puede ayudarte con $tema';
}

String ovaDuracion(OvaInfo ova) =>
    ova.duracionMinutos > 0 ? '${ova.duracionMinutos} min' : 'Corta';
