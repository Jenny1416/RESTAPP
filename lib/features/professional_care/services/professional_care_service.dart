import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rest/core/config/api_config.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/features/professional_care/models/professional_care_models.dart';

class ProfessionalCareException implements Exception {
  const ProfessionalCareException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ProfessionalCareService {
  ProfessionalCareService({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl => ApiConfig.baseUrl;

  Map<String, String> _headers({bool json = false}) {
    final token = UserSession.authToken;
    if (token == null || token.isEmpty) {
      throw const ProfessionalCareException(
        'Tu sesión venció. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<List<Psychologist>> getPsychologists() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/psicologos'),
      headers: _headers(),
    );
    final decoded = _decode(response);
    final list = decoded is List ? decoded : const [];
    return list
        .whereType<Map>()
        .map((item) => Psychologist.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList();
  }

  Future<Psychologist> getPsychologist(int id) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/psicologos/$id'),
      headers: _headers(),
    );
    final decoded = _decode(response);
    if (decoded is! Map) {
      throw const ProfessionalCareException(
        'El profesional no está disponible.',
      );
    }
    return Psychologist.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<List<CareAssignment>> getMyAssignments() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/asignaciones/mis-solicitudes'),
      headers: _headers(),
    );
    final decoded = _unwrapData(_decode(response));
    final list = decoded is List ? decoded : const [];
    return list
        .whereType<Map>()
        .map((item) => CareAssignment.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.id > 0)
        .toList();
  }

  Future<CareAssignment> requestCare({
    required int psychologistId,
    String? message,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/asignaciones/solicitar'),
      headers: _headers(json: true),
      body: jsonEncode({
        'psicologo_id': psychologistId,
        if (message != null && message.trim().isNotEmpty)
          'mensaje': message.trim(),
      }),
    );
    final decoded = _unwrapData(_decode(response));
    if (decoded is! Map) {
      throw const ProfessionalCareException(
        'No se pudo registrar la solicitud.',
      );
    }
    return CareAssignment.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> closeAssignment(int assignmentId) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/api/asignaciones/$assignmentId'),
      headers: _headers(),
    );
    _decode(response);
  }

  Future<List<ProfessionalChat>> getChats() async {
    final results = await Future.wait([
      _client.get(Uri.parse('$_baseUrl/api/chats'), headers: _headers()),
      getMyAssignments(),
    ]);
    final response = results[0] as http.Response;
    final approvedPsychologists = (results[1] as List<CareAssignment>)
        .where((assignment) => assignment.isApproved)
        .map((assignment) => assignment.psychologistId)
        .whereType<int>()
        .toSet();
    final decoded = _decode(response);
    final list = decoded is List ? decoded : const [];
    return list
        .whereType<Map>()
        .map(
          (item) => ProfessionalChat.fromJson(Map<String, dynamic>.from(item)),
        )
        .where(
          (chat) =>
              chat.id > 0 &&
              chat.psychologistId != null &&
              approvedPsychologists.contains(chat.psychologistId),
        )
        .toList();
  }

  Future<ProfessionalChat> getOrCreateActiveChat(int psychologistId) async {
    final assignments = await getMyAssignments();
    final approved = assignments.any(
      (assignment) =>
          assignment.psychologistId == psychologistId && assignment.isApproved,
    );
    if (!approved) {
      throw const ProfessionalCareException(
        'El chat se habilita cuando el psicologo acepta tu solicitud.',
        statusCode: 403,
      );
    }

    final chats = await getChats();
    for (final chat in chats) {
      if (chat.psychologistId == psychologistId &&
          chat.isActive &&
          !chat.isAi) {
        return chat;
      }
    }

    final studentId = UserSession.userId;
    if (studentId == null) {
      throw const ProfessionalCareException(
        'No fue posible identificar tu sesión.',
      );
    }

    final response = await _client.post(
      Uri.parse('$_baseUrl/api/chats'),
      headers: _headers(json: true),
      body: jsonEncode({
        'estudiante_id': studentId,
        'psicologo_id': psychologistId,
        'is_active': true,
      }),
    );
    final decoded = _decode(response);
    if (decoded is! Map) {
      throw const ProfessionalCareException(
        'No se pudo abrir la conversación.',
      );
    }
    return ProfessionalChat.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<List<ProfessionalMessage>> getMessages(int chatId) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/chats/$chatId/mensajes'),
      headers: _headers(),
    );
    final decoded = _decode(response);
    final list = decoded is List ? decoded : const [];
    final messages = list
        .whereType<Map>()
        .map(
          (item) =>
              ProfessionalMessage.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.id > 0)
        .toList();
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return messages;
  }

  Future<ProfessionalMessage> sendMessage(int chatId, String message) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/chats/$chatId/mensajes'),
      headers: _headers(json: true),
      body: jsonEncode({'mensaje': message.trim()}),
    );
    final decoded = _decode(response);
    if (decoded is! Map) {
      throw const ProfessionalCareException('No se pudo enviar el mensaje.');
    }
    return ProfessionalMessage.fromJson(Map<String, dynamic>.from(decoded));
  }

  dynamic _decode(http.Response response) {
    dynamic decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = null;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded is Map
          ? (decoded['message'] ??
                    decoded['error'] ??
                    'No se pudo completar la operación.')
                .toString()
          : 'No se pudo completar la operación.';
      throw ProfessionalCareException(message, statusCode: response.statusCode);
    }
    return decoded;
  }

  dynamic _unwrapData(dynamic decoded) {
    if (decoded is Map && decoded.containsKey('data')) return decoded['data'];
    return decoded;
  }
}
