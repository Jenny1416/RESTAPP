import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rest/core/config/api_config.dart';
import 'package:rest/core/services/user_session.dart';

class SettingsService {
  SettingsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Map<String, String> _headers() {
    final token = UserSession.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa.');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<void> report({required String titulo, required String descripcion}) =>
      _send('POST', '/api/settings/report', {
        'titulo': titulo,
        'descripcion': descripcion,
      });

  Future<void> feedback({
    required int puntaje,
    required String queMasTeGusto,
    String? comentarios,
  }) => _send('POST', '/api/settings/feedback', {
    'puntaje': puntaje,
    'que_mas_te_gusto': queMasTeGusto,
    if (comentarios != null && comentarios.trim().isNotEmpty)
      'comentarios': comentarios.trim(),
  });

  Future<void> preference(String idioma) =>
      _send('PUT', '/api/settings/preferences', {'idioma': idioma});

  Future<String> document(String path) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: _headers(),
    );
    final data = _validate(response);
    if (data is Map) {
      return (data['data'] ??
              data['texto'] ??
              data['contenido'] ??
              data['content'] ??
              '')
          .toString();
    }
    return data?.toString() ?? '';
  }

  Future<void> _send(
    String method,
    String path,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final response = method == 'POST'
        ? await _client.post(uri, headers: _headers(), body: jsonEncode(body))
        : await _client.put(uri, headers: _headers(), body: jsonEncode(body));
    _validate(response);
  }

  dynamic _validate(http.Response response) {
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {}
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data is Map
            ? (data['message'] ?? 'No se pudo completar la operación.')
            : 'No se pudo completar la operación.',
      );
    }
    return data;
  }
}
