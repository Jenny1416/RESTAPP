import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/features/professional_care/models/professional_care_models.dart';
import 'package:rest/features/professional_care/services/professional_care_service.dart';

void main() {
  setUp(() {
    UserSession.authToken = 'test-token';
    UserSession.userId = 12;
  });

  tearDown(() {
    UserSession.authToken = null;
    UserSession.userId = null;
  });

  test('interpreta el directorio público de psicólogos', () async {
    final service = ProfessionalCareService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/psicologos');
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          jsonEncode([
            {
              'id': 7,
              'nombres': 'Ana',
              'apellidos': 'Pérez',
              'especialidad_psicologo': 'Ansiedad',
              'ciudad': 'Barranquilla',
              'idioma': 'Español',
            },
          ]),
          200,
        );
      }),
    );

    final result = await service.getPsychologists();

    expect(result, hasLength(1));
    expect(result.single.fullName, 'Ana Pérez');
    expect(result.single.specialty, 'Ansiedad');
  });

  test('interpreta solicitudes y detecta la asignación aprobada', () async {
    final service = ProfessionalCareService(
      client: MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 5,
                'estudiante_id': 12,
                'psicologo_id': 7,
                'estado': 'aprobado',
                'mensaje': 'Necesito orientación',
                'solicitado_en': '2026-09-17T14:00:00.000Z',
              },
            ],
          }),
          200,
        );
      }),
    );

    final result = await service.getMyAssignments();

    expect(result.single.status, AssignmentStatus.approved);
    expect(result.single.isApproved, isTrue);
    expect(result.single.psychologistId, 7);
  });

  test('envía psicólogo y mensaje opcional al solicitar atención', () async {
    final service = ProfessionalCareService(
      client: MockClient((request) async {
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['psicologo_id'], 7);
        expect(body['mensaje'], 'Quisiera conversar');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 11,
              'estudiante_id': 12,
              'psicologo_id': 7,
              'estado': 'pendiente',
            },
          }),
          201,
        );
      }),
    );

    final result = await service.requestCare(
      psychologistId: 7,
      message: 'Quisiera conversar',
    );

    expect(result.status, AssignmentStatus.pending);
  });

  test('propaga el mensaje de error entregado por el backend', () async {
    final service = ProfessionalCareService(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({'success': false, 'message': 'Solicitud duplicada'}),
          400,
        ),
      ),
    );

    expect(
      () => service.requestCare(psychologistId: 7),
      throwsA(
        isA<ProfessionalCareException>().having(
          (error) => error.message,
          'message',
          'Solicitud duplicada',
        ),
      ),
    );
  });

  test('solo muestra chats de solicitudes aprobadas', () async {
    final service = ProfessionalCareService(
      client: MockClient((request) async {
        if (request.url.path == '/api/asignaciones/mis-solicitudes') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {'id': 1, 'psicologo_id': 7, 'estado': 'aprobado'},
                {'id': 2, 'psicologo_id': 8, 'estado': 'rechazado'},
              ],
            }),
            200,
          );
        }

        expect(request.url.path, '/api/chats');
        return http.Response(
          jsonEncode([
            {
              'id': 20,
              'estudiante_id': 12,
              'psicologo_id': 7,
              'is_active': true,
              'isSendByAi': false,
            },
            {
              'id': 21,
              'estudiante_id': 12,
              'psicologo_id': 8,
              'is_active': true,
              'isSendByAi': false,
            },
          ]),
          200,
        );
      }),
    );

    final chats = await service.getChats();

    expect(chats, hasLength(1));
    expect(chats.single.psychologistId, 7);
  });

  test('no crea un chat antes de que la solicitud sea aprobada', () async {
    final service = ProfessionalCareService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/asignaciones/mis-solicitudes');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {'id': 2, 'psicologo_id': 8, 'estado': 'pendiente'},
            ],
          }),
          200,
        );
      }),
    );

    expect(
      () => service.getOrCreateActiveChat(8),
      throwsA(
        isA<ProfessionalCareException>().having(
          (error) => error.statusCode,
          'statusCode',
          403,
        ),
      ),
    );
  });
}
