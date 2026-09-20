import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rest/core/services/settings_service.dart';
import 'package:rest/core/services/user_session.dart';

void main() {
  setUp(() => UserSession.authToken = 'test-token');
  tearDown(() => UserSession.authToken = null);

  test('lee el campo texto de los documentos legales del backend', () async {
    final service = SettingsService(
      client: MockClient((request) async {
        expect(request.url.path, '/api/settings/privacy-policy');
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          jsonEncode({
            'codigo': 'privacy_policy',
            'titulo': 'Aviso de privacidad',
            'texto': 'Contenido legal vigente',
          }),
          200,
        );
      }),
    );

    expect(
      await service.document('/api/settings/privacy-policy'),
      'Contenido legal vigente',
    );
  });
}
