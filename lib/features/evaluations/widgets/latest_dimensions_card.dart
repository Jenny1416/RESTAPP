import 'package:flutter/material.dart';
import 'package:rest/core/theme/app_colors.dart';

import '../models/evaluation.dart';
import '../services/evaluation_service.dart';

class LatestDimensionsCard extends StatefulWidget {
  final List<Map<String, dynamic>> initialDimensions;
  final String? initialSubcategory;

  const LatestDimensionsCard({
    super.key,
    this.initialDimensions = const [],
    this.initialSubcategory,
  });

  @override
  State<LatestDimensionsCard> createState() => _LatestDimensionsCardState();
}

class _LatestDimensionsCardState extends State<LatestDimensionsCard> {
  Evaluation? _evaluation;
  late final List<SemaforoDimension> _initialDimensions;

  @override
  void initState() {
    super.initState();
    _initialDimensions = widget.initialDimensions
        .map(SemaforoDimension.fromJson)
        .where((item) => item.dimension.isNotEmpty)
        .toList();
    // El backend puede seguir procesando el guardado mientras ya mostramos
    // el resultado local; consultar aquí podría traer la evaluación anterior.
    if (_initialDimensions.isEmpty) _load();
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
    final dimensions = evaluation?.dimensiones ?? _initialDimensions;
    final subcategory =
        evaluation?.subcategoriaPrincipal ?? widget.initialSubcategory;
    if (dimensions.isEmpty) {
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
          if (subcategory case final value?) ...[
            const SizedBox(height: 4),
            Text(
              'Dimensión principal: ${_dimensionLabel(value.split('_').skip(1).join('_'))}',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 14),
          ...dimensions.map(
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
