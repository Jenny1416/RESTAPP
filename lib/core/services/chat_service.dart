import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rest/core/config/api_config.dart';

import 'user_session.dart';

class ChatAIResult {
  ChatAIResult({
    required this.respuesta,
    required this.requiereSalvavidas,
    required this.nivelAlerta,
    this.chatSalvavidasId,
    this.psicologoAsignadoId,
    this.mensajeSistema,
    this.chatId,
  });

  final String respuesta;
  final bool requiereSalvavidas;
  final String nivelAlerta;
  final int? chatSalvavidasId;
  final int? psicologoAsignadoId;
  final String? mensajeSistema;
  final int? chatId;
}

class ChatSessionSummary {
  ChatSessionSummary({
    required this.chatId,
    required this.iniciadoEn,
    required this.ultimaActividad,
    required this.isActive,
    required this.totalMensajes,
    required this.preview,
  });

  final int chatId;
  final DateTime iniciadoEn;
  final DateTime ultimaActividad;
  final bool isActive;
  final int totalMensajes;
  final String preview;
}

class ChatHistoryMessage {
  ChatHistoryMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final int id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
}

class ChatStopFeedback {
  ChatStopFeedback({
    required this.retroalimentacion,
    required this.consejos,
    required this.chatId,
  });

  final String retroalimentacion;
  final List<String> consejos;
  final int? chatId;
}

class ChatService {
  static String get _baseUrl => ApiConfig.baseUrl;

  Map<String, String> _headers() {
    final token = UserSession.authToken;
    if (token == null || token.isEmpty) {
      throw Exception('No hay sesion activa. Inicia sesion nuevamente.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<ChatAIResult> enviarMensajeNOA({
    required String mensaje,
    String? contexto,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/chats/ia');

    final response = await http
        .post(
          uri,
          headers: _headers(),
          body: jsonEncode({
            'mensaje': mensaje,
            if (contexto != null && contexto.trim().isNotEmpty)
              'contexto': contexto.trim(),
          }),
        )
        .timeout(const Duration(seconds: 40));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo enviar el mensaje (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? (decoded['data'] as Map<String, dynamic>? ?? <String, dynamic>{})
        : <String, dynamic>{};

    return ChatAIResult(
      respuesta: (data['respuesta_ia'] ?? 'No pude responder en este momento.')
          .toString(),
      requiereSalvavidas: data['requiere_salvavidas'] == true,
      nivelAlerta: (data['nivel_alerta'] ?? 'normal').toString(),
      chatSalvavidasId: (data['chat_salvavidas_id'] as num?)?.toInt(),
      psicologoAsignadoId: (data['psicologo_asignado_id'] as num?)?.toInt(),
      mensajeSistema: data['mensaje_sistema']?.toString(),
      chatId: (data['chat_id'] as num?)?.toInt(),
    );
  }

  Future<List<ChatSessionSummary>> fetchHistorialIA() async {
    final uri = Uri.parse('$_baseUrl/api/chats/ia/historial');
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo cargar historial (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? (decoded['data'] as Map<String, dynamic>? ?? <String, dynamic>{})
        : <String, dynamic>{};

    final historialRaw = data['historial'] as List? ?? const [];
    Set<int>? pureAiChatIds;
    try {
      final chatsResponse = await http.get(
        Uri.parse('$_baseUrl/api/chats'),
        headers: _headers(),
      );
      if (chatsResponse.statusCode >= 200 && chatsResponse.statusCode < 300) {
        final chatsDecoded = jsonDecode(chatsResponse.body);
        if (chatsDecoded is List) {
          pureAiChatIds = chatsDecoded
              .whereType<Map>()
              .where((chat) {
                final isAi =
                    chat['isSendByAi'] == true || chat['is_send_by_ai'] == true;
                return isAi && chat['psicologo_id'] == null;
              })
              .map((chat) => (chat['id'] as num?)?.toInt() ?? 0)
              .where((id) => id > 0)
              .toSet();
        }
      }
    } catch (_) {
      // El historial principal sigue siendo util si el filtro auxiliar falla.
    }

    final sessions = historialRaw.whereType<Map>().map((item) {
      final iniciadoRaw = (item['iniciado_en'] ?? '').toString();
      final ultimaRaw = (item['ultima_actividad'] ?? '').toString();
      return ChatSessionSummary(
        chatId: (item['chat_id'] as num?)?.toInt() ?? 0,
        iniciadoEn: DateTime.tryParse(iniciadoRaw) ?? DateTime.now(),
        ultimaActividad: DateTime.tryParse(ultimaRaw) ?? DateTime.now(),
        isActive: item['is_active'] == true,
        totalMensajes: (item['total_mensajes'] as num?)?.toInt() ?? 0,
        preview: (item['preview'] ?? 'Conversacion con NOA').toString(),
      );
    });

    return sessions
        .where(
          (session) =>
              pureAiChatIds == null || pureAiChatIds.contains(session.chatId),
        )
        .toList();
  }

  Future<List<ChatHistoryMessage>> fetchMensajesChat(int chatId) async {
    final uri = Uri.parse('$_baseUrl/api/chats/$chatId/mensajes');
    final response = await http.get(uri, headers: _headers());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo cargar mensajes (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final list = decoded is List ? decoded : const [];
    final userId = UserSession.userId;

    final messages = list.whereType<Map>().map((item) {
      final userMessageId = (item['usuario_id'] as num?)?.toInt();
      final text = (item['mensaje'] ?? '').toString();
      final enviadoEn = (item['enviado_en'] ?? '').toString();
      return ChatHistoryMessage(
        id: (item['id'] as num?)?.toInt() ?? 0,
        text: text,
        isUser: userId != null && userMessageId == userId,
        timestamp: DateTime.tryParse(enviadoEn) ?? DateTime.now(),
      );
    }).toList();

    return messages.reversed.toList();
  }

  Future<ChatStopFeedback> detenerSesionIA() async {
    final uri = Uri.parse('$_baseUrl/api/chats/ia/detener');
    final response = await http.post(uri, headers: _headers());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo detener chat (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? (decoded['data'] as Map<String, dynamic>? ?? <String, dynamic>{})
        : <String, dynamic>{};

    final consejosRaw = data['consejos'] as List? ?? const [];
    return ChatStopFeedback(
      retroalimentacion:
          (data['retroalimentacion'] ?? 'Gracias por conversar con NOA.')
              .toString(),
      consejos: consejosRaw.map((e) => e.toString()).toList(),
      chatId: (data['chat_id'] as num?)?.toInt(),
    );
  }
}
