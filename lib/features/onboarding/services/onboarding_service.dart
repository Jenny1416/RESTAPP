import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rest/core/config/api_config.dart';
import 'package:rest/core/services/user_session.dart';

import '../models/onboarding_models.dart';

class OnboardingException implements Exception {
  final String message;
  final int? statusCode;

  const OnboardingException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class OnboardingAlreadyCompletedException extends OnboardingException {
  const OnboardingAlreadyCompletedException()
    : super('El onboarding ya fue completado.', statusCode: 409);
}

class OnboardingService {
  final http.Client _client;
  final String _baseUrl;
  final String? Function() _tokenProvider;

  OnboardingService({
    http.Client? client,
    String? baseUrl,
    String? Function()? tokenProvider,
  }) : _client = client ?? http.Client(),
       _baseUrl = (baseUrl ?? ApiConfig.baseUrl).replaceFirst(
         RegExp(r'/$'),
         '',
       ),
       _tokenProvider = tokenProvider ?? (() => UserSession.authToken);

  Map<String, String> _headers({bool json = false}) {
    final token = _tokenProvider();
    if (token == null || token.isEmpty) {
      throw const OnboardingException(
        'Tu sesión expiró. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  Future<OnboardingStatus> getEstado() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/api/onboarding/estado'), headers: _headers())
        .timeout(const Duration(seconds: 20));
    final data = _decodeResponse(response);
    return OnboardingStatus.fromJson(data);
  }

  Future<OnboardingSurvey> getPreguntas() async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/api/onboarding/preguntas'),
          headers: _headers(),
        )
        .timeout(const Duration(seconds: 20));
    final survey = OnboardingSurvey.fromJson(_decodeResponse(response));
    if (!survey.completado && survey.preguntas.isEmpty) {
      throw const OnboardingException(
        'El backend no devolvió preguntas para el onboarding.',
      );
    }
    return survey;
  }

  Future<void> enviarRespuestas(Map<String, int> respuestas) async {
    if (respuestas.isEmpty) {
      throw const OnboardingException('Debes responder la encuesta.');
    }
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/onboarding/respuestas'),
          headers: _headers(json: true),
          body: jsonEncode({
            'respuestas': respuestas.entries
                .map(
                  (entry) => {'pregunta_id': entry.key, 'puntaje': entry.value},
                )
                .toList(),
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode == 409) {
      throw const OnboardingAlreadyCompletedException();
    }
    _decodeResponse(response);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic>? body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) body = Map<String, dynamic>.from(decoded);
    } catch (_) {
      body = null;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = body?['message']?.toString();
      throw OnboardingException(
        message?.isNotEmpty == true
            ? message!
            : 'No se pudo comunicar con el servicio de onboarding.',
        statusCode: response.statusCode,
      );
    }
    if (body == null) {
      throw const OnboardingException(
        'El backend devolvió una respuesta inválida.',
      );
    }
    return body;
  }
}
