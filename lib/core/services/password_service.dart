import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rest/core/config/api_config.dart';
import 'package:rest/core/services/user_session.dart';

class PasswordService {
  PasswordService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static String get _baseUrl => ApiConfig.baseUrl;

  Map<String, String> _authHeaders() {
    final token = UserSession.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa. Inicia sesión nuevamente.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<String> changePassword({
    required String contrasenaActual,
    required String nuevaContrasena,
    required String confirmarContrasena,
  }) async {
    if (nuevaContrasena != confirmarContrasena) {
      throw Exception('Las contraseñas nuevas no coinciden.');
    }

    final profileResponse = await _client.get(
      Uri.parse('$_baseUrl/api/settings/profile'),
      headers: _authHeaders(),
    );
    final profile = _decodeOrThrow(
      profileResponse,
      fallback: 'No se pudo consultar el perfil.',
    );
    if (profile is! Map || profile['correo'] == null || profile['id'] == null) {
      throw Exception('No fue posible identificar la cuenta actual.');
    }

    final loginResponse = await _client.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'correo': profile['correo'].toString(),
        'contrasena': contrasenaActual,
      }),
    );
    _decodeOrThrow(
      loginResponse,
      fallback: 'La contraseña actual no es correcta.',
    );

    final updateResponse = await _client.patch(
      Uri.parse('$_baseUrl/api/users/${profile['id']}'),
      headers: _authHeaders(),
      body: jsonEncode({'contrasena': nuevaContrasena}),
    );
    _decodeOrThrow(
      updateResponse,
      fallback: 'No se pudo actualizar la contraseña.',
    );
    return 'Contraseña actualizada correctamente.';
  }

  dynamic _decodeOrThrow(http.Response response, {required String fallback}) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map && decoded['message'] != null
          ? decoded['message'].toString()
          : fallback;
      throw Exception(message);
    }
    return decoded;
  }
}
