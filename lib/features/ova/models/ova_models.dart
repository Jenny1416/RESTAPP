/// Estado de una asignación OVA tal como lo devuelve el backend.
enum OvaEstado {
  pending,
  inProgress,
  completed,
  skipped,
  dismissed,
  unknown;

  static OvaEstado parse(Object? value) {
    switch (value?.toString().trim().toUpperCase()) {
      case 'PENDING':
        return OvaEstado.pending;
      case 'IN_PROGRESS':
        return OvaEstado.inProgress;
      case 'COMPLETED':
        return OvaEstado.completed;
      case 'SKIPPED':
        return OvaEstado.skipped;
      case 'DISMISSED':
        return OvaEstado.dismissed;
      default:
        return OvaEstado.unknown;
    }
  }
}

/// Formas de dejar una actividad sin hacer.
enum OvaOmision {
  skipped('SKIPPED'),
  dismissed('DISMISSED');

  const OvaOmision(this.apiValue);
  final String apiValue;
}

enum OvaTipo {
  video,
  respiracion,
  ejercicioPractico,
  otro;

  static OvaTipo parse(Object? value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'video':
        return OvaTipo.video;
      case 'respiracion':
        return OvaTipo.respiracion;
      case 'ejercicio_practico':
        return OvaTipo.ejercicioPractico;
      default:
        return OvaTipo.otro;
    }
  }
}

enum OvaFuente {
  youtube,
  cloudflareR2,
  externalUrl,
  otro;

  static OvaFuente parse(Object? value) {
    switch (value?.toString().trim().toUpperCase()) {
      case 'YOUTUBE':
        return OvaFuente.youtube;
      case 'CLOUDFLARE_R2':
        return OvaFuente.cloudflareR2;
      case 'EXTERNAL_URL':
        return OvaFuente.externalUrl;
      default:
        return OvaFuente.otro;
    }
  }
}

/// Cómo se debe mostrar un recurso en la app.
enum OvaMedia { youtube, video, audio, imagen, pdf, enlace }

class OvaRecurso {
  const OvaRecurso({
    required this.fuente,
    required this.originalUrl,
    required this.resolvedUrl,
    this.videoId,
    this.watchUrl,
    this.embedUrl,
  });

  final OvaFuente fuente;
  final String originalUrl;
  final String resolvedUrl;
  final String? videoId;
  final String? watchUrl;
  final String? embedUrl;

  /// `true` cuando hay una URL que el dispositivo puede abrir. Una key de R2
  /// sin dominio (servidor sin R2_PUBLIC_BASE_URL) no es utilizable.
  bool get esUtilizable {
    if (fuente == OvaFuente.youtube && (videoId?.isNotEmpty ?? false)) {
      return true;
    }
    return _isHttp(urlParaAbrir);
  }

  /// URL que se abre fuera de la app (navegador o visor del sistema).
  String get urlParaAbrir {
    if (fuente == OvaFuente.youtube) {
      final watch = watchUrl;
      if (watch != null && watch.isNotEmpty) return watch;
      return originalUrl;
    }
    return resolvedUrl;
  }

  OvaMedia get media {
    if (fuente == OvaFuente.youtube) {
      return (videoId?.isNotEmpty ?? false) ? OvaMedia.youtube : OvaMedia.enlace;
    }
    final path = (Uri.tryParse(resolvedUrl)?.path ?? resolvedUrl).toLowerCase();
    if (path.endsWith('.mp4') ||
        path.endsWith('.webm') ||
        path.endsWith('.mov')) {
      return OvaMedia.video;
    }
    if (path.endsWith('.mp3') || path.endsWith('.m4a')) return OvaMedia.audio;
    if (path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp')) {
      return OvaMedia.imagen;
    }
    if (path.endsWith('.pdf')) return OvaMedia.pdf;
    return OvaMedia.enlace;
  }

  factory OvaRecurso.fromJson(
    Map<String, dynamic>? json, {
    Object? fallbackSource,
    Object? fallbackUrl,
  }) {
    final data = json ?? const <String, dynamic>{};
    final original = _text(data['original_url']) ?? _text(fallbackUrl) ?? '';
    return OvaRecurso(
      fuente: OvaFuente.parse(data['storage_source'] ?? fallbackSource),
      originalUrl: original,
      resolvedUrl: _text(data['resolved_url']) ?? original,
      videoId: _text(data['video_id']),
      watchUrl: _text(data['watch_url']),
      embedUrl: _text(data['embed_url']),
    );
  }
}

class OvaInfo {
  const OvaInfo({
    required this.id,
    required this.titulo,
    required this.tipo,
    required this.duracionMinutos,
    required this.recurso,
    this.descripcion,
  });

  final int id;
  final String titulo;
  final String? descripcion;
  final OvaTipo tipo;
  final int duracionMinutos;
  final OvaRecurso recurso;

  factory OvaInfo.fromJson(Map<String, dynamic> json) {
    // GET /api/ovas/asignaciones trae `recurso`; la respuesta de crear una
    // evaluación trae `recurso_resuelto` y la URL cruda en `resource_url`.
    final recursoJson = _map(json['recurso']) ?? _map(json['recurso_resuelto']);
    return OvaInfo(
      id: _int(json['id']),
      titulo: _text(json['titulo']) ?? 'Actividad',
      descripcion: _text(json['descripcion']),
      tipo: OvaTipo.parse(json['tipo_actividad']),
      duracionMinutos: _int(json['duracion_minutos']),
      recurso: OvaRecurso.fromJson(
        recursoJson,
        fallbackSource: json['storage_source'],
        fallbackUrl: json['resource_url'],
      ),
    );
  }
}

class OvaAsignacion {
  const OvaAsignacion({
    required this.id,
    required this.ovaId,
    required this.estado,
    required this.requierePostTest,
    required this.ova,
    this.preEvaluacionId,
    this.postEvaluacionId,
    this.dimension,
    this.nivel,
    this.startedAt,
    this.completedAt,
    this.liked,
    this.rating,
    this.deltaPuntaje,
    this.createdAt,
  });

  final int id;
  final int ovaId;
  final OvaEstado estado;
  final bool requierePostTest;
  final OvaInfo ova;
  final int? preEvaluacionId;
  final int? postEvaluacionId;
  final String? dimension;
  final String? nivel;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool? liked;
  final int? rating;

  /// post - pre. Un valor negativo significa mejoría.
  final double? deltaPuntaje;
  final DateTime? createdAt;

  /// Actividades que el estudiante todavía puede hacer.
  bool get porHacer =>
      estado == OvaEstado.pending || estado == OvaEstado.inProgress;

  /// Completada, pero aún sin la medición posterior.
  bool get necesitaPostTest =>
      estado == OvaEstado.completed && postEvaluacionId == null;

  bool get mejoro => deltaPuntaje != null && deltaPuntaje! < 0;

  factory OvaAsignacion.fromJson(Map<String, dynamic> json) {
    final matched = _map(json['matched']);
    final feedback = _map(json['feedback']);
    final efectividad = _map(json['efectividad']);
    final ovaJson = _map(json['ova']) ?? const <String, dynamic>{};

    final estado = OvaEstado.parse(json['estado']);
    final postId = _intOrNull(json['post_evaluacion_id']);
    return OvaAsignacion(
      id: _int(json['id']),
      ovaId: _int(json['ova_id'] ?? ovaJson['id']),
      estado: estado,
      requierePostTest:
          json['requiere_post_test'] == true ||
          (estado == OvaEstado.completed && postId == null),
      ova: OvaInfo.fromJson(ovaJson),
      preEvaluacionId: _intOrNull(json['pre_evaluacion_id']),
      postEvaluacionId: postId,
      dimension: _text(matched?['dimension'] ?? json['matched_dimension']),
      nivel: _text(matched?['nivel'] ?? json['matched_nivel']),
      startedAt: _date(feedback?['started_at'] ?? json['started_at']),
      completedAt: _date(feedback?['completed_at'] ?? json['completed_at']),
      liked: _bool(feedback?['liked'] ?? json['liked']),
      rating: _intOrNull(feedback?['rating'] ?? json['rating']),
      // El backend envía los numéricos de Postgres como string ("-12.50").
      deltaPuntaje: _double(efectividad?['delta_puntaje'] ?? json['delta_puntaje']),
      createdAt: _date(json['created_at']),
    );
  }
}

/// Resultado de marcar una actividad como completada.
class OvaCompletada {
  const OvaCompletada({required this.requierePostTest, this.preEvaluacionId});

  final bool requierePostTest;
  final int? preEvaluacionId;
}

// ---------------------------------------------------------------------------
// Helpers de parseo tolerante
// ---------------------------------------------------------------------------

String? _text(Object? value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty || text == 'null') ? null : text;
}

int _int(Object? value) => _intOrNull(value) ?? 0;

int? _intOrNull(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return num.tryParse(value.toString())?.toInt();
}

double? _double(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

bool? _bool(Object? value) => value is bool ? value : null;

DateTime? _date(Object? value) {
  final text = _text(value);
  return text == null ? null : DateTime.tryParse(text);
}

Map<String, dynamic>? _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : null;

bool _isHttp(String url) {
  final lower = url.toLowerCase();
  return lower.startsWith('http://') || lower.startsWith('https://');
}
