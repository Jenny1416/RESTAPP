// emotionregister_screen.dart (Preguntas de evaluación emocional)
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:rest/core/routes/app_routes.dart';
import 'package:rest/core/services/emotion_service.dart';
import 'package:rest/core/services/personal_progress_service.dart';
import 'package:rest/core/services/user_session.dart';
import 'package:rest/features/evaluations/services/evaluation_service.dart';

class EmotionRegisterScreen extends StatefulWidget {
  const EmotionRegisterScreen({super.key});

  @override
  State<EmotionRegisterScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<EmotionRegisterScreen> {
  static const int _dailyQuestionLimit = 5;
  final EvaluationService _evaluationService = EvaluationService();
  final EmotionService _emotionService = EmotionService();
  final PersonalProgressService _personalProgressService =
      PersonalProgressService();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _preguntas = [];
  final Map<int, int> _opcionSeleccionadaPorPregunta =
      {}; // preguntaId -> opcionId
  int _currentQuestion = 0;

  final List<String> _facesAssets = const [
    'assets/images/sadrest.jpg',
    'assets/images/yellowrest.jpg',
    'assets/images/normalrest.jpg',
    'assets/images/goodrest.jpg',
    'assets/images/statesuperexcellent.png', // Cambio: nueva imagen para excelente
  ];

  // Etiquetas para las emociones
  final List<String> _emotionLabels = const [
    'Muy mal',
    'Mal',
    'Normal',
    'Bien',
    'Excelente',
  ];

  @override
  void initState() {
    super.initState();
    _cargarPreguntas();
  }

  Future<void> _cargarPreguntas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Se consultan ambos bancos. La misma respuesta se guarda como
      // evaluación (semaforo) y como registro emocional (calendario/racha).
      final results = await Future.wait<dynamic>([
        _evaluationService.getPreguntas(),
        _emotionService.fetchPreguntas(),
      ]);
      final evaluationQuestions = List<Map<String, dynamic>>.from(
        (results[0] as List).map(
          (p) => p is Map ? Map<String, dynamic>.from(p) : <String, dynamic>{},
        ),
      );
      final emotionalQuestions = List<Map<String, dynamic>>.from(
        (results[1] as List).map(
          (p) => p is Map ? Map<String, dynamic>.from(p) : <String, dynamic>{},
        ),
      );
      final evaluationByText = <String, Map<String, dynamic>>{
        for (final question in evaluationQuestions)
          _normalizeQuestion(question['texto'] ?? question['pregunta']): question,
      };
      // El registro emocional selecciona las preguntas adaptativas del día.
      // Se conserva esa selección y se encuentra su equivalente para el
      // endpoint de evaluaciones.
      final questions = emotionalQuestions
          .map((emotional) {
            final evaluation = evaluationByText[
                _normalizeQuestion(emotional['texto'] ?? emotional['pregunta'])];
            if (evaluation == null || evaluation['id'] is! int || emotional['id'] is! int || emotional['opciones'] is! List) {
              return <String, dynamic>{};
            }
            return <String, dynamic>{
              ...evaluation,
              'categoria': emotional['categoria'],
              'registroPreguntaId': emotional['id'],
              'registroOpciones': emotional['opciones'],
            };
          })
          .where((question) => question.isNotEmpty)
          .toList();
      if (questions.isEmpty) {
        throw Exception('No hay preguntas compatibles para el registro diario.');
      }
      setState(() {
        _preguntas = _dailyQuestions(questions);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _guardarRespuestas() async {
    if (_preguntas.isEmpty) return;

    final respuestas = <Map<String, int>>[];
    final registroRespuestas = <Map<String, int>>[];
    for (final q in _preguntas) {
      final int? preguntaId = q['id'] is int ? q['id'] as int : null;
      if (preguntaId == null) continue;
      final int? score = _opcionSeleccionadaPorPregunta[preguntaId];
      if (score == null) continue;
      respuestas.add({'pregunta_id': preguntaId, 'respuesta': score});

      final registroPreguntaId = q['registroPreguntaId'];
      final registroOpciones = q['registroOpciones'] as List? ?? const [];
      Map? selectedOption;
      for (final option in registroOpciones.whereType<Map>()) {
        if (option['puntaje'] == score) {
          selectedOption = option;
          break;
        }
      }
      final optionId = selectedOption?['id'];
      if (registroPreguntaId is int && optionId is int) {
        registroRespuestas.add({
          'pregunta_id': registroPreguntaId,
          'opcion_id': optionId,
        });
      }
    }

    if (respuestas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una respuesta.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (respuestas.length != _preguntas.length) {
        throw Exception('Responde todas las preguntas para continuar.');
      }
      if (registroRespuestas.length != _preguntas.length) {
        throw Exception('No se pudieron preparar las respuestas del registro diario.');
      }
      final evaluation = await _evaluationService.submitEvaluation(respuestas);
      await _emotionService.enviarRegistroEmocional(
        respuestas: registroRespuestas,
      );
      final assignment = await _evaluationService.assignTrafficLight();
      final streak = await _personalProgressService.activarRachaDiaria();

      // Actualizar fecha del último test completado
      UserSession.lastTestDate = DateTime.now();
      await UserSession.persist();

      if (!mounted) return;
      final assignmentData = assignment['data'] is Map
          ? Map<String, dynamic>.from(assignment['data'] as Map)
          : assignment;
      final evaluationData = evaluation['evaluacion'] is Map
          ? Map<String, dynamic>.from(evaluation['evaluacion'] as Map)
          : evaluation;
      final estadoRaw = (assignmentData['estado_semaforo'] ??
              assignmentData['estado'] ??
              evaluationData['estado_semaforo'] ??
              evaluation['estado'] ??
              evaluation['semaforo'] ??
              'normal')
          .toString()
          .toLowerCase()
          .trim();
      final estadoUi = _mapEstadoToUiKey(estadoRaw);
      final esCritico = estadoUi == 'critico';
      final resultado = {
        'estado': estadoUi,
        'mensaje': (assignmentData['mensaje'] ??
                assignmentData['observaciones'] ??
                evaluation['mensaje'] ??
                'Tu resultado ha sido actualizado.')
            .toString(),
        'botonTexto': esCritico ? 'Buscar psicólogo' : 'Continuar',
        'rachaActivada': streak.activada,
      };
      // Navegar directo al semáforo emocional
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.trafficLight,
        arguments: resultado,
      );
    } catch (e) {
      if (!mounted) return;

      if (e.toString().contains('CONFLICT_ERROR')) {
        // El test de hoy ya fue completado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ya has completado el test emocional de hoy.'),
          ),
        );
        UserSession.lastTestDate = DateTime.now();
        await UserSession.persist();

        // Redirigir a MainApp
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.mainApp);
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _nextQuestion() async {
    if (_preguntas.isEmpty) return;
    final id = _preguntas[_currentQuestion]['id'] as int?;
    if (id == null || !_opcionSeleccionadaPorPregunta.containsKey(id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una respuesta para continuar.')),
      );
      return;
    }
    if (_currentQuestion < _preguntas.length - 1) {
      setState(() => _currentQuestion++);
    } else {
      await _guardarRespuestas();
    }
  }

  List<Map<String, dynamic>> _dailyQuestions(List<Map<String, dynamic>> all) {
    if (all.length <= _dailyQuestionLimit) return all;

    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    final shuffled = List<Map<String, dynamic>>.from(all)..shuffle(Random(seed));
    return shuffled.take(_dailyQuestionLimit).toList();
  }

  /// Traduce el estado devuelto por el backend (colores de semáforo:
  /// `verde`/`amarillo`/`rojo`) a las claves que reconoce
  /// [EmotionStateConfig]. Si ya viene en el formato de UI (por ejemplo en
  /// pruebas manuales o respuestas legadas), se retorna sin cambios.
  String _mapEstadoToUiKey(String estadoRaw) {
    switch (estadoRaw) {
      case 'verde':
        return 'normal';
      case 'amarillo':
        return 'alerta-amarillo';
      case 'rojo':
        return 'critico';
      default:
        return estadoRaw;
    }
  }

  String _normalizeQuestion(Object? value) {
    return value
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-záéíóúüñ0-9]+'), ' ')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Header con logo y título
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 8.h),
              child: Row(
                children: [
                  // Logo igual al del chat
                  Container(
                    width: 68.w,
                    height: 68.h,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Color(0xFF7DFDFE),
                          Color(0xFF4ECDC4),
                          Color(0xFF00B4D8),
                        ],
                        stops: [0.0, 0.6, 1.0],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF4ECDC4), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF4ECDC4).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/normalrest.jpg',
                        width: 68.w,
                        height: 68.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 15.w),
                  // Título
                  Expanded(
                    child: Text(
                      '¡Cuéntame\nsobre tu día!',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 30.sp,
                        height: 0.9,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: [
                              Color(0xFF7DFDFE), // Celeste
                              Color(0xFF2196F3), // Azul
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(Rect.fromLTWH(0, 0, 250, 60)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenido principal
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildErrorContent()
                  : _buildPreguntasContent(context),
            ),

            // Botón guardar
            Container(
              margin: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2196F3), // Azul izquierdo
                        Color(0xFF3973D1), // Azul derecho (más oscuro)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    child: Text(
                      _currentQuestion < _preguntas.length - 1 ? 'CONTINUAR' : 'VER MI RESULTADO',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: 21.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'No pudimos cargar las preguntas.',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.sp, color: Colors.red),
              ),
            ),
          SizedBox(height: 12.h),
          ElevatedButton(
            onPressed: _cargarPreguntas,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreguntasContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Text(
                'Pregunta ${_currentQuestion + 1} de ${_preguntas.length}',
                style: TextStyle(
                  color: const Color(0xFF1769AA),
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: _preguntas.isEmpty ? 0 : (_currentQuestion + 1) / _preguntas.length,
                    minHeight: 7.h,
                    backgroundColor: const Color(0xFFCFE3F7),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF38A6D9)),
                  ),
                ),
              ),
            ]),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 4.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chequeo emocional diario',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontFamily: 'Fredoka',
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Te tomará menos de un minuto.',
                style: TextStyle(fontSize: 14.sp, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _preguntas.where((q) => _preguntas.indexOf(q) == _currentQuestion).map((q) {
                final int? id = (q['id'] as int?);
                if (id == null) return const SizedBox.shrink();
                final String textoPregunta = (q['texto'] ?? q['pregunta'] ?? '')
                    .toString();
                final String categoria = (q['categoria'] ?? '').toString();
                final List<dynamic> opciones = (q['opciones'] is List)
                    ? q['opciones'] as List
                    : List.generate(5, (index) => {'id': index, 'nombre': _emotionLabels[index]});

                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (categoria.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF5CCFC0,
                            ).withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _dimensionLabel(categoria),
                            style: const TextStyle(
                              color: Color(0xFF167E76),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(18.w),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F8FF),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFB9E0F7)),
                        ),
                        child: Text(
                          textoPregunta,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                            fontFamily: 'Freeman',
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final int count = opciones.length.clamp(
                            0,
                            _facesAssets.length,
                          );
                          final double maxFaceSize = 48;
                          final double spacing = 8;
                          final double borderWidth = 3 * 2;
                          final double paddingSize = 4 * 2;
                          final double available = constraints.maxWidth;
                          final double idealTotal =
                              count *
                                  (maxFaceSize + borderWidth + paddingSize) +
                              (count - 1) * spacing;
                          final double faceSize = idealTotal > available
                              ? ((available - (count - 1) * spacing) / count -
                                        borderWidth -
                                        paddingSize)
                                    .clamp(24, maxFaceSize)
                              : maxFaceSize;

                          return Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(count, (index) {
                                  final dynamic opcion = opciones[index];
                                  final int opcionId = index;
                                  final bool seleccionado =
                                      _opcionSeleccionadaPorPregunta[id] ==
                                      opcionId;

                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _opcionSeleccionadaPorPregunta[id] =
                                            opcionId;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: seleccionado
                                              ? const Color(0xFFFFC107)
                                              : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          _facesAssets[index.clamp(
                                            0,
                                            _facesAssets.length - 1,
                                          )],
                                          width: faceSize,
                                          height: faceSize,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              SizedBox(height: 8.h),
                              // Agregar etiquetas de emociones
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(count, (index) {
                                  final dynamic opcion = opciones[index];
                                  final String nombreOpcion =
                                      (opcion is Map &&
                                          opcion['nombre'] is String)
                                      ? opcion['nombre'] as String
                                      : _emotionLabels[index.clamp(
                                          0,
                                          _emotionLabels.length - 1,
                                        )];
                                  return SizedBox(
                                    width: faceSize + 8,
                                    child: Text(
                                      nombreOpcion,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurfaceVariant,
                                        fontFamily: 'Freeman',
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _dimensionLabel(String value) {
    const labels = {
      'ansiedad': 'Ansiedad',
      'estres_academico': 'Estrés académico',
      'humor_depresivo': 'Estado de ánimo',
      'sueno': 'Sueño',
      'relaciones_sociales': 'Relaciones sociales',
      'autoestima_autocuidado': 'Autoestima y autocuidado',
      'energia_motivacion': 'Energía y motivación',
    };
    return labels[value] ?? value.replaceAll('_', ' ');
  }
}
