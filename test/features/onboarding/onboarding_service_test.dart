import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rest/features/onboarding/services/onboarding_service.dart';

void main() {
  group('OnboardingService', () {
    test('interpreta estado pendiente', () async {
      final service = OnboardingService(
        baseUrl: 'https://api.test',
        tokenProvider: () => 'token',
        client: MockClient((request) async {
          expect(request.url.path, '/api/onboarding/estado');
          expect(request.headers['Authorization'], 'Bearer token');
          return http.Response('{"completado":false}', 200);
        }),
      );

      final status = await service.getEstado();
      expect(status.completado, isFalse);
    });

    test('interpreta el contrato real de preguntas', () async {
      final service = OnboardingService(
        baseUrl: 'https://api.test',
        tokenProvider: () => 'token',
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'encuesta_id': 1,
              'titulo': 'Encuesta Inicial de Bienestar',
              'completado': false,
              'preguntas': [
                {
                  'id': 'onb_01',
                  'texto': '¿Cómo te sientes?',
                  'categoria': 'ansiedad',
                  'escala': '0-4',
                },
              ],
            }),
            200,
          ),
        ),
      );

      final survey = await service.getPreguntas();
      expect(survey.preguntas.single.id, 'onb_01');
      expect(survey.preguntas.single.categoria, 'ansiedad');
    });

    test('envía pregunta_id y puntaje', () async {
      final service = OnboardingService(
        baseUrl: 'https://api.test',
        tokenProvider: () => 'token',
        client: MockClient((request) async {
          expect(request.url.path, '/api/onboarding/respuestas');
          expect(jsonDecode(request.body), {
            'respuestas': [
              {'pregunta_id': 'onb_01', 'puntaje': 3},
            ],
          });
          return http.Response('{"message":"ok"}', 200);
        }),
      );

      await service.enviarRespuestas({'onb_01': 3});
    });

    test('expone conflicto cuando ya está completado', () async {
      final service = OnboardingService(
        baseUrl: 'https://api.test',
        tokenProvider: () => 'token',
        client: MockClient(
          (request) async => http.Response(
            '{"message":"El onboarding ya fue completado anteriormente"}',
            409,
          ),
        ),
      );

      expect(
        () => service.enviarRespuestas({'onb_01': 3}),
        throwsA(isA<OnboardingAlreadyCompletedException>()),
      );
    });
  });
}
