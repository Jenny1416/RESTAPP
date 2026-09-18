import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rest/core/config/api_config.dart';
import 'package:rest/core/services/user_session.dart';

class PasswordService {
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
    final response = await http.put(
      Uri.parse('$_baseUrl/api/settings/change-password'),
      headers: _authHeaders(),
      body: jsonEncode({
        'contrasenaActual': contrasenaActual,
        'nuevaContrasena': nuevaContrasena,
        'confirmarContrasena': confirmarContrasena,
      }),
    );

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        return decoded['message'].toString();
      }
      return 'Contraseña actualizada correctamente.';
    }

    var message = 'No se pudo actualizar la contraseña.';
    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] != null) message = decoded['message'].toString();
      if (decoded['errors'] != null) message = '$message: ${decoded['errors']}';
    }
    throw Exception(message);
  }
}
