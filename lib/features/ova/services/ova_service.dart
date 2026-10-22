import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rest/core/config/api_config.dart';
import 'package:rest/core/services/user_session.dart';

import '../models/ova_models.dart';

class OvaException implements Exception {
  const OvaException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Consume `/api/ovas/*`: actividades (OVA) asignadas al estudiante.
class OvaService {
  OvaService({
    http.Client? client,
    String? baseUrl,
    String? Function()? tokenProvider,
  }) : _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(
         RegExp(r'/$'),
         '',
       ),
       _tokenProvider = tokenProvider ?? (() => UserSession.authToken);

  final http.Client _client;
  final String _baseUrl;
  final String? Function() _tokenProvider;

  static const _timeout = Duration(seconds: 20);

  Map<String, String> _headers({bool json = false}) {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      throw const OvaException(
        'Tu sesión venció. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  /// Actividades por hacer y completadas que aún esperan la medición posterior.
  Future<List<OvaAsignacion>> getAsignaciones() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/api/ovas/asignaciones'), headers: _headers())
        .timeout(_timeout);
    final decoded = _decode(response);
    final list = decoded is Map ? decoded['asignaciones'] : decoded;
    if (list is! List) {
      throw const OvaException('No pudimos leer tus actividades.');
    }
    return list
        .whereType<Map>()
        .map((item) => OvaAsignacion.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList();
  }

  Future<OvaAsignacion> getAsignacion(int id) async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/api/ovas/asignaciones/$id'),
          headers: _headers(),
        )
        .timeout(_timeout);
    final decoded = _decode(response);
    if (decoded is! Map) {
      throw const OvaException('No pudimos leer la actividad.');
    }
    return OvaAsignacion.fromJson(Map<String, dynamic>.from(decoded));
  }

  /// Marca la actividad como en curso. Es idempotente en el backend.
  Future<void> iniciar(int id) async {
    final response = await _client
        .patch(
          Uri.parse('$_baseUrl/api/ovas/asignaciones/$id/iniciar'),
          headers: _headers(),
        )
        .timeout(_timeout);
    _decode(response);
  }

  Future<OvaCompletada> completar(
    int id, {
    required bool liked,
    int? rating,
  }) async {
    if (rating != null && (rating < 1 || rating > 5)) {
      throw ArgumentError.value(rating, 'rating', 'Debe estar entre 1 y 5');
    }
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/ovas/asignaciones/$id/completar'),
          headers: _headers(json: true),
          body: jsonEncode({'liked': liked, 'rating': ?rating}),
        )
        .timeout(_timeout);
    final decoded = _decode(response);
    final data = decoded is Map ? decoded : const <String, dynamic>{};
    return OvaCompletada(
      requierePostTest: data['requiere_post_test'] != false,
      preEvaluacionId: (data['pre_evaluacion_id'] as num?)?.toInt(),
    );
  }

  Future<void> omitir(int id, OvaOmision tipo) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/ovas/asignaciones/$id/omitir'),
          headers: _headers(json: true),
          body: jsonEncode({'estado': tipo.apiValue}),
        )
        .timeout(_timeout);
    _decode(response);
  }

  dynamic _decode(http.Response response) {
    dynamic decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      throw OvaException(
        'El servidor devolvió una respuesta inválida.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    if (response.statusCode == 401) {
      throw const OvaException(
        'Tu sesión venció. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }
    final message = decoded is Map ? decoded['message']?.toString() : null;
    throw OvaException(
      message ?? 'No pudimos completar la acción. Intenta de nuevo.',
      statusCode: response.statusCode,
    );
  }
}
