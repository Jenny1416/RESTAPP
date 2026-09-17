import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rest/core/config/api_config.dart';

import 'user_session.dart';

class DailyActivity {
  DailyActivity({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.imageUrl,
  });

  final int id;
  final String nombre;
  final String descripcion;
  final String? imageUrl;
}

class DailyActivitiesSummary {
  DailyActivitiesSummary({
    required this.hechas,
    required this.pendientes,
    required this.totalObjetivoDiario,
    required this.totalHechas,
    required this.totalPendientes,
    required this.estrellasMesActual,
    required this.metaEstrellasMesActual,
    required this.estadoSemaforo,
  });

  final List<DailyActivity> hechas;
  final List<DailyActivity> pendientes;
  final int totalObjetivoDiario;
  final int totalHechas;
  final int totalPendientes;
  final int estrellasMesActual;
  final int metaEstrellasMesActual;
  final String estadoSemaforo;
}

class RelaxTechnique {
  RelaxTechnique({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.imageUrl,
  });

  final int id;
  final String nombre;
  final String descripcion;
  final String? imageUrl;
}

class RewardItem {
  RewardItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.estrellasRequeridas,
    required this.solicitarHabilitado,
    required this.estrellasFaltantes,
  });

  final int id;
  final String nombre;
  final String descripcion;
  final int estrellasRequeridas;
  final bool solicitarHabilitado;
  final int estrellasFaltantes;
}

class RewardRequest {
  RewardRequest({
    required this.id,
    required this.estado,
    required this.estrellasRequeridas,
    required this.solicitadoEn,
    required this.premioNombre,
  });

  final int id;
  final String estado;
  final int estrellasRequeridas;
  final DateTime solicitadoEn;
  final String premioNombre;
}

class RewardsCatalogSummary {
  RewardsCatalogSummary({
    required this.periodoAnio,
    required this.periodoMes,
    required this.estrellasAcumuladas,
    required this.estrellasReservadas,
    required this.estrellasDisponibles,
    required this.premios,
    required this.solicitudes,
  });

  final int periodoAnio;
  final int periodoMes;
  final int estrellasAcumuladas;
  final int estrellasReservadas;
  final int estrellasDisponibles;
  final List<RewardItem> premios;
  final List<RewardRequest> solicitudes;
}

class ProgressService {
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

  Future<DailyActivitiesSummary> fetchActividadesDiarias() async {
    final uri = Uri.parse('$_baseUrl/api/registro-actividades/diarias');
    final response = await http.get(uri, headers: _authHeaders());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudieron cargar actividades diarias (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    final hechasRaw = data['actividades_realizadas_hoy'] as List? ?? const [];
    final pendientesRaw = data['actividades_pendientes'] as List? ?? const [];

    List<DailyActivity> parseHechas(List raw) {
      return raw.whereType<Map>().map((item) {
        final opcion = (item['opcion'] as Map?) ?? const {};
        return DailyActivity(
          id: (item['opcion_id'] as num?)?.toInt() ?? 0,
          nombre: (opcion['nombre'] ?? 'Actividad').toString(),
          descripcion: (opcion['descripcion'] ?? '').toString(),
          imageUrl: opcion['url_imagen']?.toString(),
        );
      }).toList();
    }

    List<DailyActivity> parsePendientes(List raw) {
      return raw
          .whereType<Map>()
          .map(
            (item) => DailyActivity(
              id: (item['id'] as num?)?.toInt() ?? 0,
              nombre: (item['nombre'] ?? 'Actividad').toString(),
              descripcion: (item['descripcion'] ?? '').toString(),
              imageUrl: item['url_imagen']?.toString(),
            ),
          )
          .toList();
    }

    return DailyActivitiesSummary(
      hechas: parseHechas(hechasRaw),
      pendientes: parsePendientes(pendientesRaw),
      totalObjetivoDiario:
          (data['total_objetivo_diario'] as num?)?.toInt() ?? 5,
      totalHechas: (data['total_realizadas_hoy'] as num?)?.toInt() ?? 0,
      totalPendientes: (data['total_pendientes'] as num?)?.toInt() ?? 0,
      estrellasMesActual: (data['estrellas_mes_actual'] as num?)?.toInt() ?? 0,
      metaEstrellasMesActual:
          (data['meta_estrellas_mes_actual'] as num?)?.toInt() ?? 150,
      estadoSemaforo: (data['estado_semaforo_actual'] ?? 'sin_evaluar')
          .toString(),
    );
  }

  Future<void> completarActividadDiaria({required int opcionId}) async {
    final uri = Uri.parse('$_baseUrl/api/registro-actividades/diarias/asignar');
    final body = jsonEncode({'opcion_id': opcionId});

    final response = await http.post(
      uri,
      headers: _authHeaders(withJson: true),
      body: body,
    );

    if (response.statusCode == 409) {
      return;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo completar la actividad (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<List<RelaxTechnique>> fetchTecnicasRelajacion() async {
    final uri = Uri.parse(
      '$_baseUrl/api/registro-actividades/tecnicas-relajacion',
    );
    final response = await http.get(uri, headers: _authHeaders());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudieron cargar técnicas (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? decoded['tecnicas'] as List? ?? const []
        : const [];

    return data
        .whereType<Map>()
        .map(
          (item) => RelaxTechnique(
            id: (item['id'] as num?)?.toInt() ?? 0,
            nombre: (item['nombre'] ?? 'Técnica').toString(),
            descripcion: (item['descripcion'] ?? '').toString(),
            imageUrl: item['url_imagen']?.toString(),
          ),
        )
        .toList();
  }

  Future<void> registrarPracticaTecnica({
    required int opcionId,
    String? observaciones,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/registro-actividades/tecnicas-relajacion/practicar',
    );

    final response = await http.post(
      uri,
      headers: _authHeaders(withJson: true),
      body: jsonEncode({
        'opcion_id': opcionId,
        if (observaciones != null && observaciones.isNotEmpty)
          'observaciones': observaciones,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo registrar la práctica (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<RewardsCatalogSummary> fetchRewardsCatalog() async {
    final uri = Uri.parse('$_baseUrl/api/premios/catalogo');
    final response = await http.get(uri, headers: _authHeaders());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo cargar premios (${response.statusCode}): ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    final periodo = data['periodo'] is Map<String, dynamic>
        ? data['periodo'] as Map<String, dynamic>
        : <String, dynamic>{};
    final estrellas = data['estrellas'] is Map<String, dynamic>
        ? data['estrellas'] as Map<String, dynamic>
        : <String, dynamic>{};

    final premiosRaw = data['premios'] as List? ?? const [];
    final solicitudesRaw = data['solicitudes'] as List? ?? const [];

    final premios = premiosRaw.whereType<Map>().map((item) {
      return RewardItem(
        id: (item['id'] as num?)?.toInt() ?? 0,
        nombre: (item['nombre'] ?? 'Premio').toString(),
        descripcion: (item['descripcion'] ?? '').toString(),
        estrellasRequeridas:
            (item['estrellas_requeridas'] as num?)?.toInt() ?? 0,
        solicitarHabilitado: item['solicitar_habilitado'] == true,
        estrellasFaltantes: (item['estrellas_faltantes'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    final solicitudes = solicitudesRaw.whereType<Map>().map((item) {
      final solicitadoRaw = (item['solicitado_en'] ?? '').toString();
      return RewardRequest(
        id: (item['id'] as num?)?.toInt() ?? 0,
        estado: (item['estado'] ?? 'pendiente').toString(),
        estrellasRequeridas:
            (item['estrellas_requeridas'] as num?)?.toInt() ?? 0,
        solicitadoEn: DateTime.tryParse(solicitadoRaw) ?? DateTime.now(),
        premioNombre: (item['premio_nombre'] ?? 'Premio').toString(),
      );
    }).toList();

    return RewardsCatalogSummary(
      periodoAnio: (periodo['anio'] as num?)?.toInt() ?? DateTime.now().year,
      periodoMes: (periodo['mes'] as num?)?.toInt() ?? DateTime.now().month,
      estrellasAcumuladas: (estrellas['acumuladas'] as num?)?.toInt() ?? 0,
      estrellasReservadas: (estrellas['reservadas'] as num?)?.toInt() ?? 0,
      estrellasDisponibles: (estrellas['disponibles'] as num?)?.toInt() ?? 0,
      premios: premios,
      solicitudes: solicitudes,
    );
  }

  Future<void> requestReward({required int premioId}) async {
    final uri = Uri.parse('$_baseUrl/api/premios/solicitar');
    final response = await http.post(
      uri,
      headers: _authHeaders(withJson: true),
      body: jsonEncode({'premio_id': premioId}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'No se pudo solicitar premio (${response.statusCode}): ${response.body}',
      );
    }
  }
}
