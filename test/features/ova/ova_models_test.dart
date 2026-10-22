import 'package:flutter_test/flutter_test.dart';
import 'package:rest/features/ova/models/ova_models.dart';

Map<String, dynamic> _asignacion({
  String estado = 'PENDING',
  Map<String, dynamic>? recurso,
  Map<String, dynamic>? efectividad,
  int? postEvaluacionId,
  bool requierePostTest = false,
}) {
  return {
    'id': 12,
    'ova_id': 3,
    'pre_evaluacion_id': 40,
    'post_evaluacion_id': postEvaluacionId,
    'estado': estado,
    'requiere_post_test': requierePostTest,
    'matched': {'dimension': 'ansiedad', 'nivel': 'rojo', 'prioridad': 10},
    'feedback': {
      'started_at': null,
      'completed_at': '2026-10-20T10:00:00.000Z',
      'liked': true,
      'rating': 4,
    },
    'efectividad':
        efectividad ??
        {'pre_puntaje': null, 'post_puntaje': null, 'delta_puntaje': null},
    'ova': {
      'id': 3,
      'titulo': 'Respiración 4-7-8',
      'descripcion': 'Calma tu cuerpo',
      'tipo_actividad': 'respiracion',
      'duracion_minutos': 5,
      'storage_source': 'YOUTUBE',
      'recurso':
          recurso ??
          {
            'storage_source': 'YOUTUBE',
            'original_url': 'https://youtu.be/dQw4w9WgXcQ',
            'video_id': 'dQw4w9WgXcQ',
            'watch_url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            'embed_url': 'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ',
            'resolved_url': 'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ',
          },
    },
    'created_at': '2026-10-19T08:00:00.000Z',
  };
}

void main() {
  group('OvaAsignacion.fromJson', () {
    test('lee la forma de GET /api/ovas/asignaciones', () {
      final item = OvaAsignacion.fromJson(_asignacion());

      expect(item.id, 12);
      expect(item.ovaId, 3);
      expect(item.estado, OvaEstado.pending);
      expect(item.porHacer, isTrue);
      expect(item.dimension, 'ansiedad');
      expect(item.nivel, 'rojo');
      expect(item.liked, isTrue);
      expect(item.rating, 4);
      expect(item.ova.titulo, 'Respiración 4-7-8');
      expect(item.ova.tipo, OvaTipo.respiracion);
      expect(item.ova.duracionMinutos, 5);
      expect(item.ova.recurso.media, OvaMedia.youtube);
      expect(item.ova.recurso.videoId, 'dQw4w9WgXcQ');
      expect(item.completedAt, isNotNull);
    });

    test('convierte los puntajes que llegan como string', () {
      final item = OvaAsignacion.fromJson(
        _asignacion(
          estado: 'COMPLETED',
          requierePostTest: true,
          efectividad: {
            'pre_puntaje': '45.00',
            'post_puntaje': '32.50',
            'delta_puntaje': '-12.50',
          },
        ),
      );

      expect(item.deltaPuntaje, -12.5);
      expect(item.mejoro, isTrue);
    });

    test('delta nulo no cuenta como mejoría', () {
      final item = OvaAsignacion.fromJson(_asignacion());
      expect(item.deltaPuntaje, isNull);
      expect(item.mejoro, isFalse);
    });

    test('COMPLETED sin post-test necesita la medición posterior', () {
      final sinPost = OvaAsignacion.fromJson(
        _asignacion(estado: 'COMPLETED', requierePostTest: true),
      );
      final conPost = OvaAsignacion.fromJson(
        _asignacion(estado: 'COMPLETED', postEvaluacionId: 77),
      );

      expect(sinPost.necesitaPostTest, isTrue);
      expect(sinPost.porHacer, isFalse);
      expect(conPost.necesitaPostTest, isFalse);
    });

    test('tolera la forma de ovas_asignados (recurso_resuelto y matched_*)', () {
      final item = OvaAsignacion.fromJson({
        'id': 5,
        'ova_id': 9,
        'estado': 'PENDING',
        'matched_dimension': 'sueno',
        'matched_nivel': 'amarillo',
        'post_evaluacion_id': null,
        'ova': {
          'id': 9,
          'titulo': 'Higiene del sueño',
          'tipo_actividad': 'video',
          'duracion_minutos': 8,
          'storage_source': 'CLOUDFLARE_R2',
          'resource_url': 'ovas/abc.mp4',
          'recurso_resuelto': {
            'storage_source': 'CLOUDFLARE_R2',
            'original_url': 'ovas/abc.mp4',
            'resolved_url': 'https://cdn.test/ovas/abc.mp4',
          },
        },
      });

      expect(item.dimension, 'sueno');
      expect(item.nivel, 'amarillo');
      expect(item.ova.recurso.resolvedUrl, 'https://cdn.test/ovas/abc.mp4');
      expect(item.ova.recurso.media, OvaMedia.video);
    });

    test('un estado desconocido no rompe el parseo', () {
      final item = OvaAsignacion.fromJson(_asignacion(estado: 'ARCHIVED'));
      expect(item.estado, OvaEstado.unknown);
      expect(item.porHacer, isFalse);
    });
  });

  group('OvaRecurso', () {
    OvaRecurso build(Map<String, dynamic> recurso) =>
        OvaAsignacion.fromJson(_asignacion(recurso: recurso)).ova.recurso;

    test('YouTube sin video_id cae al enlace original', () {
      final recurso = build({
        'storage_source': 'YOUTUBE',
        'original_url': 'https://example.com/video',
        'video_id': '',
        'resolved_url': 'https://example.com/video',
      });

      expect(recurso.media, OvaMedia.enlace);
      expect(recurso.urlParaAbrir, 'https://example.com/video');
      expect(recurso.esUtilizable, isTrue);
    });

    test('R2 con key relativa no es utilizable', () {
      final recurso = build({
        'storage_source': 'CLOUDFLARE_R2',
        'original_url': 'ovas/abc.mp4',
        'resolved_url': 'ovas/abc.mp4',
      });

      expect(recurso.esUtilizable, isFalse);
    });

    test('detecta el tipo de archivo ignorando el query string', () {
      OvaMedia mediaDe(String url) => build({
        'storage_source': 'CLOUDFLARE_R2',
        'original_url': url,
        'resolved_url': url,
      }).media;

      expect(mediaDe('https://cdn.test/ovas/a.MP4?x=1'), OvaMedia.video);
      expect(mediaDe('https://cdn.test/ovas/a.mp3'), OvaMedia.audio);
      expect(mediaDe('https://cdn.test/ovas/a.webp'), OvaMedia.imagen);
      expect(mediaDe('https://cdn.test/ovas/a.pdf'), OvaMedia.pdf);
      expect(mediaDe('https://cdn.test/ovas/a'), OvaMedia.enlace);
    });

    test('EXTERNAL_URL usa la URL resuelta', () {
      final recurso = build({
        'storage_source': 'EXTERNAL_URL',
        'original_url': 'https://blog.test/articulo',
        'resolved_url': 'https://blog.test/articulo',
      });

      expect(recurso.fuente, OvaFuente.externalUrl);
      expect(recurso.media, OvaMedia.enlace);
      expect(recurso.urlParaAbrir, 'https://blog.test/articulo');
    });
  });
}
