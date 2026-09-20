import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rest/features/evaluations/services/evaluation_service.dart';

void main() {
  test('getEvaluaciones interpreta dimensiones y subcategoría', () async {
    final service = EvaluationService(
      baseUrl: 'https://api.test',
      tokenProvider: () => 'token',
      client: MockClient((request) async {
        expect(request.url.path, '/api/evaluaciones');
        return http.Response(
          jsonEncode([
            {
              'id': 9,
              'estado_semaforo': 'rojo',
              'puntaje_total': 82,
              'subcategoria_principal': 'rojo_ansiedad',
              'fecha': '2026-09-17T00:00:00.000Z',
              'dimensiones': [
                {'dimension': 'ansiedad', 'puntaje': 82, 'nivel': 'rojo'},
              ],
            },
          ]),
          200,
        );
      }),
    );

    final evaluations = await service.getEvaluaciones();
    expect(evaluations.single.subcategoriaPrincipal, 'rojo_ansiedad');
    expect(evaluations.single.dimensiones.single.nivel, 'rojo');
  });

  test('getEvaluacion consulta el id solicitado', () async {
    final service = EvaluationService(
      baseUrl: 'https://api.test',
      tokenProvider: () => 'token',
      client: MockClient((request) async {
        expect(request.url.path, '/api/evaluaciones/12');
        return http.Response(
          '{"id":12,"estado_semaforo":"verde","puntaje_total":20,"dimensiones":[]}',
          200,
        );
      }),
    );

    final evaluation = await service.getEvaluacion(12);
    expect(evaluation.id, 12);
    expect(evaluation.estadoSemaforo, 'verde');
  });
}
