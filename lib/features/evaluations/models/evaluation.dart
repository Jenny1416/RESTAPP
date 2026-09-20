class SemaforoDimension {
  final String dimension;
  final double puntaje;
  final String nivel;

  const SemaforoDimension({
    required this.dimension,
    required this.puntaje,
    required this.nivel,
  });

  factory SemaforoDimension.fromJson(Map<String, dynamic> json) {
    return SemaforoDimension(
      dimension: json['dimension']?.toString() ?? '',
      puntaje: (json['puntaje'] as num?)?.toDouble() ?? 0,
      nivel: json['nivel']?.toString() ?? 'verde',
    );
  }
}

class Evaluation {
  final int id;
  final String estadoSemaforo;
  final double puntajeTotal;
  final String? subcategoriaPrincipal;
  final DateTime? fecha;
  final List<SemaforoDimension> dimensiones;

  const Evaluation({
    required this.id,
    required this.estadoSemaforo,
    required this.puntajeTotal,
    required this.subcategoriaPrincipal,
    required this.fecha,
    required this.dimensiones,
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    final rawDimensions = json['dimensiones'];
    return Evaluation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      estadoSemaforo: json['estado_semaforo']?.toString() ?? 'verde',
      puntajeTotal: (json['puntaje_total'] as num?)?.toDouble() ?? 0,
      subcategoriaPrincipal: json['subcategoria_principal']?.toString(),
      fecha: DateTime.tryParse(json['fecha']?.toString() ?? ''),
      dimensiones: rawDimensions is List
          ? rawDimensions
                .whereType<Map>()
                .map(
                  (item) => SemaforoDimension.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .where((item) => item.dimension.isNotEmpty)
                .toList()
          : const [],
    );
  }
}
