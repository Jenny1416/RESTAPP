import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rest/core/config/api_config.dart';

import 'user_session.dart';

class PersonalWeekDay {
  PersonalWeekDay({
    required this.fecha,
    required this.dia,
    required this.registroEmocional,
    required this.estrellaActivada,
  });

  final String fecha;
  final String dia;
  final bool registroEmocional;
  final bool estrellaActivada;
}

class FrequentMood {
  FrequentMood({required this.nombre, required this.total});

  final String nombre;
  final int total;
}

class EvolutionPoint {
  EvolutionPoint({required this.fecha, required this.promedio});

  final String fecha;
  final double promedio;
}

class MoodEvolution {
  MoodEvolution({
    required this.tendencia,
    required this.promedioUltimos7Dias,
    required this.promedio7DiasAnteriores,
    required this.serieUltimos7Dias,
  });

  final String tendencia;
  final double promedioUltimos7Dias;
  final double promedio7DiasAnteriores;
  final List<EvolutionPoint> serieUltimos7Dias;
}

class PersonalDashboardSummary {
  PersonalDashboardSummary({
    required this.diasTrabajadosEnMi,
    required this.rachaActual,
    required this.rachaMaximaHistorica,
    required this.diasSinRegistrar,
    required this.ultimoRegistro,
    required this.estrellaHoyActivada,
    required this.puedeActivarEstrellaHoy,
    required this.estrellasRachaTotal,
    required this.estrellasRachaMesActual,
    required this.estadoAnimoMasFrecuente,
    required this.emocionesFrecuentes,
    required this.evolucionEstadoAnimo,
    required this.semanaActual,
  });

  final int diasTrabajadosEnMi;
  final int rachaActual;
  final int rachaMaximaHistorica;
  final int diasSinRegistrar;
  final String? ultimoRegistro;
  final bool estrellaHoyActivada;
  final bool puedeActivarEstrellaHoy;
  final int estrellasRachaTotal;
  final int estrellasRachaMesActual;
  final FrequentMood? estadoAnimoMasFrecuente;
  final List<FrequentMood> emocionesFrecuentes;
  final MoodEvolution evolucionEstadoAnimo;
  final List<PersonalWeekDay> semanaActual;
}

class DailyStreakActivationResult {
  DailyStreakActivationResult({
    required this.activada,
    required this.mensaje,
    required this.fecha,
    required this.estrellaOtorgada,
    required this.totalEstrellasRacha,
    required this.estrellasRachaMesActual,
  });

  final bool activada;
  final String mensaje;
  final String fecha;
  final int estrellaOtorgada;
  final int totalEstrellasRacha;
  final int estrellasRachaMesActual;
}

class PersonalProgressService {
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

  Future<PersonalDashboardSummary> fetchPantallaPersonal() async {
    final uri = Uri.parse('$_baseUrl/api/registro-emocional/pantalla-personal');
    final response = await http.get(uri, headers: _authHeaders());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo cargar pantalla personal (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? (decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : decoded)
        : <String, dynamic>{};

    final estadoFrecuenteRaw = data['estado_animo_mas_frecuente'];
    final estadoFrecuente = estadoFrecuenteRaw is Map<String, dynamic>
        ? FrequentMood(
            nombre: (estadoFrecuenteRaw['nombre'] ?? 'Sin datos').toString(),
            total: (estadoFrecuenteRaw['total'] as num?)?.toInt() ?? 0,
          )
        : null;

    final emocionesFrecuentesRaw =
        data['emociones_frecuentes'] as List? ?? const [];
    final emocionesFrecuentes = emocionesFrecuentesRaw
        .whereType<Map>()
        .map(
          (item) => FrequentMood(
            nombre: (item['nombre'] ?? 'Sin datos').toString(),
            total: (item['total'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();

    final evolucionRaw = data['evolucion_estado_animo'] is Map<String, dynamic>
        ? data['evolucion_estado_animo'] as Map<String, dynamic>
        : <String, dynamic>{};

    final serieRaw = evolucionRaw['serie_ultimos_7_dias'] as List? ?? const [];
    final serie = serieRaw
        .whereType<Map>()
        .map(
          (item) => EvolutionPoint(
            fecha: (item['fecha'] ?? '').toString(),
            promedio: (item['promedio'] as num?)?.toDouble() ?? 0,
          ),
        )
        .toList();

    final semanaRaw = data['semana_actual'] as List? ?? const [];
    final semana = semanaRaw
        .whereType<Map>()
        .map(
          (item) => PersonalWeekDay(
            fecha: (item['fecha'] ?? '').toString(),
            dia: (item['dia'] ?? '').toString(),
            registroEmocional: item['registro_emocional'] == true,
            estrellaActivada: item['estrella_activada'] == true,
          ),
        )
        .toList();

    return PersonalDashboardSummary(
      diasTrabajadosEnMi: (data['dias_trabajados_en_mi'] as num?)?.toInt() ?? 0,
      rachaActual: (data['racha_actual'] as num?)?.toInt() ?? 0,
      rachaMaximaHistorica:
          (data['racha_maxima_historica'] as num?)?.toInt() ?? 0,
      diasSinRegistrar: (data['dias_sin_registrar'] as num?)?.toInt() ?? 0,
      ultimoRegistro: data['ultimo_registro']?.toString(),
      estrellaHoyActivada: data['estrella_hoy_activada'] == true,
      puedeActivarEstrellaHoy: data['puede_activar_estrella_hoy'] == true,
      estrellasRachaTotal:
          (data['estrellas_racha_total'] as num?)?.toInt() ?? 0,
      estrellasRachaMesActual:
          (data['estrellas_racha_mes_actual'] as num?)?.toInt() ?? 0,
      estadoAnimoMasFrecuente: estadoFrecuente,
      emocionesFrecuentes: emocionesFrecuentes,
      evolucionEstadoAnimo: MoodEvolution(
        tendencia: (evolucionRaw['tendencia'] ?? 'estable').toString(),
        promedioUltimos7Dias:
            (evolucionRaw['promedio_ultimos_7_dias'] as num?)?.toDouble() ?? 0,
        promedio7DiasAnteriores:
            (evolucionRaw['promedio_7_dias_anteriores'] as num?)?.toDouble() ??
            0,
        serieUltimos7Dias: serie,
      ),
      semanaActual: semana,
    );
  }

  Future<DailyStreakActivationResult> activarRachaDiaria() async {
    final uri = Uri.parse(
      '$_baseUrl/api/registro-emocional/pantalla-personal/activar-racha',
    );

    final response = await http.post(
      uri,
      headers: _authHeaders(withJson: true),
      body: jsonEncode({}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo activar la racha diaria (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? (decoded['data'] is Map<String, dynamic>
              ? decoded['data'] as Map<String, dynamic>
              : decoded)
        : <String, dynamic>{};

    return DailyStreakActivationResult(
      activada: data['activada'] == true || data['activated_today'] == true,
      mensaje: (data['mensaje'] ?? 'Racha procesada').toString(),
      fecha: (data['fecha'] ?? '').toString(),
      estrellaOtorgada: (data['estrella_otorgada'] as num?)?.toInt() ?? 0,
      totalEstrellasRacha:
          (data['total_estrellas_racha'] as num?)?.toInt() ?? 0,
      estrellasRachaMesActual:
          (data['estrellas_racha_mes_actual'] as num?)?.toInt() ?? 0,
    );
  }
}
