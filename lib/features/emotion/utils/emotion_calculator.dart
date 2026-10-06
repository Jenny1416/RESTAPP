/// Calcula localmente el mismo fallback determinista que usa el backend.
/// Las respuestas van de 0 (muy mal) a 4 (excelente).
class EmotionCalculator {
  static const String critico = 'critico';
  static const String alertaAmarillo = 'alerta-amarillo';
  static const String normal = 'normal';

  // Compatibilidad con las pantallas que clasifican el historial semanal.
  static const String CRITICO = critico;
  static const String ALERTA_AMARILLO = alertaAmarillo;
  static const String NORMAL = normal;
  static const String EXCELENTE = 'excelente';

  /// El backend invierte la escala a gravedad 1-5 y clasifica el resultado
  /// normalizado así: verde < 40, amarillo 40-69 y rojo >= 70. También eleva
  /// el nivel cuando hay suficientes respuestas graves.
  static Map<String, dynamic> calcularEstado({
    required List<dynamic> preguntas,
    required Map<int, int> opcionSeleccionadaPorPregunta,
  }) {
    if (preguntas.isEmpty) return _defaultNormal();

    double puntajePonderado = 0;
    double sumaBienestar = 0;
    int cantidad = 0;
    int respuestasGraves = 0;
    final puntajesPorDimension = <String, List<double>>{};

    for (final pregunta in preguntas) {
      if (pregunta is! Map) continue;
      final preguntaId = pregunta['id'];
      if (preguntaId is! int) continue;

      final respuesta = opcionSeleccionadaPorPregunta[preguntaId];
      if (respuesta == null) continue;

      final valorBienestar = respuesta.clamp(0, 4);
      final gravedad = 5 - valorBienestar;
      final peso = pregunta['peso'] is num
          ? (pregunta['peso'] as num).toDouble()
          : 1.0;
      puntajePonderado += gravedad * peso;
      sumaBienestar += valorBienestar;
      cantidad++;
      if (gravedad >= 4) respuestasGraves++;

      final dimension = (pregunta['categoria'] ?? 'general').toString();
      final puntajeDimension = ((gravedad - 1) / 4 * 100)
          .clamp(0, 100)
          .toDouble();
      puntajesPorDimension
          .putIfAbsent(dimension, () => <double>[])
          .add(puntajeDimension);
    }

    if (cantidad == 0) return _defaultNormal();

    final minScore = cantidad;
    final maxScore = cantidad * 5;
    final puntaje =
        (((puntajePonderado - minScore) / (maxScore - minScore)) * 100)
            .clamp(0, 100)
            .round();
    final porcentajeGraves = respuestasGraves / cantidad * 100;

    final Map<String, dynamic> resultado;
    if (puntaje >= 70 || porcentajeGraves >= 60) {
      resultado = Map<String, dynamic>.from(_estadoCritico());
    } else if (puntaje >= 40 || porcentajeGraves >= 30) {
      resultado = Map<String, dynamic>.from(_estadoAlertaAmarillo());
    } else {
      resultado = Map<String, dynamic>.from(_estadoNormal());
    }

    final dimensiones = puntajesPorDimension.entries.map((entry) {
      final promedio =
          (entry.value.reduce((a, b) => a + b) / entry.value.length).round();
      return <String, dynamic>{
        'dimension': entry.key,
        'puntaje': promedio,
        'nivel': _nivelBackend(promedio),
      };
    }).toList();
    dimensiones.sort((a, b) {
      final nivel =
          _rangoNivel(b['nivel'] as String) - _rangoNivel(a['nivel'] as String);
      if (nivel != 0) return nivel;
      final puntajeDiff = (b['puntaje'] as int) - (a['puntaje'] as int);
      if (puntajeDiff != 0) return puntajeDiff;
      return (a['dimension'] as String).compareTo(b['dimension'] as String);
    });

    resultado['promedio'] = sumaBienestar / cantidad;
    resultado['puntaje'] = puntaje;
    resultado['dimensiones'] = dimensiones;
    if (dimensiones.isNotEmpty) {
      final color = resultado['estado'] == critico
          ? 'rojo'
          : resultado['estado'] == alertaAmarillo
          ? 'amarillo'
          : 'verde';
      resultado['subcategoria_principal'] =
          '${color}_${dimensiones.first['dimension']}';
    }
    return resultado;
  }

  static String _nivelBackend(int puntaje) {
    if (puntaje >= 70) return 'rojo';
    if (puntaje >= 40) return 'amarillo';
    return 'verde';
  }

  static int _rangoNivel(String nivel) {
    if (nivel == 'rojo') return 2;
    if (nivel == 'amarillo') return 1;
    return 0;
  }

  static Map<String, String> _estadoNormal() => const {
    'estado': normal,
    'titulo': 'Normal',
    'mensaje': 'Tu día va tranquilo y estable.',
    'mensaje2': 'Es un buen momento para reflexionar.',
    'botonTexto': 'Continuar',
  };

  static Map<String, String> _estadoAlertaAmarillo() => const {
    'estado': alertaAmarillo,
    'titulo': '¡Alerta!',
    'mensaje':
        'Parece que hoy no estás al 100%. Te invitamos a respirar y relajarte.',
    'mensaje2': '¡Tenemos esto para ti!',
    'botonTexto': 'Ver consejos',
  };

  static Map<String, String> _estadoCritico() => const {
    'estado': critico,
    'titulo': '¡Alerta!',
    'mensaje': 'Notamos que hoy te sientes mal. Estamos aquí para ayudarte.',
    'mensaje2': '¡Tenemos esto para ti!',
    'botonTexto': 'Pedir ayuda',
  };

  static Map<String, dynamic> _defaultNormal() => <String, dynamic>{
    ..._estadoNormal(),
    'promedio': 2.0,
    'puntaje': 50,
    'dimensiones': <Map<String, dynamic>>[],
  };
}
