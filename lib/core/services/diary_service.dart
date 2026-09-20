import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rest/core/config/api_config.dart';

import 'user_session.dart';

class DiaryEntry {
  DiaryEntry({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.fecha,
  });

  final int id;
  final String titulo;
  final String contenido;
  final DateTime fecha;
}

class DiaryService {
  static String get _baseUrl => ApiConfig.baseUrl;

  Map<String, String> _authHeaders({bool withJson = false}) {
    final token = UserSession.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesión activa. Inicia sesión nuevamente.');
    }

    return {
      'Authorization': 'Bearer $token',
      if (withJson) 'Content-Type': 'application/json',
    };
  }

  Future<void> createEntry({
    required String titulo,
    required String contenido,
    DateTime? fecha,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/diario');

    final response = await http.post(
      uri,
      headers: _authHeaders(withJson: true),
      body: jsonEncode({
        'titulo': titulo.trim(),
        'contenido': contenido.trim(),
        if (fecha != null) 'fecha': fecha.toUtc().toIso8601String(),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo guardar la entrada (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<List<DiaryEntry>> fetchEntries() async {
    final uri = Uri.parse('$_baseUrl/api/diario');

    final response = await http.get(uri, headers: _authHeaders());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo cargar el diario (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final list = decoded is List ? decoded : const [];

    final entries = list.whereType<Map>().map((item) {
      final fechaRaw = (item['fecha'] ?? '').toString();
      final parsedDate = DateTime.tryParse(fechaRaw) ?? DateTime.now();
      return DiaryEntry(
        id: (item['id'] as num?)?.toInt() ?? 0,
        titulo: (item['titulo'] ?? 'Sin titulo').toString(),
        contenido: (item['contenido'] ?? '').toString(),
        fecha: parsedDate,
      );
    }).toList();

    entries.sort((a, b) => b.fecha.compareTo(a.fecha));
    return entries;
  }

  Future<DiaryEntry> fetchEntry(int id) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/diario/$id'),
      headers: _authHeaders(),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo cargar la entrada (${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body);
    final data = decoded is Map && decoded['data'] is Map
        ? decoded['data'] as Map
        : decoded;
    if (data is! Map) throw Exception('Respuesta de diario inválida.');
    final fecha = DateTime.tryParse((data['fecha'] ?? '').toString()) ?? DateTime.now();
    return DiaryEntry(
      id: (data['id'] as num?)?.toInt() ?? id,
      titulo: (data['titulo'] ?? '').toString(),
      contenido: (data['contenido'] ?? '').toString(),
      fecha: fecha,
    );
  }

  Future<void> updateEntry({
    required int id,
    required String titulo,
    required String contenido,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/api/diario/$id'),
      headers: _authHeaders(withJson: true),
      body: jsonEncode({'titulo': titulo.trim(), 'contenido': contenido.trim()}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No se pudo actualizar la entrada (${response.statusCode}).');
    }
  }
}
