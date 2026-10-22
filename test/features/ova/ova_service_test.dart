import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rest/features/ova/models/ova_models.dart';
import 'package:rest/features/ova/services/ova_service.dart';

Map<String, dynamic> _item(int id, String estado) => {
  'id': id,
  'ova_id': 3,
  'estado': estado,
  'requiere_post_test': estado == 'COMPLETED',
  'post_evaluacion_id': null,
  'ova': {
    'id': 3,
    'titulo': 'Respiración',
    'tipo_actividad': 'respiracion',
    'duracion_minutos': 5,
    'storage_source': 'YOUTUBE',
    'recurso': {
      'storage_source': 'YOUTUBE',
      'original_url': 'https://youtu.be/abcdefghijk',
      'video_id': 'abcdefghijk',
    },
  },
};

OvaService _service(MockClientHandler handler, {String? token = 'token'}) {
  return OvaService(
    baseUrl: 'https://api.test/',
    tokenProvider: () => token,
    client: MockClient(handler),
  );
}

void main() {
  test('getAsignaciones llama a la ruta con Bearer y lee la lista', () async {
    final service = _service((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/ovas/asignaciones');
      expect(request.headers['Authorization'], 'Bearer token');
      return http.Response(
        jsonEncode({
          'total': 2,
          'asignaciones': [_item(1, 'PENDING'), _item(2, 'COMPLETED')],
        }),
        200,
      );
    });

    final items = await service.getAsignaciones();

    expect(items.map((e) => e.id), [1, 2]);
    expect(items.first.porHacer, isTrue);
    expect(items.last.necesitaPostTest, isTrue);
  });

  test('getAsignacion lee el objeto sin envoltorio', () async {
    final service = _service((request) async {
      expect(request.url.path, '/api/ovas/asignaciones/7');
      return http.Response(jsonEncode(_item(7, 'IN_PROGRESS')), 200);
    });

    final item = await service.getAsignacion(7);

    expect(item.id, 7);
    expect(item.estado, OvaEstado.inProgress);
  });

  test('iniciar usa PATCH sobre la asignación', () async {
    var llamado = false;
    final service = _service((request) async {
      llamado = true;
      expect(request.method, 'PATCH');
      expect(request.url.path, '/api/ovas/asignaciones/7/iniciar');
      return http.Response(
        jsonEncode({'message': 'Actividad iniciada correctamente'}),
        200,
      );
    });

    await service.iniciar(7);

    expect(llamado, isTrue);
  });

  test('completar envía liked y rating y devuelve requierePostTest', () async {
    final service = _service((request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/api/ovas/asignaciones/7/completar');
      expect(request.headers['Content-Type'], contains('application/json'));
      expect(jsonDecode(request.body), {'liked': true, 'rating': 5});
      return http.Response(
        jsonEncode({
          'message': 'Actividad completada exitosamente',
          'requiere_post_test': true,
          'pre_evaluacion_id': 40,
        }),
        200,
      );
    });

    final resultado = await service.completar(7, liked: true, rating: 5);

    expect(resultado.requierePostTest, isTrue);
    expect(resultado.preEvaluacionId, 40);
  });

  test('completar omite rating cuando no se califica', () async {
    final service = _service((request) async {
      expect(jsonDecode(request.body), {'liked': false});
      return http.Response(jsonEncode({'requiere_post_test': true}), 200);
    });

    await service.completar(7, liked: false);
  });

  test('completar rechaza una calificación fuera de 1 a 5', () {
    final service = _service((request) async => http.Response('{}', 200));

    expect(
      () => service.completar(7, liked: true, rating: 6),
      throwsArgumentError,
    );
  });

  test('omitir envía el estado como lo espera el backend', () async {
    final service = _service((request) async {
      expect(request.url.path, '/api/ovas/asignaciones/7/omitir');
      expect(jsonDecode(request.body), {'estado': 'DISMISSED'});
      return http.Response(jsonEncode({'message': 'ok'}), 200);
    });

    await service.omitir(7, OvaOmision.dismissed);
  });

  test('propaga el mensaje de error del backend', () async {
    final service = _service(
      (request) async => http.Response(
        jsonEncode({'message': 'La actividad ya fue completada previamente'}),
        400,
      ),
    );

    await expectLater(
      service.iniciar(7),
      throwsA(
        isA<OvaException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having(
              (e) => e.message,
              'message',
              'La actividad ya fue completada previamente',
            ),
      ),
    );
  });

  test('401 muestra un mensaje de sesión vencida', () async {
    final service = _service(
      (request) async =>
          http.Response(jsonEncode({'message': 'Invalid or expired token'}), 401),
    );

    await expectLater(
      service.getAsignaciones(),
      throwsA(
        isA<OvaException>().having(
          (e) => e.message,
          'message',
          contains('sesión venció'),
        ),
      ),
    );
  });

  test('sin token no hace la petición y avisa que la sesión venció', () async {
    var llamado = false;
    final service = _service((request) async {
      llamado = true;
      return http.Response('{}', 200);
    }, token: null);

    await expectLater(
      service.getAsignaciones(),
      throwsA(isA<OvaException>()),
    );
    expect(llamado, isFalse);
  });

  test('una respuesta que no es JSON lanza OvaException', () async {
    final service = _service(
      (request) async => http.Response('<html>502</html>', 502),
    );

    await expectLater(
      service.getAsignaciones(),
      throwsA(isA<OvaException>()),
    );
  });
}
