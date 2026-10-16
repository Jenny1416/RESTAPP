import 'package:flutter_test/flutter_test.dart';
import 'package:rest/features/emotion/utils/emotion_calculator.dart';

void main() {
  final preguntas = <Map<String, dynamic>>[
    {'id': 1, 'peso': 1, 'categoria': 'ansiedad'},
    {'id': 2, 'peso': 1, 'categoria': 'estres_academico'},
    {'id': 3, 'peso': 1, 'categoria': 'energia_motivacion'},
    {'id': 4, 'peso': 1, 'categoria': 'humor_depresivo'},
    {'id': 5, 'peso': 1, 'categoria': 'ansiedad'},
  ];

  test('respuestas positivas producen el mismo verde/normal del backend', () {
    final result = EmotionCalculator.calcularEstado(
      preguntas: preguntas,
      opcionSeleccionadaPorPregunta: {
        for (final pregunta in preguntas) pregunta['id'] as int: 4,
      },
    );

    expect(result['estado'], 'normal');
    expect(result['puntaje'], 0);
    expect(result['promedio'], 4.0);
  });

  test('respuestas intermedias producen amarillo', () {
    final result = EmotionCalculator.calcularEstado(
      preguntas: preguntas,
      opcionSeleccionadaPorPregunta: {
        for (final pregunta in preguntas) pregunta['id'] as int: 2,
      },
    );

    expect(result['estado'], 'alerta-amarillo');
    expect(result['puntaje'], 50);
  });

  test('respuestas de malestar producen rojo y dimensiones locales', () {
    final result = EmotionCalculator.calcularEstado(
      preguntas: preguntas,
      opcionSeleccionadaPorPregunta: {
        for (final pregunta in preguntas) pregunta['id'] as int: 0,
      },
    );

    expect(result['estado'], 'critico');
    expect(result['puntaje'], 100);
    expect(result['dimensiones'], isNotEmpty);
    expect(result['subcategoria_principal'], 'rojo_ansiedad');
  });
}
