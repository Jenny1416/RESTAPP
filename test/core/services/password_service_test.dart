import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rest/core/services/password_service.dart';
import 'package:rest/core/services/user_session.dart';

void main() {
  setUp(() => UserSession.authToken = 'test-token');
  tearDown(() => UserSession.authToken = null);

  test(
    'valida la contraseña actual y actualiza mediante endpoints existentes',
    () async {
      var passwordUpdated = false;
      final service = PasswordService(
        client: MockClient((request) async {
          if (request.url.path == '/api/settings/profile') {
            expect(request.method, 'GET');
            expect(request.headers['Authorization'], 'Bearer test-token');
            return http.Response(
              jsonEncode({'id': 12, 'correo': 'user@test.com'}),
              200,
            );
          }
          if (request.url.path == '/api/auth/login') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['correo'], 'user@test.com');
            expect(body['contrasena'], 'actual123');
            return http.Response(jsonEncode({'token': 'token-validado'}), 200);
          }
          expect(request.method, 'PATCH');
          expect(request.url.path, '/api/users/12');
          expect(jsonDecode(request.body)['contrasena'], 'nueva1234');
          passwordUpdated = true;
          return http.Response(jsonEncode({'id': 12}), 200);
        }),
      );

      final message = await service.changePassword(
        contrasenaActual: 'actual123',
        nuevaContrasena: 'nueva1234',
        confirmarContrasena: 'nueva1234',
      );

      expect(passwordUpdated, isTrue);
      expect(message, 'Contraseña actualizada correctamente.');
    },
  );

  test('no actualiza cuando la contraseña actual es incorrecta', () async {
    var requests = 0;
    final service = PasswordService(
      client: MockClient((request) async {
        requests++;
        if (request.url.path == '/api/settings/profile') {
          return http.Response(
            jsonEncode({'id': 12, 'correo': 'user@test.com'}),
            200,
          );
        }
        return http.Response(
          jsonEncode({'message': 'Credenciales inválidas'}),
          401,
        );
      }),
    );

    await expectLater(
      service.changePassword(
        contrasenaActual: 'incorrecta',
        nuevaContrasena: 'nueva1234',
        confirmarContrasena: 'nueva1234',
      ),
      throwsA(isA<Exception>()),
    );
    expect(requests, 2);
  });
}
