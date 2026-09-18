import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rest/core/config/api_config.dart';
import 'package:rest/core/services/user_session.dart';

import '../models/evaluation.dart';

class EvaluationService {
  final http.Client _client;
  final String _baseUrl;
  final String? Function() _tokenProvider;

  EvaluationService({
    http.Client? client,
    String? baseUrl,
    String? Function()? tokenProvider,
  }) : _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(
         RegExp(r'/$'),
         '',
       ),
       _tokenProvider = tokenProvider ?? (() => UserSession.authToken);

  Map<String, String> get _headers {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      throw Exception('Tu sesión expiró. Inicia sesión nuevamente.');
    }
    return {'Authorization': 'Bearer $token'};
  }

  Future<List<Evaluation>> getEvaluaciones() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/api/evaluaciones'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    if (decoded is! List) throw Exception('Formato de evaluaciones inválido.');
    return decoded
        .whereType<Map>()
        .map((item) => Evaluation.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Evaluation> getEvaluacion(int id) async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/api/evaluaciones/$id'), headers: _headers)
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    if (decoded is! Map) throw Exception('Formato de evaluación inválido.');
    return Evaluation.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<List<Map<String, dynamic>>> getPreguntas() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/api/evaluaciones/preguntas'))
        .timeout(const Duration(seconds: 20));
    final decoded = _decode(response);
    final list = decoded is Map ? decoded['data'] : decoded;
    if (list is! List) throw Exception('Formato de preguntas inválido.');
    return list.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
  }

  Future<Map<String, dynamic>> submitEvaluation(
      List<Map<String, int>> respuestas) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/evaluaciones'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({'respuestas': respuestas}),
    );
    final decoded = _decode(response);
    if (decoded is Map) return Map<String, dynamic>.from(decoded['data'] is Map ? decoded['data'] as Map : decoded);
    throw Exception('Respuesta de evaluación inválida.');
  }

  Future<Map<String, dynamic>> assignTrafficLight() async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/evaluaciones/asignacion-semaforo'),
      headers: {..._headers, 'Content-Type': 'application/json'},
      body: jsonEncode({}),
    );
    final decoded = _decode(response);
    if (decoded is Map) return Map<String, dynamic>.from(decoded['data'] is Map ? decoded['data'] as Map : decoded);
    return <String, dynamic>{};
  }

  dynamic _decode(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('El backend devolvió una respuesta inválida.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map ? decoded['message']?.toString() : null;
      throw Exception(message ?? 'No se pudieron cargar las evaluaciones.');
    }
    return decoded;
  }
}
