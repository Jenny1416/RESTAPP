import 'package:flutter/material.dart';
import 'package:rest/core/theme/app_colors.dart';

import '../models/evaluation.dart';
import '../services/evaluation_service.dart';

class LatestDimensionsCard extends StatefulWidget {
  const LatestDimensionsCard({super.key});

  @override
  State<LatestDimensionsCard> createState() => _LatestDimensionsCardState();
}

class _LatestDimensionsCardState extends State<LatestDimensionsCard> {
  Evaluation? _evaluation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final evaluations = await EvaluationService().getEvaluaciones();
      if (mounted && evaluations.isNotEmpty) {
        setState(() => _evaluation = evaluations.first);
      }
    } catch (_) {
      // El detalle dimensional complementa el semáforo; no bloquea la vista.
    }
  }

  @override
  Widget build(BuildContext context) {
    final evaluation = _evaluation;
    if (evaluation == null || evaluation.dimensiones.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Semáforo por dimensiones',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          if (evaluation.subcategoriaPrincipal case final subcategory?) ...[
            const SizedBox(height: 4),
            Text(
              'Dimensión principal: ${_dimensionLabel(subcategory.split('_').skip(1).join('_'))}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 14),
          ...evaluation.dimensiones.map(
            (dimension) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DimensionRow(dimension: dimension),
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionRow extends StatelessWidget {
  final SemaforoDimension dimension;

  const _DimensionRow({required this.dimension});

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final color = switch (dimension.nivel.toLowerCase()) {
      'rojo' => appColors.dangerFg,
      'amarillo' => appColors.goldEnd,
      _ => appColors.successFg,
    };
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(_dimensionLabel(dimension.dimension))),
        Text(
          '${dimension.puntaje.round()}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
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
