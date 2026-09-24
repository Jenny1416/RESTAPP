import 'package:flutter/material.dart';

/// Configuración centralizada para cada estado emocional
class EmotionStateConfig {
  final String estado;
  final String titulo;
  final String mensaje;
  final String mensaje2;
  final String imagenAsset;
  final Color colorPrincipal;
  final Color colorSecundario;
  final Color colorTexto;
  final String botonTexto;
  final List<String> recomendaciones;

  EmotionStateConfig({
    required this.estado,
    required this.titulo,
    required this.mensaje,
    required this.mensaje2,
    required this.imagenAsset,
    required this.colorPrincipal,
    required this.colorSecundario,
    required this.colorTexto,
    required this.botonTexto,
    required this.recomendaciones,
  });

  static EmotionStateConfig getConfig(String estado) {
    // Alias defensivos: si en algún punto llega el color crudo del semáforo
    // del backend ('verde'/'amarillo'/'rojo') en vez de la clave de UI,
    // se traduce aquí también para no caer en "ESTADO DESCONOCIDO".
    switch (estado.toLowerCase().trim()) {
      case 'verde':
        estado = 'normal';
        break;
      case 'amarillo':
        estado = 'alerta-amarillo';
        break;
      case 'rojo':
        estado = 'critico';
        break;
      default:
        estado = estado.toLowerCase().trim();
    }

    switch (estado) {
      case 'excelente':
        return EmotionStateConfig(
          estado: 'excelente',
          titulo: '¡Excelente!',
          mensaje: '¡Qué bien te sientes hoy! Sigue así.',
          mensaje2: 'Tu energía es inspiradora.',
          imagenAsset: 'assets/images/goodrest.jpg',
          colorPrincipal: const Color(0xFF08D557),
          colorSecundario: const Color(0xFF41AC20),
          colorTexto: const Color(0xFF08D557),
          botonTexto: 'Continuar',
          recomendaciones: [
            '✨ Celebra este momento de bienestar',
            '🎯 Comparte tu energía con otros',
            '💪 Mantén tus hábitos saludables',
          ],
        );

      case 'normal':
        return EmotionStateConfig(
          estado: 'normal',
          titulo: 'Normal',
          mensaje: 'Tu día va tranquilo y estable.',
          mensaje2: 'Es un buen momento para reflexionar.',
          imagenAsset: 'assets/images/normalrest.jpg',
          colorPrincipal: const Color(0xFF2196F3),
          colorSecundario: const Color(0xFF64B5F6),
          colorTexto: const Color(0xFF1565C0),
          botonTexto: 'Continuar',
          recomendaciones: [
            '🎯 Fija metas pequeñas para hoy',
            '🌿 Práctica meditación',
            '👥 Conecta con alguien cercano',
          ],
        );

      case 'alerta-amarillo':
        return EmotionStateConfig(
          estado: 'alerta-amarillo',
          titulo: '¡Alerta!',
          mensaje:
              'Parece que hoy no estás al 100%. Te invitamos a respirar y relajarte.',
          mensaje2: '¡Tenemos esto para ti!',
          imagenAsset: 'assets/images/yellowrest.jpg',
          colorPrincipal: const Color(0xFFFF9800),
          colorSecundario: const Color(0xFFFFB74D),
          colorTexto: const Color(0xFFE65100),
          botonTexto: 'Ver consejos',
          recomendaciones: [
            '🫁 Practica la técnica 4-7-8 de respiración',
            '🧘 Realiza una meditación corta de 5 minutos',
            '🚶 Da un paseo para despejar la mente',
            '🎵 Escucha música relajante',
            '✍️ Escribe lo que te preocupa',
          ],
        );

      case 'critico':
        return EmotionStateConfig(
          estado: 'critico',
          titulo: '¡Alerta!',
          mensaje:
              'Notamos que hoy te sientes mal. Estamos aquí para ayudarte.',
          mensaje2: '¡Tenemos esto para ti!',
          imagenAsset: 'assets/images/sadrest.jpg',
          colorPrincipal: const Color(0xFFE91E63),
          colorSecundario: const Color(0xFFF06292),
          colorTexto: const Color(0xFFC2185B),
          botonTexto: 'Pedir ayuda',
          recomendaciones: [
            '📞 Contacta a un psicólogo',
            '👤 Habla con alguien de tu confianza',
            '🏥 Si es urgente, busca atención médica',
            '💬 Chat de emergencia',
            '🆘 PAS Colombia: 123',
          ],
        );

      default:
        return EmotionStateConfig(
          estado: 'desconocido',
          titulo: '❓ ESTADO DESCONOCIDO',
          mensaje: 'No pudimos identificar tu estado emocional.',
          mensaje2: 'Por favor, intenta de nuevo.',
          imagenAsset: 'assets/images/normalrest.jpg',
          colorPrincipal: const Color(0xFF9E9E9E),
          colorSecundario: const Color(0xFFBDBDBD),
          colorTexto: const Color(0xFF616161),
          botonTexto: 'Reintentar',
          recomendaciones: ['Recarga la página', 'Verifica tu conexión'],
        );
    }
  }

  /// Obtiene recomendaciones aleatorias
  List<String> getRandomRecommendations({int count = 3}) {
    final random = recomendaciones.toList()..shuffle();
    return random.take(count).toList();
  }
}
